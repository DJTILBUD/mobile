import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
import 'package:dj_tilbud_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';

/// Emoji reactions for a conversation, keyed by message id, kept live via Realtime.
/// Realtime lives in the provider (never a widget), per the app's architecture rule.
class ReactionsNotifier extends StateNotifier<Map<int, List<MessageReaction>>> {
  ReactionsNotifier(this._repository, this._client, this._conversationId)
    : super(const {}) {
    _load();
    _subscribe();
  }

  final ChatRepository _repository;
  final SupabaseClient _client;
  final int _conversationId;
  RealtimeChannel? _channel;

  Future<void> _load() async {
    try {
      final list = await _repository.fetchReactions(_conversationId);
      final map = <int, List<MessageReaction>>{};
      for (final r in list) {
        (map[r.messageId] ??= []).add(r);
      }
      if (mounted) state = map;
    } catch (_) {
      // keep existing state
    }
  }

  void _subscribe() {
    // The reaction set per conversation is tiny, so reloading on any change is simplest + correct.
    _channel =
        _client
            .channel('reactions-$_conversationId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ChatMessageReactions',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: _conversationId,
              ),
              callback: (_) => _load(),
            )
            .subscribe();
  }

  /// The current user's emoji on [messageId], or null.
  String? myEmoji(int messageId, String userId) {
    for (final r in state[messageId] ?? const <MessageReaction>[]) {
      if (r.userId == userId) return r.emoji;
    }
    return null;
  }

  Future<void> toggle({
    required int messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      await _repository.toggleReaction(
        messageId: messageId,
        conversationId: _conversationId,
        userId: userId,
        emoji: emoji,
      );
      await _load();
    } catch (_) {
      // ignore — realtime will reconcile
    }
  }

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}

final conversationReactionsProvider = StateNotifierProvider.autoDispose
    .family<ReactionsNotifier, Map<int, List<MessageReaction>>, int>(
      (ref, conversationId) => ReactionsNotifier(
        ref.watch(chatRepositoryProvider),
        ref.watch(supabaseClientProvider),
        conversationId,
      ),
    );
