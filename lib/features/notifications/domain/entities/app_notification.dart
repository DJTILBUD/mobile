/// One entry in the in-app notification feed — a persisted copy of a push that was
/// sent to this user (written server-side by the notify-* Edge Functions). `data` is
/// the exact FCM data payload, so tapping it can replay NotificationsService.navigateTo.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    this.role,
    required this.title,
    this.body,
    required this.data,
    this.referenceId,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final String type;
  final String? role;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final String? referenceId;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    role: role,
    title: title,
    body: body,
    data: data,
    referenceId: referenceId,
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'unknown',
      role: json['role'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      data:
          rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : <String, dynamic>{},
      referenceId: json['reference_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt:
          json['read_at'] != null
              ? DateTime.parse(json['read_at'] as String)
              : null,
    );
  }
}
