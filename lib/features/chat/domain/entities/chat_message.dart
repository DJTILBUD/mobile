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
    this.senderName,
    this.senderAvatarUrl,
    this.replyToId,
    this.attachmentUrl,
  });

  final int id;
  final int conversationId;
  final String senderId;
  final String senderType; // 'dj' | 'musician' | 'admin'
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isSystemMessage;

  /// Public S3 URL of an attached image; null for text-only messages.
  final String? attachmentUrl;

  /// Denormalized identity of an admin sender (support channel); null for dj/musician messages.
  final String? senderName;
  final String? senderAvatarUrl;

  /// The message this one replies to (resolved from the loaded message list); null if not a reply.
  final int? replyToId;

  bool get isRead => readAt != null;

  /// True for a reply from the DJTILBUD team on a support conversation.
  bool get isAdmin => senderType == 'admin';
}

/// A single emoji reaction on a message (one per user per message).
class MessageReaction {
  const MessageReaction({
    required this.messageId,
    required this.userId,
    required this.emoji,
  });

  final int messageId;
  final String userId;
  final String emoji;
}
