import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.createdAt,
    this.type = 'job',
    this.userId,
    this.djId,
    this.musicianId,
    this.jobId,
    this.extJobId,
    this.lastMessageAt,
    this.djName,
    this.musicianName,
    this.assignedDjName,
    this.jobEventType,
    this.extJobEventType,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageIsSystem = false,
    this.unreadCount = 0,
    this.djAvatarUrl,
    this.musicianAvatarUrl,
  });

  final int id;
  final String createdAt;
  final String type;
  final String? userId;
  final String? djId;
  final String? musicianId;
  final int? jobId;
  final int? extJobId;
  final String? lastMessageAt;
  final String? djName;
  final String? musicianName;
  final String? assignedDjName; // ext_job.assigned_dj_name fallback
  final String? jobEventType;
  final String? extJobEventType;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final bool lastMessageIsSystem;
  final int unreadCount;
  final String? djAvatarUrl;
  final String? musicianAvatarUrl;

  factory ConversationModel.fromJson(
    Map<String, dynamic> json, {
    String? lastMessageText,
    String? lastMessageSenderId,
    bool lastMessageIsSystem = false,
    int unreadCount = 0,
    String? djAvatarUrl,
    String? musicianAvatarUrl,
  }) {
    final djJson = json['dj'] as Map<String, dynamic>?;
    final musicianJson = json['musician'] as Map<String, dynamic>?;
    final jobJson = json['job'] as Map<String, dynamic>?;
    final extJobJson = json['ext_job'] as Map<String, dynamic>?;

    return ConversationModel(
      id: (json['id'] as num).toInt(),
      createdAt: json['created_at'] as String,
      type: json['type'] as String? ?? 'job',
      userId: json['user_id'] as String?,
      djId: json['dj_id'] as String?,
      musicianId: json['musician_id'] as String?,
      jobId: (json['job_id'] as num?)?.toInt(),
      extJobId: (json['ext_job_id'] as num?)?.toInt(),
      lastMessageAt: json['last_message_at'] as String?,
      djName: djJson?['full_name'] as String?,
      musicianName: musicianJson?['full_name'] as String?,
      assignedDjName: extJobJson?['assigned_dj_name'] as String?,
      jobEventType: jobJson?['event_type'] as String?,
      extJobEventType: extJobJson?['event_type'] as String?,
      lastMessageText: lastMessageText,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageIsSystem: lastMessageIsSystem,
      unreadCount: unreadCount,
      djAvatarUrl: djAvatarUrl,
      musicianAvatarUrl: musicianAvatarUrl,
    );
  }

  /// Returns true if this conversation should be shown to [currentUserId].
  /// Mirrors web app's isConversationChatEnabledForUser.
  bool isChatEnabled(String currentUserId) {
    // The DJTILBUD support channel belongs to one user (userId); require ownership so an admin JWT
    // (broad support read via RLS) can't open someone else's support thread by id. The admin Support
    // tab surfaces other users' threads via a separate admin-only endpoint, not this path.
    if (type == 'support') return userId == currentUserId;
    final isCurrentUserDj = currentUserId == djId;
    if (isCurrentUserDj) return musicianName != null;
    // For musicians: accept if DJ has a DjInfos record OR ext job has an assigned name
    return djName != null || assignedDjName != null;
  }

  Conversation toEntity(String currentUserId) {
    final isSupport = type == 'support';
    final isCurrentUserDj = currentUserId == djId;
    final effectiveDjName = djName ?? assignedDjName;
    // Support: the counterpart is the DJTILBUD team; per-message admin identity is resolved in the
    // detail screen from each message's sender_name/sender_avatar_url.
    final partnerName =
        isSupport
            ? 'DJTILBUD'
            : isCurrentUserDj
            ? (musicianName ?? 'Ukendt musiker')
            : (effectiveDjName ?? 'Ukendt DJ');

    // For the user's own support messages the role label is cosmetic (display keys off sender_id,
    // and a user->admin push has no recipient), so default to 'musician' when role is unknown.
    final senderType = isCurrentUserDj ? 'dj' : 'musician';

    final effectiveJobId = jobId ?? extJobId;
    final effectiveEventType = jobEventType ?? extJobEventType;
    final jobInfo =
        isSupport
            ? 'Support'
            : effectiveJobId != null && effectiveEventType != null
            ? '#$effectiveJobId • ${eventTypeLabel(effectiveEventType)}'
            : effectiveEventType != null
            ? eventTypeLabel(effectiveEventType)
            : 'Arrangement';

    final partnerAvatarUrl =
        isSupport ? null : (isCurrentUserDj ? musicianAvatarUrl : djAvatarUrl);

    return Conversation(
      id: id,
      type: type,
      userId: userId,
      djId: djId,
      musicianId: musicianId,
      jobId: jobId,
      extJobId: extJobId,
      lastMessageAt:
          lastMessageAt != null ? DateTime.tryParse(lastMessageAt!) : null,
      createdAt: DateTime.parse(createdAt),
      partnerName: partnerName,
      jobInfo: jobInfo,
      lastMessageText: lastMessageText,
      isLastMessageFromMe: lastMessageSenderId == currentUserId,
      lastMessageIsSystem: lastMessageIsSystem,
      senderType: senderType,
      unreadCount: unreadCount,
      partnerAvatarUrl: partnerAvatarUrl,
    );
  }
}
