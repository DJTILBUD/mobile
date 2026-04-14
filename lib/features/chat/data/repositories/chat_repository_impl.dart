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
  }) async {
    final model = await _datasource.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderType: senderType,
      message: message,
    );
    return model.toEntity();
  }

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
}
