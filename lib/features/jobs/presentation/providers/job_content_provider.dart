import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/jobs/data/datasources/job_content_remote_datasource.dart';

const int kContentVideoMaxSeconds = 15;
const double kContentVideoTargetRatio = 9 / 16; // 0.5625 (portrait)
const double _ratioTolerance = 0.04;

/// Identifies the job a content clip belongs to (exactly one id is set).
class JobContentKey {
  const JobContentKey({this.quoteId, this.extJobId});
  final int? quoteId;
  final int? extJobId;

  @override
  bool operator ==(Object other) =>
      other is JobContentKey && other.quoteId == quoteId && other.extJobId == extJobId;

  @override
  int get hashCode => Object.hash(quoteId, extJobId);
}

final jobContentDatasourceProvider = Provider<JobContentRemoteDatasource>((ref) {
  return JobContentRemoteDatasource(ref.watch(supabaseClientProvider));
});

final jobContentProvider =
    FutureProvider.family<List<JobContentClip>, JobContentKey>((ref, key) async {
  return ref
      .watch(jobContentDatasourceProvider)
      .fetchJobContent(quoteId: key.quoteId, extJobId: key.extJobId);
});

/// All of the current DJ's content clips across every job (profile library).
final myJobContentProvider = FutureProvider<List<MyJobContentClip>>((ref) async {
  return ref.watch(jobContentDatasourceProvider).fetchMyJobContent();
});

/// Label for the job a scoped upload targets (shown on the content screen).
final scopedJobSummaryProvider =
    FutureProvider.family<JobSummary, JobContentKey>((ref, key) async {
  return ref
      .watch(jobContentDatasourceProvider)
      .fetchJobSummary(quoteId: key.quoteId, extJobId: key.extJobId);
});

/// Hard-validates a clip before upload (max 15s, 9:16 portrait). Returns a
/// Danish error string, or null when the clip is acceptable. Server-side
/// enforcement isn't possible (no ffprobe), so this is the gate.
Future<String?> validateContentVideo(String filePath) async {
  final controller = VideoPlayerController.file(File(filePath));
  try {
    await controller.initialize();
    final duration = controller.value.duration;
    final ratio = controller.value.aspectRatio;

    if (duration.inMilliseconds > (kContentVideoMaxSeconds * 1000 + 500)) {
      return 'Videoen må højst være $kContentVideoMaxSeconds sekunder '
          '(din er ${duration.inSeconds} sek.).';
    }
    if ((ratio - kContentVideoTargetRatio).abs() > _ratioTolerance) {
      return 'Videoen skal være i lodret 9:16 format (optag med telefonen lodret).';
    }
    return null;
  } catch (_) {
    return 'Kunne ikke læse videoen. Prøv en anden fil.';
  } finally {
    await controller.dispose();
  }
}
