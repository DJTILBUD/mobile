import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/features/notifications/domain/entities/app_notification.dart';
import 'package:dj_tilbud_app/features/notifications/domain/stale_bid_notifications.dart';

/// Reads/writes the in-app notification feed (UserNotifications). Logic-free direct
/// Supabase access (a per-user read + a read-flag update), which the architecture
/// rules allow — inserts are server-side only (the notify-* Edge Functions).
class NotificationsDatasource {
  NotificationsDatasource(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetch(String userId, {int limit = 100}) async {
    final rows = await _client
        .from('UserNotifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => AppNotification.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) async {
    await _client
        .from('UserNotifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .isFilter('read_at', null);
  }

  /// Marks the feed row(s) a tapped push points at as read.
  ///
  /// Tapping a push IS reading it, so the bell badge and the app-icon badge must drop on
  /// their own — before this, they survived the tap and only cleared via "Marker alle
  /// læst" in the notification centre.
  ///
  /// The push payload carries no `UserNotifications` id: the sender builds the FCM data
  /// map first and the feed row is inserted from it afterwards (`_shared/notification_log.ts`),
  /// so the id does not exist yet at send time. The row is therefore matched on
  /// **(type, reference_id)** — the same pair that sender writes, where `type` is
  /// `data.type` and `reference_id` is the id `NotificationsService.extractReferenceId`
  /// pulls out of the same payload. If you add a notification type, add it to that switch
  /// too, or its badge will not clear on tap.
  ///
  /// Every unread row sharing the pair is cleared, which is the point: three unread
  /// `chat_message` rows for one conversation all become read the moment that conversation
  /// opens, so the badge goes to 0 instead of 2.
  ///
  /// [referenceId] null means a broadcast type with nothing to point at
  /// (`custom_notification`). The pair cannot tell two unrelated announcements apart, so
  /// only the newest unread row is cleared rather than the whole backlog.
  Future<void> markReadForPush({
    required String userId,
    required String type,
    String? referenceId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    if (referenceId == null) {
      final rows = await _client
          .from('UserNotifications')
          .select('id')
          .eq('user_id', userId)
          .eq('type', type)
          .isFilter('reference_id', null)
          .isFilter('read_at', null)
          .order('created_at', ascending: false)
          .limit(1);
      final list = rows as List;
      if (list.isEmpty) return;
      await _client
          .from('UserNotifications')
          .update({'read_at': now})
          .eq('id', (list.first as Map<String, dynamic>)['id'] as int)
          .isFilter('read_at', null);
      return;
    }

    await _client
        .from('UserNotifications')
        .update({'read_at': now})
        .eq('user_id', userId)
        .eq('type', type)
        .eq('reference_id', referenceId)
        .isFilter('read_at', null);
  }

  /// Auto-clears bid invitations whose job is already filled or past bidding.
  ///
  /// Reported by a DJ: having to hand-mark eight "Nyt job" notifications read
  /// once the jobs were taken. Nothing server-side can do this cheaply — the
  /// `UserNotifications` row is written per recipient at send time and no
  /// trigger walks it when a job closes — so the client resolves it on fetch.
  ///
  /// Returns the ids it marked read, so the caller can flip them locally
  /// instead of re-fetching.
  ///
  /// Best-effort by design: any failure returns an empty set and leaves the feed
  /// exactly as it was. It only ever marks rows READ — it never deletes, so a
  /// wrong call is recoverable and the row stays visible under "Alle".
  Future<Set<int>> markStaleBidInvitationsRead(
    String userId,
    List<AppNotification> notifications,
  ) async {
    final candidates =
        notifications
            .where(
              (n) =>
                  !n.isRead &&
                  kBidInvitationNotificationTypes.contains(n.type) &&
                  int.tryParse(n.referenceId ?? '') != null,
            )
            .toList();
    if (candidates.isEmpty) return const {};

    final jobIds = <int>{};
    final extJobIds = <int>{};
    for (final n in candidates) {
      final id = int.parse(n.referenceId!);
      if (n.type == 'new_ext_job') {
        extJobIds.add(id);
      } else {
        jobIds.add(id);
      }
    }

    final Map<int, JobBidState> jobStates;
    final Map<int, JobBidState> extJobStates;
    try {
      jobStates = await _fetchJobStates(jobIds);
      extJobStates = await _fetchExtJobStates(extJobIds);
    } catch (_) {
      // A read failure must never look like "every job is gone".
      return const {};
    }

    final staleIds = <int>{};
    for (final n in candidates) {
      final id = int.parse(n.referenceId!);
      final state = n.type == 'new_ext_job' ? extJobStates[id] : jobStates[id];
      if (isBidInvitationStale(type: n.type, role: n.role, state: state)) {
        staleIds.add(n.id);
      }
    }
    if (staleIds.isEmpty) return const {};

    try {
      await _client
          .from('UserNotifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', userId)
          .inFilter('id', staleIds.toList())
          .isFilter('read_at', null);
    } catch (_) {
      return const {};
    }
    return staleIds;
  }

  /// A missing id in the returned map means the row was not readable — archived
  /// jobs are hidden from performers by RLS, and an archived job is dead.
  Future<Map<int, JobBidState>> _fetchJobStates(Set<int> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _client
        .from('Jobs')
        .select('id, status')
        .inFilter('id', ids.toList());
    return {
      for (final r in rows as List)
        (r as Map<String, dynamic>)['id'] as int: JobBidState(
          status: r['status'] as String?,
        ),
    };
  }

  /// ExtJobs need two extra signals: a self-serve win leaves
  /// `assigned_musician_id` NULL and shows up only as a won `ServiceOffers` row,
  /// while an admin assignment is the other way round. Both mean "taken".
  Future<Map<int, JobBidState>> _fetchExtJobStates(Set<int> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _client
        .from('ExtJobs')
        .select('id, status, assigned_musician_id')
        .inFilter('id', ids.toList());

    final wonOffers = await _client
        .from('ServiceOffers')
        .select('ext_job_id')
        .eq('status', 'won')
        .inFilter('ext_job_id', ids.toList());
    final wonExtJobIds = {
      for (final r in wonOffers as List)
        if ((r as Map<String, dynamic>)['ext_job_id'] != null)
          r['ext_job_id'] as int,
    };

    return {
      for (final r in rows as List)
        (r as Map<String, dynamic>)['id'] as int: JobBidState(
          status: r['status'] as String?,
          assignedMusicianId: r['assigned_musician_id'] as String?,
          hasWonOffer: wonExtJobIds.contains(r['id'] as int),
        ),
    };
  }

  Future<void> markAllRead(String userId) async {
    await _client
        .from('UserNotifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }
}
