import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';

/// Max length of the personal video greeting (`profile_video`).
const int kProfileVideoMaxSeconds = 60;

/// Max length of an event/performance clip (`common_video`) shown on the public profile.
///
/// Raised 10 -> 15 to match the web app. Mirrors web-app `src/constants.ts`
/// `commonVideoMaxLengthSeconds` — change both together.
const int kCommonVideoMaxSeconds = 15;

/// Tolerance for container rounding, same grace the job-content validator uses: a clip the user
/// trimmed to exactly 15s often reports 15.02s, and rejecting that reads as a bug.
const int _durationGraceMs = 500;

int? maxSecondsForVideoType(UserFileType type) {
  switch (type) {
    case UserFileType.profileVideo:
      return kProfileVideoMaxSeconds;
    case UserFileType.commonVideo:
      return kCommonVideoMaxSeconds;
    default:
      return null;
  }
}

/// Hard-validates a profile video's length before upload. Returns a Danish error string, or null
/// when the clip is acceptable (or [type] is not a video).
///
/// This exists because there is NO server-side duration check anywhere in the platform (no
/// ffprobe — see web-app/CLAUDE.md "File uploads = AWS S3"), so the client is the only gate. The
/// web app enforced these limits from the start; mobile previously showed "maks 10 sek." as a
/// label while accepting a clip of any length, so the two platforms disagreed about what a valid
/// profile actually contained. Mirrors the `maxLength` prop on web's `VideoUploader`.
Future<String?> validateProfileVideo(String filePath, UserFileType type) async {
  final maxSeconds = maxSecondsForVideoType(type);
  if (maxSeconds == null) return null;

  final controller = VideoPlayerController.file(File(filePath));
  try {
    await controller.initialize();
    final duration = controller.value.duration;

    if (duration.inMilliseconds > (maxSeconds * 1000 + _durationGraceMs)) {
      return 'Videoen må højst være $maxSeconds sekunder '
          '(din er ${duration.inSeconds} sek.).';
    }
    return null;
  } catch (_) {
    return 'Kunne ikke læse videoen. Prøv en anden fil.';
  } finally {
    await controller.dispose();
  }
}
