import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/notifications/app_badge.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/notifications/data/notifications_datasource.dart';
import 'package:dj_tilbud_app/features/notifications/domain/entities/app_notification.dart';

final notificationsDatasourceProvider = Provider<NotificationsDatasource>(
  (ref) => NotificationsDatasource(ref.watch(supabaseClientProvider)),
);

/// Holds the user's notification feed and keeps it live via a Realtime subscription
/// on UserNotifications (rule: Realtime lives in a provider, not a widget). Mirrors
/// ConversationsNotifier: fetch on init, re-fetch on resume, coalesce bursts.
class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>>
    with WidgetsBindingObserver {
  NotificationsNotifier(this._ds, this._client, this._userId)
    : super(const AsyncLoading()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  final NotificationsDatasource _ds;
  final SupabaseClient _client;
  final String _userId;
  RealtimeChannel? _channel;
  Timer? _debounce;

  Future<void> _init() async {
    await _fetchSilent();
    _subscribe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Realtime can miss events while backgrounded — re-fetch on resume.
    if (state == AppLifecycleState.resumed) _fetchSilent();
  }

  Future<void> _fetchSilent() async {
    try {
      final items = await _ds.fetch(_userId);
      _emit(items);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }

  /// Publish a new list AND mirror the unread count onto the OS app-icon badge.
  /// Called on every data change (fetch/realtime/read) so the badge is authoritative
  /// on launch and clears as the user reads.
  void _emit(List<AppNotification> items) {
    if (!mounted) return;
    state = AsyncData(items);
    setAppIconBadge(items.where((n) => !n.isRead).length);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchSilent();
  }

  void _coalescedFetch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _fetchSilent);
  }

  void _subscribe() {
    _channel =
        _client
            .channel('user-notifications-$_userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'UserNotifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: _userId,
              ),
              callback: (_) => _coalescedFetch(),
            )
            .subscribe();
  }

  Future<void> markRead(int id) async {
    final current = state.valueOrNull;
    if (current != null) {
      // Optimistic: flip the one row read locally so the badge/dot update instantly.
      _emit([
        for (final n in current)
          n.id == id && !n.isRead ? n.copyWith(readAt: DateTime.now()) : n,
      ]);
    }
    try {
      await _ds.markRead(id);
    } catch (_) {
      await _fetchSilent();
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current != null) {
      final now = DateTime.now();
      _emit([for (final n in current) n.isRead ? n : n.copyWith(readAt: now)]);
    }
    try {
      await _ds.markAllRead(_userId);
    } catch (_) {
      await _fetchSilent();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}

final notificationsProvider = StateNotifierProvider<
  NotificationsNotifier,
  AsyncValue<List<AppNotification>>
>(
  (ref) => NotificationsNotifier(
    ref.watch(notificationsDatasourceProvider),
    ref.watch(supabaseClientProvider),
    supabase.auth.currentUser!.id,
  ),
);

/// Unread count for the app-bar bell badge. Derived from the loaded feed.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return list.where((n) => !n.isRead).length;
});
