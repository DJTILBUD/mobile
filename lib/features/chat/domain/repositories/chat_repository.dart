import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  /// Fetches all conversations for the current user (RLS-filtered),
  /// enriched with last message preview and unread count.
  Future<List<Conversation>> fetchConversations(String currentUserId);

  /// Fetches all messages in [conversationId], oldest first.
  Future<List<ChatMessage>> fetchMessages(int conversationId);

  /// Inserts a new message and returns it.
  Future<ChatMessage> sendMessage({
    required int conversationId,
    required String senderId,
    required String senderType,
    required String message,
  });

  /// Marks all unread messages from the other participant as read.
  Future<void> markMessagesAsRead({
    required int conversationId,
    required String currentUserId,
  });
}
