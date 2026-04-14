import 'package:dj_tilbud_app/features/profile/domain/entities/standard_message.dart';

class StandardMessageModel {
  const StandardMessageModel({
    required this.id,
    required this.messageText,
    required this.eventType,
    required this.createdAt,
  });

  final int id;
  final String messageText;
  final String eventType;
  final String createdAt;

  factory StandardMessageModel.fromJson(Map<String, dynamic> json) {
    return StandardMessageModel(
      id: (json['id'] as num).toInt(),
      messageText: json['message_text'] as String,
      eventType: json['event_type'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  StandardMessage toEntity() {
    return StandardMessage(
      id: id,
      messageText: messageText,
      eventType: eventType,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
