import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/features/chat/data/datasources/admin_support_datasource.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/job_link.dart';

final adminSupportDatasourceProvider = Provider<AdminSupportDatasource>(
  (ref) => AdminSupportDatasource(Supabase.instance.client),
);

/// Whether the current user is an admin. Drives the Support tab visibility. Cached for the session;
/// defaults to false (feature hidden) until it resolves. Never throws.
final isAdminProvider = FutureProvider<bool>(
  (ref) => ref.read(adminSupportDatasourceProvider).fetchIsAdmin(),
);

/// The admin support inbox: every support thread, refreshed on any chat change (Realtime pings a
/// re-fetch through the endpoint, since RLS may filter the admin's raw payload).
final adminSupportThreadsProvider = StateNotifierProvider<
  AdminSupportThreadsNotifier,
  AsyncValue<List<AdminSupportThread>>
>(
  (ref) => AdminSupportThreadsNotifier(
    ref.watch(adminSupportDatasourceProvider),
    Supabase.instance.client,
  ),
);

/// Number of support threads with unread activity, for the Support tab badge.
final adminSupportUnreadCountProvider = Provider<int>((ref) {
  final threads = ref.watch(adminSupportThreadsProvider);
  return threads.maybeWhen(
    data: (list) => list.where((t) => t.hasUnread).length,
    orElse: () => 0,
  );
});

/// Composer "@" job picker for the admin thread. Keyed on a
/// "recipientUserId|query" string (string key mirrors the musician
/// `linkableJobsProvider`). Debouncing is done in the screen.
final adminLinkableJobsProvider = FutureProvider.autoDispose
    .family<List<LinkableJob>, String>((ref, key) {
      final sep = key.indexOf('|');
      final recipientUserId = sep >= 0 ? key.substring(0, sep) : '';
      final query = sep >= 0 ? key.substring(sep + 1) : key;
      return ref
          .read(adminSupportDatasourceProvider)
          .searchLinkableJobs(query, recipientUserId: recipientUserId);
    });

/// Resolves the `@job:`/`@extjob:` tokens in a thread to labels (chip rendering).
/// Keyed on a comma-joined ref list so it re-runs only when the set changes.
final adminJobLinkResolutionsProvider = FutureProvider.autoDispose
    .family<Map<String, JobLinkResolution>, String>((ref, refsCsv) {
      final refs = refsCsv.split(',').where((s) => s.isNotEmpty).toList();
      return ref.read(adminSupportDatasourceProvider).resolveJobLinks(refs);
    });

/// Messages + reactions of one support thread (admin view).
final adminThreadMessagesProvider = StateNotifierProvider.autoDispose
    .family<AdminThreadMessagesNotifier, AsyncValue<AdminThreadData>, int>(
      (ref, conversationId) => AdminThreadMessagesNotifier(
        ref.watch(adminSupportDatasourceProvider),
        Supabase.instance.client,
        conversationId,
      ),
    );

class AdminSupportThreadsNotifier
    extends StateNotifier<AsyncValue<List<AdminSupportThread>>>
    with WidgetsBindingObserver {
  AdminSupportThreadsNotifier(this._ds, this._client)
    : super(const AsyncLoading()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  final AdminSupportDatasource _ds;
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  Future<void> _init() async {
    await _fetch();
    _subscribe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fetch();
  }

  Future<void> _fetch() async {
    try {
      final threads = await _ds.fetchThreads();
      if (mounted) state = AsyncData(threads);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetch();
  }

  void _subscribe() {
    _channel =
        _client
            .channel('admin-support-threads')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ChatMessages',
              callback: (_) => _fetch(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'Conversations',
              callback: (_) => _fetch(),
            )
            .subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}

class AdminThreadMessagesNotifier
    extends StateNotifier<AsyncValue<AdminThreadData>> {
  AdminThreadMessagesNotifier(this._ds, this._client, this._conversationId)
    : super(const AsyncLoading()) {
    _init();
  }

  final AdminSupportDatasource _ds;
  final SupabaseClient _client;
  final int _conversationId;
  RealtimeChannel? _channel;

  Future<void> _init() async {
    await _fetch();
    _subscribe();
  }

  Future<void> _fetch() async {
    try {
      final data = await _ds.fetchMessages(_conversationId);
      if (mounted) state = AsyncData(data);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }

  void _subscribe() {
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'conversation_id',
      value: _conversationId,
    );
    _channel =
        _client
            .channel('admin-support-msgs-$_conversationId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ChatMessages',
              filter: filter,
              callback: (_) => _fetch(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ChatMessageReactions',
              filter: filter,
              callback: (_) => _fetch(),
            )
            .subscribe();
  }

  /// Send an admin reply. Returns null on success, a Danish error string on failure.
  Future<String?> send(
    String message, {
    int? replyToId,
    String? attachmentUrl,
  }) async {
    final err = await _ds.sendMessage(
      _conversationId,
      message,
      replyToId: replyToId,
      attachmentUrl: attachmentUrl,
    );
    if (err == null) await _fetch();
    return err;
  }

  /// Uploads an image to S3 and returns its public URL (throws on failure).
  Future<String> uploadImage({
    required String userId,
    required String filePath,
  }) => _ds.uploadImage(userId: userId, filePath: filePath);

  Future<void> toggleReaction(int messageId, String emoji) async {
    try {
      await _ds.toggleReaction(_conversationId, messageId, emoji);
      await _fetch();
    } catch (_) {
      // Non-fatal; the next Realtime refresh reconciles.
    }
  }

  Future<void> markRead() async {
    try {
      await _ds.markRead(_conversationId);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}
