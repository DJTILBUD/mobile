import 'package:dj_tilbud_app/features/jobs/domain/musician_job_availability.dart';

/// Feed rows that are an INVITATION TO BID. Once the job behind one is filled or
/// past bidding, the invitation is dead — there is nothing left for the user to
/// do with it, so it should stop counting toward the unread badge on its own.
///
/// Reported by a DJ: *"Kan man ikke gøre, så appen fjerner notifikationer på
/// jobs, når de er taget? Det er irriterende at skulle markere fx 8 stk som
/// læst, når jobbene er besat."* Every other notification type is about a job
/// the user is already on, so only these three self-expire.
const Set<String> kBidInvitationNotificationTypes = {
  'new_job',
  'another_round',
  'new_ext_job',
};

/// Statuses an internal Job still accepts DJ quotes in. Mirrors `biddableStatuses`
/// in web `POST /api/jobs/[job_id]/quotes` and `domain/biddableJobs.ts`.
const Set<String> kJobStatusesOpenToQuotes = {
  'open',
  'another_round',
  'sent',
  're_sent',
  'reopened',
};

/// What we know about the job a bid invitation points at.
///
/// A `null` [JobBidState] at the call site means the row could not be read at
/// all — which for an authenticated performer means it was **archived**
/// (CRM-deleted; RLS hides it, see `mobile/CLAUDE.md` → "Archived jobs are
/// invisible") or deleted outright. Either way the invitation is dead.
class JobBidState {
  const JobBidState({
    required this.status,
    this.assignedMusicianId,
    this.hasWonOffer = false,
  });

  final String? status;

  /// ExtJobs only — an admin-assigned musician wins with no offer row at all.
  final String? assignedMusicianId;

  /// ExtJobs only — a self-serve win leaves `assigned_musician_id` NULL, so the
  /// won `ServiceOffers` row is the other half of the same question.
  final bool hasWonOffer;
}

/// Whether a bid-invitation notification has expired and can be auto-marked read.
///
/// [state] is null when the job row was not readable (archived/deleted).
///
/// ⚠️ This FAILS CLOSED in the safe direction: an unknown type or a type outside
/// [kBidInvitationNotificationTypes] is never stale, so no notification the user
/// might still act on is silently cleared. Only a positively-known dead job is.
bool isBidInvitationStale({
  required String type,
  required String? role,
  required JobBidState? state,
}) {
  if (!kBidInvitationNotificationTypes.contains(type)) return false;

  // Archived / deleted / unreadable — nothing to act on.
  if (state == null) return true;

  final status = state.status;
  if (status == null) return true;

  if (type == 'new_ext_job') {
    // A saxophonist's ext-job invitation. Someone else winning it is the whole
    // point of the complaint, and a win shows up two different ways.
    if (state.hasWonOffer) return true;
    final assigned = state.assignedMusicianId;
    if (assigned != null && assigned.isNotEmpty) return true;
    return !kExtJobStatusesOpenToOffers.contains(status);
  }

  // `new_job` / `another_round` on an internal Job. DJs and saxophonists have
  // different biddable-status sets on the SAME table, so branch on the role the
  // sender stamped into the payload. `kJobStatusesOpenToOffers` (musicians) is a
  // strict superset of `kJobStatusesOpenToQuotes` (DJs) — a `closed` job still
  // takes sax offers, because a booked DJ does not fill the sax slot. An unknown
  // role therefore uses the SUPERSET, so a missing `role` under-clears rather
  // than clearing an invitation that is still live.
  final open =
      role == 'dj' ? kJobStatusesOpenToQuotes : kJobStatusesOpenToOffers;
  return !open.contains(status);
}
