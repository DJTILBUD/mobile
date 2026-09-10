enum UserFileType {
  profile,
  common,
  profileVideo,
  commonVideo,
  thumbnail,
  jobContent,
  djMix;

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
      case 'job_content':
        return UserFileType.jobContent;
      case 'dj_mix':
        return UserFileType.djMix;
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
      case UserFileType.jobContent:
        return 'job_content';
      case UserFileType.djMix:
        return 'dj_mix';
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
    this.description,
    this.sortOrder,
  });

  final int id;
  final String url;
  final UserFileType type;
  final DateTime createdAt;

  /// For thumbnail files: the ID of the video this thumbnail belongs to.
  final int? thumbnailVideoId;

  /// Optional caption/title. Used by dj_mix rows (the mix label).
  final String? description;

  /// Display position within this user's gallery of the same [type] (lower = earlier).
  ///
  /// Nullable and optional on purpose: it is null for rows uploaded before the user ever
  /// reordered that gallery, and [sortUserFiles] sorts nulls LAST so a fresh upload appends
  /// instead of jumping to the front. Optional in the constructor so the ad-hoc `UserFile(...)`
  /// built in job_content_remote_datasource keeps compiling.
  final int? sortOrder;

  UserFile copyWith({int? sortOrder}) {
    return UserFile(
      id: id,
      url: url,
      type: type,
      createdAt: createdAt,
      thumbnailVideoId: thumbnailVideoId,
      description: description,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
