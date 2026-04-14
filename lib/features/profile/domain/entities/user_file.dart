enum UserFileType {
  profile,
  common,
  profileVideo,
  commonVideo,
  thumbnail;

  static UserFileType fromString(String value) {
    switch (value) {
      case 'profile':
        return UserFileType.profile;
      case 'common':
        return UserFileType.common;
      case 'profile_video':
        return UserFileType.profileVideo;
      case 'common_video':
        return UserFileType.commonVideo;
      case 'thumbnail':
        return UserFileType.thumbnail;
      default:
        return UserFileType.common;
    }
  }

  String toDbString() {
    switch (this) {
      case UserFileType.profile:
        return 'profile';
      case UserFileType.common:
        return 'common';
      case UserFileType.profileVideo:
        return 'profile_video';
      case UserFileType.commonVideo:
        return 'common_video';
      case UserFileType.thumbnail:
        return 'thumbnail';
    }
  }
}

class UserFile {
  const UserFile({
    required this.id,
    required this.url,
    required this.type,
    required this.createdAt,
    this.thumbnailVideoId,
  });

  final int id;
  final String url;
  final UserFileType type;
  final DateTime createdAt;

  /// For thumbnail files: the ID of the video this thumbnail belongs to.
  final int? thumbnailVideoId;
}
