import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.message,
    required this.createdAt,
    this.readAt,
    this.isSystemMessage = false,
  });

  final int id;
  final int conversationId;
  final String senderId;
  final String senderType;
  final String message;
  final String createdAt;
  final String? readAt;
  final bool isSystemMessage;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] as num).toInt(),
      conversationId: (json['conversation_id'] as num).toInt(),
      senderId: json['sender_id'] as String,
      senderType: json['sender_type'] as String,
      message: json['message'] as String,
      createdAt: json['created_at'] as String,
      readAt: json['read_at'] as String?,
      isSystemMessage: json['is_system_message'] as bool? ?? false,
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderType: senderType,
      message: message,
      createdAt: DateTime.parse(createdAt),
      readAt: readAt != null ? DateTime.parse(readAt!) : null,
      isSystemMessage: isSystemMessage,
    );
  }
}
