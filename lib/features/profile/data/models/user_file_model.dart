import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';

class UserFileModel {
  const UserFileModel({
    required this.id,
    required this.url,
    required this.type,
    required this.createdAt,
    this.thumbnailVideoId,
    this.description,
  });

  final int id;
  final String url;
  final String type;
  final String createdAt;
  final int? thumbnailVideoId;
  final String? description;

  factory UserFileModel.fromJson(Map<String, dynamic> json) {
    return UserFileModel(
      id: (json['id'] as num).toInt(),
      url: json['url'] as String,
      type: json['type'] as String,
      createdAt: json['created_at'] as String,
      thumbnailVideoId:
          json['thumbnail_video_id'] != null
              ? (json['thumbnail_video_id'] as num).toInt()
              : null,
      description: json['description'] as String?,
    );
  }

  UserFile toEntity() {
    return UserFile(
      id: id,
      url: url,
      type: UserFileType.fromString(type),
      createdAt: DateTime.parse(createdAt),
      thumbnailVideoId: thumbnailVideoId,
      description: description,
    );
  }
}
