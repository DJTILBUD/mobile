/// Why a musician can (or cannot) still bid on a job.
///
/// The browse feed already excludes everything except [biddable], so this only ever matters on the
/// OFFER FORM, which is reachable by **push deep-link** — `NotificationsService.navigateTo` fetches
/// the row by id and opens the form, completely bypassing the feed's filters. A `new_ext_job` push
/// stays valid long after the job stopped accepting offers (another sax won it, admin assigned one,
/// or it moved to ready_for_billing), so tapping an old notification used to open a normal, fully
/// enabled form. The musician wrote a price and a sales pitch, and the FIRST signal that it was
/// hopeless was the server rejecting the insert.
enum MusicianJobAvailability {
  /// Still open for offers.
  biddable,

  /// Someone else already won it (a won `ServiceOffers` row, or `assigned_musician_id` is set —
  /// a self-serve win leaves that column NULL, so BOTH have to be checked; this is the same
  /// "won offer OR assigned_musician_id" resolution order the invoicing and iCal paths use).
  wonByAnother,

  /// This musician already has an offer on it (it lives in their sent/won/lost lanes instead).
  alreadyBid,

  /// Another musician holds an ACTIVE (non-lost) offer on it. The DB allows only one non-lost
  /// offer per instrument per job (unique indexes `idx_unique_active_instrument_per_job` /
  /// `_per_ext_job`), so a second offer is rejected at insert. Frees up again if that offer goes
  /// `lost`. Same rule as the feed's `has_active_offer` ("Jobbet er desværre optaget").
  heldByAnother,

  /// The job's status is past the point where offers are accepted.
  closedForOffers,

  /// This ext job belongs to a TRUE partner-portal account (`is_partner = true`) — the venue
  /// coordinator books the performer via admin/the partner flow, so saxophonists can never
  /// self-serve bid on it. Only reachable via a push deep-link (the feed already excludes it).
  partnerBooking,
}

/// Statuses an ExtJob accepts musician offers in. Mirrors the feed query in
/// `JobsRemoteDatasource.fetchInstrumentalistExtJobs` and web `useExtJobsForMusicians`.
///
/// `closed`/`customer_contacted` ARE included on purpose: a DJ being booked does not mean the sax
/// slot is filled. `ready_for_billing`, `canceled`, `expired` and `reopened`-without-a-slot are not.
const Set<String> kExtJobStatusesOpenToOffers = {
  'open',
  'sent',
  'closed',
  'customer_contacted',
};

/// Statuses an internal Job accepts musician offers in. Mirrors
/// `JobsRemoteDatasource.fetchNewInstrumentalistJobs` + web `useAvailableJobsForMusicians`.
///
/// `ready_for_billing` is deliberately absent: it is only biddable in the separate sax-campaign
/// path, which additionally requires `sax_round_active` and is handled by the feed query, not here.
const Set<String> kJobStatusesOpenToOffers = {
  'open',
  'sent',
  're_sent',
  'reopened',
  'another_round',
  'closed',
  'customer_contacted',
};

/// The canonical "may this musician still bid?" rule.
///
/// Pure so it can be unit-tested and reused by the form, the card and any future surface. Pass the
/// raw DB values; [offers] is every `ServiceOffers` row on the job as `{musician_id, status}`.
///
/// ⚠️ Order matters. [wonByAnother] is reported before [alreadyBid] so a musician whose own losing
/// offer sits on a job someone else won is told the job is gone, not that they already bid.
MusicianJobAvailability resolveMusicianJobAvailability({
  required String? status,
  required bool isExtJob,
  required String? assignedMusicianId,
  required String currentMusicianId,
  required List<({String? musicianId, String? status})> offers,
  bool isPartnerBooking = false,
}) {
  if (isExtJob && isPartnerBooking) {
    return MusicianJobAvailability.partnerBooking;
  }

  final wonByOther = offers.any(
    (o) => o.status == 'won' && o.musicianId != currentMusicianId,
  );
  if (wonByOther) return MusicianJobAvailability.wonByAnother;

  // An admin-assigned musician wins without any offer row existing at all.
  if (assignedMusicianId != null &&
      assignedMusicianId.isNotEmpty &&
      assignedMusicianId != currentMusicianId) {
    return MusicianJobAvailability.wonByAnother;
  }

  if (offers.any((o) => o.musicianId == currentMusicianId)) {
    return MusicianJobAvailability.alreadyBid;
  }

  final open =
      isExtJob ? kExtJobStatusesOpenToOffers : kJobStatusesOpenToOffers;
  // An unknown/null status is treated as CLOSED rather than open: this gate only ever guards the
  // deep-link path, where the alternative is letting the musician write an offer the server will
  // reject anyway. That is the opposite polarity to the feed's fail-open filters, and deliberate.
  if (status == null || !open.contains(status)) {
    return MusicianJobAvailability.closedForOffers;
  }

  // After the status check: a closed job must not claim it "may free up again".
  if (offers.any(
    (o) => o.status != 'lost' && o.musicianId != currentMusicianId,
  )) {
    return MusicianJobAvailability.heldByAnother;
  }

  return MusicianJobAvailability.biddable;
}

/// Danish explanation shown on the offer form, or null when the job is still biddable.
///
/// Describes the JOB's state, never the musician's standing.
String? musicianJobAvailabilityMessage(MusicianJobAvailability availability) {
  switch (availability) {
    case MusicianJobAvailability.biddable:
      return null;
    case MusicianJobAvailability.wonByAnother:
      return 'Jobbet er desværre besat af en anden musiker, så du kan ikke sende et tilbud på det længere.';
    case MusicianJobAvailability.alreadyBid:
      return 'Du har allerede sendt et tilbud på dette job. Du finder det under dine tilbud.';
    case MusicianJobAvailability.heldByAnother:
      return 'En anden saxofonist har allerede afgivet et aktivt tilbud på dette job. Skulle tilbuddet blive trukket tilbage, vil jobbet automatisk blive tilgængeligt igen.';
    case MusicianJobAvailability.closedForOffers:
      return 'Jobbet tager ikke imod flere tilbud. Se de ledige jobs på din jobside.';
    case MusicianJobAvailability.partnerBooking:
      return 'Dette job kan ikke bydes på direkte — kontakt os, hvis du er interesseret.';
  }
}
