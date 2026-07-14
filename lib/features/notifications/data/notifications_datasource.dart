import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/features/notifications/domain/entities/app_notification.dart';

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

  Future<void> markAllRead(String userId) async {
    await _client
        .from('UserNotifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }
}
