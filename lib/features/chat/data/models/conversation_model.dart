import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.createdAt,
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
    final isCurrentUserDj = currentUserId == djId;
    if (isCurrentUserDj) return musicianName != null;
    // For musicians: accept if DJ has a DjInfos record OR ext job has an assigned name
    return djName != null || assignedDjName != null;
  }

  Conversation toEntity(String currentUserId) {
    final isCurrentUserDj = currentUserId == djId;
    final effectiveDjName = djName ?? assignedDjName;
    final partnerName = isCurrentUserDj
        ? (musicianName ?? 'Ukendt musiker')
        : (effectiveDjName ?? 'Ukendt DJ');

    final senderType = isCurrentUserDj ? 'dj' : 'musician';

    final effectiveJobId = jobId ?? extJobId;
    final effectiveEventType = jobEventType ?? extJobEventType;
    final jobInfo = effectiveJobId != null && effectiveEventType != null
        ? '#$effectiveJobId • ${eventTypeLabel(effectiveEventType)}'
        : effectiveEventType != null
            ? eventTypeLabel(effectiveEventType)
            : 'Arrangement';

    final partnerAvatarUrl =
        isCurrentUserDj ? musicianAvatarUrl : djAvatarUrl;

    return Conversation(
      id: id,
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
