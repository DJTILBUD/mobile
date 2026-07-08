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
    int? replyToId,
    String? attachmentUrl,
  });

  /// Uploads a chat image to S3 and returns its public URL (for `attachment_url`).
  Future<String> uploadChatImage({
    required String userId,
    required String filePath,
  });

  /// Marks all unread messages from the other participant as read.
  Future<void> markMessagesAsRead({
    required int conversationId,
    required String currentUserId,
  });

  /// All emoji reactions in a conversation.
  Future<List<MessageReaction>> fetchReactions(int conversationId);

  /// Toggles the current user's emoji reaction on a message.
  Future<void> toggleReaction({
    required int messageId,
    required int conversationId,
    required String userId,
    required String emoji,
  });
}
