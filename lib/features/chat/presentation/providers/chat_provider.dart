import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
import 'package:dj_tilbud_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dj_tilbud_app/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:dj_tilbud_app/features/chat/data/models/chat_message_model.dart';
import 'package:dj_tilbud_app/features/chat/data/repositories/chat_repository_impl.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ChatRepositoryImpl(ChatRemoteDatasource(client));
});

// ─── Conversations list ───────────────────────────────────────────────────────

class ConversationsNotifier
    extends StateNotifier<AsyncValue<List<Conversation>>> {
  ConversationsNotifier(this._repository, this._client, this._userId)
      : super(const AsyncLoading()) {
    _init();
  }

  final ChatRepository _repository;
  final SupabaseClient _client;
  final String _userId;
  RealtimeChannel? _channel;

  Future<void> _init() async {
    await _fetchSilent();
    _subscribeToRealtime();
  }

  Future<void> _fetchSilent() async {
    try {
      final conversations = await _repository.fetchConversations(_userId);
      if (mounted) state = AsyncData(conversations);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchSilent();
  }

  void _subscribeToRealtime() {
    // One channel with chained handlers — mirrors web app exactly.
    // Web app: .channel("conversations-changes").on(...).on(...).on(...).subscribe()
    _channel = _client
        .channel('conversations-$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'dj_id',
            value: _userId,
          ),
          callback: (_) => _fetchSilent(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'musician_id',
            value: _userId,
          ),
          callback: (_) => _fetchSilent(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ChatMessages',
          callback: (_) => _fetchSilent(),
        )
        .subscribe((status, [error]) {
          // ignore: avoid_print
          print('[Chat:convs] $status ${error ?? ''}');
        });
  }

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}

final conversationsProvider = StateNotifierProvider<ConversationsNotifier,
    AsyncValue<List<Conversation>>>(
  (ref) => ConversationsNotifier(
    ref.watch(chatRepositoryProvider),
    ref.watch(supabaseClientProvider),
    supabase.auth.currentUser!.id,
  ),
);

// ─── Conversation messages ────────────────────────────────────────────────────

class ConversationMessagesNotifier
    extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ConversationMessagesNotifier(
      this._repository, this._client, this._conversationId)
      : super(const AsyncLoading()) {
    _init();
  }

  final ChatRepository _repository;
  final SupabaseClient _client;
  final int _conversationId;
  RealtimeChannel? _channel;

  Future<void> _init() async {
    await _loadInitial();
    _subscribeToRealtime();
  }

  Future<void> _loadInitial() async {
    try {
      final messages = await _repository.fetchMessages(_conversationId);
      if (mounted) state = AsyncData(messages);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }

  /// Silent re-fetch — never sets AsyncLoading so no spinner flash.
  Future<void> _reload() async {
    try {
      final messages = await _repository.fetchMessages(_conversationId);
      if (mounted) state = AsyncData(messages);
    } catch (_) {
      // Keep showing existing data
    }
  }

  void _subscribeToRealtime() {
    // One channel with two chained handlers — mirrors web app exactly.
    // Web app: .channel(`messages-${id}`).on("INSERT",...).on("UPDATE",...).subscribe()
    _channel = _client
        .channel('messages-$_conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'ChatMessages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: _conversationId,
          ),
          callback: (payload) {
            final current = state.valueOrNull;
            if (current == null) return;

            final json = Map<String, dynamic>.from(payload.newRecord);
            if (json.isEmpty) {
              // RLS filtered the payload — re-fetch silently
              _reload();
              return;
            }
            try {
              final newMsg = ChatMessageModel.fromJson(json).toEntity();
              if (current.any((m) => m.id == newMsg.id)) return;
              if (mounted) state = AsyncData([...current, newMsg]);
            } catch (_) {
              _reload();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'ChatMessages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: _conversationId,
          ),
          callback: (payload) {
            final current = state.valueOrNull;
            if (current == null) return;

            final json = Map<String, dynamic>.from(payload.newRecord);
            if (json.isEmpty) {
              _reload();
              return;
            }
            try {
              final updated = ChatMessageModel.fromJson(json).toEntity();
              if (mounted) {
                state = AsyncData(
                  current
                      .map((m) => m.id == updated.id ? updated : m)
                      .toList(),
                );
              }
            } catch (_) {
              _reload();
            }
          },
        )
        .subscribe((status, [error]) {
          // ignore: avoid_print
          print('[Chat:msgs] $_conversationId $status ${error ?? ''}');
        });
  }

  Future<bool> sendMessage({
    required String senderId,
    required String senderType,
    required String message,
  }) async {
    try {
      await _repository.sendMessage(
        conversationId: _conversationId,
        senderId: senderId,
        senderType: senderType,
        message: message,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markAsRead(String currentUserId) async {
    try {
      await _repository.markMessagesAsRead(
        conversationId: _conversationId,
        currentUserId: currentUserId,
      );
    } catch (_) {
      // Non-critical — silent fail
    }
  }

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}

final conversationMessagesProvider = StateNotifierProvider.autoDispose
    .family<ConversationMessagesNotifier, AsyncValue<List<ChatMessage>>, int>(
  (ref, conversationId) => ConversationMessagesNotifier(
    ref.watch(chatRepositoryProvider),
    ref.watch(supabaseClientProvider),
    conversationId,
  ),
);

// ─── Total unread count ───────────────────────────────────────────────────────

/// Sum of unread message counts across all conversations.
/// Used for the red badge on the Chat nav item.
final totalUnreadChatCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider).valueOrNull ?? [];
  return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
});
