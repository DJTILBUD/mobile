class ChatMessage {
  const ChatMessage({
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
  final String senderType; // 'dj' | 'musician'
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isSystemMessage;

  bool get isRead => readAt != null;
}
