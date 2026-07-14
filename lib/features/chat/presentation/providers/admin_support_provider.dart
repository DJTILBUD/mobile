import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/features/chat/data/datasources/admin_support_datasource.dart';
import 'package:dj_tilbud_app/features/chat/data/models/chat_message_model.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
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

/// Cross-conversation support search: fetches the thread list filtered by [query] (user name +
/// message content) server-side, with per-thread match snippets. Keyed on the trimmed query so it
/// re-runs only when the term changes; the search bar debounces before setting the key.
final adminSupportSearchProvider = FutureProvider.autoDispose
    .family<List<AdminSupportThread>, String>((ref, query) {
      return ref.read(adminSupportDatasourceProvider).fetchThreads(q: query);
    });

/// Recipient options for the "new message" composer (DJs + musicians by name). Keyed on the trimmed
/// query; the sheet debounces before setting the key.
final adminSupportRecipientsProvider = FutureProvider.autoDispose
    .family<List<AdminRecipient>, String>((ref, query) {
      return ref.read(adminSupportDatasourceProvider).fetchRecipients(q: query);
    });

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

  /// Optimistically re-bold a thread (mark unread), then persist. The realtime subscription and
  /// the next fetch reconcile the exact server-computed count; on failure we re-fetch to undo.
  Future<void> markThreadUnread(int conversationId) async {
    _patchUnread(conversationId, unread: true);
    try {
      await _ds.markUnread(conversationId);
    } catch (_) {
      await _fetch();
    }
  }

  /// Optimistically clear a thread's unread state (used on open so the badge drops instantly),
  /// then persist. Failure reconciles via re-fetch.
  Future<void> markThreadRead(int conversationId) async {
    _patchUnread(conversationId, unread: false);
    try {
      await _ds.markRead(conversationId);
    } catch (_) {
      await _fetch();
    }
  }

  void _patchUnread(int conversationId, {required bool unread}) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final t in current)
        if (t.id == conversationId)
          t.copyWith(
            unreadCount: unread ? (t.unreadCount > 0 ? t.unreadCount : 1) : 0,
          )
        else
          t,
    ]);
  }

  // A single user action emits several DB events (message insert + Conversations.last_message_at
  // update), and this subscription is unfiltered (any support chat, any thread). Coalesce a burst
  // into ONE refetch instead of one full inbox reload per event. The endpoint is already batched.
  Timer? _fetchDebounce;
  void _coalescedFetch() {
    _fetchDebounce?.cancel();
    _fetchDebounce = Timer(const Duration(milliseconds: 400), _fetch);
  }

  void _subscribe() {
    _channel =
        _client
            .channel('admin-support-threads')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ChatMessages',
              callback: (_) => _coalescedFetch(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'Conversations',
              callback: (_) => _coalescedFetch(),
            )
            .subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fetchDebounce?.cancel();
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
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'ChatMessages',
              filter: filter,
              callback: (payload) => _applyMessageInsert(payload.newRecord),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'ChatMessages',
              filter: filter,
              callback: (payload) => _applyMessageUpdate(payload.newRecord),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ChatMessageReactions',
              filter: filter,
              callback: _applyReactionChange,
            )
            .subscribe();
  }

  // Apply realtime payloads incrementally instead of re-downloading the whole thread on every event
  // (a full refetch per inbound message/reaction caused flicker + scroll wobble). Fall back to a full
  // fetch only when the payload is empty (admin RLS can strip it) or unparseable.
  void _applyMessageInsert(Map<String, dynamic> raw) {
    final current = state.valueOrNull;
    if (current == null) return;
    final json = Map<String, dynamic>.from(raw);
    if (json.isEmpty) {
      _fetch();
      return;
    }
    try {
      final msg = ChatMessageModel.fromJson(json).toEntity();
      var list = current.messages;
      // A real admin echo replaces any optimistic temp (negative id) appended on send.
      if (msg.senderType == 'admin')
        list = list.where((m) => m.id > 0).toList();
      if (!list.any((m) => m.id == msg.id)) list = [...list, msg];
      if (mounted) {
        state = AsyncData(
          AdminThreadData(
            messages: list,
            reactionsByMessage: current.reactionsByMessage,
          ),
        );
      }
    } catch (_) {
      _fetch();
    }
  }

  void _applyMessageUpdate(Map<String, dynamic> raw) {
    final current = state.valueOrNull;
    if (current == null) return;
    final json = Map<String, dynamic>.from(raw);
    if (json.isEmpty) {
      _fetch();
      return;
    }
    try {
      final updated = ChatMessageModel.fromJson(json).toEntity();
      if (mounted) {
        state = AsyncData(
          AdminThreadData(
            messages:
                current.messages
                    .map((m) => m.id == updated.id ? updated : m)
                    .toList(),
            reactionsByMessage: current.reactionsByMessage,
          ),
        );
      }
    } catch (_) {
      _fetch();
    }
  }

  void _applyReactionChange(PostgresChangePayload payload) {
    final current = state.valueOrNull;
    if (current == null) return;
    final source =
        payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
    final mid = (source['message_id'] as num?)?.toInt();
    final uid = source['user_id'] as String?;
    // DELETE payloads may carry only the PK (no message_id/user_id) → reconcile with a fetch.
    if (mid == null || uid == null) {
      _fetch();
      return;
    }
    final map = <int, List<AdminReaction>>{
      for (final e in current.reactionsByMessage.entries)
        e.key: List<AdminReaction>.from(e.value),
    };
    // One reaction per (message, user): drop the user's existing one, then re-add on insert/update.
    map[mid] = (map[mid] ?? []).where((r) => r.userId != uid).toList();
    final emoji =
        payload.newRecord.isNotEmpty
            ? payload.newRecord['emoji'] as String?
            : null;
    if (emoji != null) {
      map[mid]!.add(AdminReaction(messageId: mid, userId: uid, emoji: emoji));
    }
    if (map[mid]!.isEmpty) map.remove(mid);
    if (mounted) {
      state = AsyncData(
        AdminThreadData(messages: current.messages, reactionsByMessage: map),
      );
    }
  }

  /// Send an admin reply. Optimistic: the bubble appears instantly with a temp id; the realtime
  /// echo (or a fallback fetch) swaps in the server row. Returns null on success, else Danish error.
  Future<String?> send(
    String message, {
    int? replyToId,
    String? attachmentUrl,
  }) async {
    final current = state.valueOrNull;
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    if (current != null && mounted) {
      final temp = ChatMessage(
        id: tempId,
        conversationId: _conversationId,
        senderId: _client.auth.currentUser?.id ?? '',
        senderType: 'admin',
        message: message,
        createdAt: DateTime.now(),
        replyToId: replyToId,
        attachmentUrl: attachmentUrl,
      );
      state = AsyncData(
        AdminThreadData(
          messages: [...current.messages, temp],
          reactionsByMessage: current.reactionsByMessage,
        ),
      );
    }
    final err = await _ds.sendMessage(
      _conversationId,
      message,
      replyToId: replyToId,
      attachmentUrl: attachmentUrl,
    );
    if (err != null) {
      // Roll back the optimistic bubble on failure.
      final now = state.valueOrNull;
      if (now != null && mounted) {
        state = AsyncData(
          AdminThreadData(
            messages: now.messages.where((m) => m.id != tempId).toList(),
            reactionsByMessage: now.reactionsByMessage,
          ),
        );
      }
    }
    // On success the realtime INSERT echo strips the temp and appends the real row; if RLS strips
    // the payload, that handler falls back to a fetch which reconciles too.
    return err;
  }

  /// Uploads an image to S3 and returns its public URL (throws on failure).
  Future<String> uploadImage({
    required String userId,
    required String filePath,
  }) => _ds.uploadImage(userId: userId, filePath: filePath);

  Future<void> toggleReaction(int messageId, String emoji) async {
    // No full refetch — the ChatMessageReactions realtime handler patches the map when the change
    // echoes back. Errors reconcile on the next event/fetch.
    try {
      await _ds.toggleReaction(_conversationId, messageId, emoji);
    } catch (_) {
      // Non-fatal.
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
