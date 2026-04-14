class Conversation {
  const Conversation({
    required this.id,
    required this.createdAt,
    required this.partnerName,
    required this.jobInfo,
    required this.unreadCount,
    required this.isLastMessageFromMe,
    required this.lastMessageIsSystem,
    required this.senderType,
    this.djId,
    this.musicianId,
    this.jobId,
    this.extJobId,
    this.lastMessageAt,
    this.lastMessageText,
    this.partnerAvatarUrl,
  });

  final int id;
  final String? djId;
  final String? musicianId;
  final int? jobId;
  final int? extJobId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  /// Display name of the other participant.
  final String partnerName;

  /// Human-readable job label, e.g. "#1234 • Bryllup".
  final String jobInfo;

  /// Preview text of the most recent message.
  final String? lastMessageText;

  /// Profile image URL of the other participant (from UserFiles, type=profile).
  final String? partnerAvatarUrl;

  /// True if the last message was sent by the current user.
  final bool isLastMessageFromMe;

  final bool lastMessageIsSystem;

  /// 'dj' if the current user is the DJ side, 'musician' otherwise.
  final String senderType;

  final int unreadCount;

  bool get hasUnread => unreadCount > 0;
}
