import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
import 'package:dj_tilbud_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dj_tilbud_app/features/chat/data/datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._datasource);

  final ChatRemoteDatasource _datasource;

  @override
  Future<List<Conversation>> fetchConversations(String currentUserId) async {
    final models = await _datasource.fetchConversations(currentUserId);
    return models.map((m) => m.toEntity(currentUserId)).toList();
  }

  @override
  Future<List<ChatMessage>> fetchMessages(int conversationId) async {
    final models = await _datasource.fetchMessages(conversationId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required int conversationId,
    required String senderId,
    required String senderType,
    required String message,
    int? replyToId,
    String? attachmentUrl,
  }) async {
    final model = await _datasource.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderType: senderType,
      message: message,
      replyToId: replyToId,
      attachmentUrl: attachmentUrl,
    );
    return model.toEntity();
  }

  @override
  Future<ChatMessage> editMessage({
    required int messageId,
    required String senderId,
    required String message,
  }) async {
    final model = await _datasource.editMessage(
      messageId: messageId,
      senderId: senderId,
      message: message,
    );
    return model.toEntity();
  }

  @override
  Future<String> uploadChatImage({
    required String userId,
    required String filePath,
  }) => _datasource.uploadChatImage(userId: userId, filePath: filePath);

  @override
  Future<void> markMessagesAsRead({
    required int conversationId,
    required String currentUserId,
  }) async {
    await _datasource.markMessagesAsRead(
      conversationId: conversationId,
      currentUserId: currentUserId,
    );
  }

  @override
  Future<List<MessageReaction>> fetchReactions(int conversationId) =>
      _datasource.fetchReactions(conversationId);

  @override
  Future<void> toggleReaction({
    required int messageId,
    required int conversationId,
    required String userId,
    required String emoji,
  }) => _datasource.toggleReaction(
    messageId: messageId,
    conversationId: conversationId,
    userId: userId,
    emoji: emoji,
  );
}
