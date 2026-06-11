import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';

/// A content clip plus its (optional) thumbnail URL.
class JobContentClip {
  const JobContentClip({required this.file, this.thumbnailUrl});
  final UserFile file;
  final String? thumbnailUrl;
}

/// Admin review status of a content clip.
enum ContentReviewStatus { pending, approved, rejected }

/// A clip plus a label for the job it belongs to (for the profile library view).
class MyJobContentClip {
  const MyJobContentClip({
    required this.file,
    this.thumbnailUrl,
    required this.isExtJob,
    this.jobId,
    this.eventType,
    this.date,
    this.leadName,
    this.status = ContentReviewStatus.pending,
  });

  final UserFile file;
  final String? thumbnailUrl;
  final bool isExtJob;
  final int? jobId;
  final String? eventType;
  final String? date;
  final String? leadName;
  final ContentReviewStatus status;

  String get jobLabel {
    final ref =
        jobId != null
            ? '${isExtJob ? "Udvalgt " : ""}Job #$jobId'
            : 'Ukendt job';
    final rest = [
      eventType,
      leadName,
      date,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    return rest.isEmpty ? ref : '$ref — $rest';
  }
}

/// A short label for the job a scoped upload targets.
class JobSummary {
  const JobSummary({
    required this.isExtJob,
    this.jobId,
    this.eventType,
    this.date,
    this.leadName,
  });
  final bool isExtJob;
  final int? jobId;
  final String? eventType;
  final String? date;
  final String? leadName;

  String get label {
    final ref =
        jobId != null
            ? '${isExtJob ? "Udvalgt " : ""}Job #$jobId'
            : 'dette job';
    final rest = [
      eventType,
      leadName,
      date,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    return rest.isEmpty ? ref : '$ref — $rest';
  }
}

/// Handles DJ "content" clips tied to a job (feature 52). Uploads go to S3 via a
/// signed URL, then ownership is verified + the row recorded through the web API
/// (`/api/files/job-content`) — never a direct UserFiles insert, so a DJ cannot
/// attach content to a job that isn't theirs.
class JobContentRemoteDatasource {
  JobContentRemoteDatasource(this._client);

  final SupabaseClient _client;

  String get _webAppBaseUrl {
    String url = EnvConfig.webAppUrl;
    if (EnvConfig.isLocal && Platform.isAndroid) {
      url = url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  String get _accessToken {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Not authenticated');
    return token;
  }

  /// Lists the content clips uploaded for one job (newest first), with thumbnails.
  Future<List<JobContentClip>> fetchJobContent({
    int? quoteId,
    int? extJobId,
  }) async {
    var query = _client.from('UserFiles').select().eq('type', 'job_content');
    query =
        quoteId != null
            ? query.eq('quote_id', quoteId)
            : query.eq('ext_job_id', extJobId as Object);
    final rows = await query.order('created_at', ascending: false);

    final videos =
        (rows as List)
            .map(
              (r) => UserFile(
                id: r['id'] as int,
                url: r['url'] as String,
                type: UserFileType.fromString(r['type'] as String),
                createdAt: DateTime.parse(r['created_at'] as String),
              ),
            )
            .toList();
    if (videos.isEmpty) return [];

    final thumbRows = await _client
        .from('UserFiles')
        .select('url, thumbnail_video_id')
        .eq('type', 'thumbnail')
        .inFilter('thumbnail_video_id', videos.map((v) => v.id).toList());
    final thumbByVideoId = {
      for (final t in (thumbRows as List))
        if (t['thumbnail_video_id'] != null)
          t['thumbnail_video_id'] as int: t['url'] as String,
    };

    return videos
        .map((v) => JobContentClip(file: v, thumbnailUrl: thumbByVideoId[v.id]))
        .toList();
  }

  /// Lists all of the current DJ's content clips across every job (newest
  /// first), each labelled with the job it belongs to.
  Future<List<MyJobContentClip>> fetchMyJobContent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final rows = await _client
        .from('UserFiles')
        .select(
          'id, url, type, created_at, quote_id, ext_job_id, verified_at, rejected_at, '
          'Quotes(id, job_id, Jobs(id, event_type, date, lead_name)), '
          'ExtJobs(id, event_type, date, lead_name)',
        )
        .eq('type', 'job_content')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final list = rows as List;
    if (list.isEmpty) return [];

    final videoIds = list.map((r) => r['id'] as int).toList();
    final thumbRows = await _client
        .from('UserFiles')
        .select('url, thumbnail_video_id')
        .eq('type', 'thumbnail')
        .inFilter('thumbnail_video_id', videoIds);
    final thumbByVideoId = {
      for (final t in (thumbRows as List))
        if (t['thumbnail_video_id'] != null)
          t['thumbnail_video_id'] as int: t['url'] as String,
    };

    return list.map((r) {
      final quote = r['Quotes'] as Map<String, dynamic>?;
      final extJob = r['ExtJobs'] as Map<String, dynamic>?;
      final job = (quote?['Jobs'] as Map<String, dynamic>?) ?? extJob;
      final isExt = r['ext_job_id'] != null;
      return MyJobContentClip(
        file: UserFile(
          id: r['id'] as int,
          url: r['url'] as String,
          type: UserFileType.fromString(r['type'] as String),
          createdAt: DateTime.parse(r['created_at'] as String),
        ),
        thumbnailUrl: thumbByVideoId[r['id'] as int],
        isExtJob: isExt,
        jobId: (quote?['job_id'] as int?) ?? (r['ext_job_id'] as int?),
        eventType: job?['event_type'] as String?,
        date: job?['date'] as String?,
        leadName: job?['lead_name'] as String?,
        status:
            r['verified_at'] != null
                ? ContentReviewStatus.approved
                : r['rejected_at'] != null
                ? ContentReviewStatus.rejected
                : ContentReviewStatus.pending,
      );
    }).toList();
  }

  /// Resolves a label (event type · customer · date) for the job a scoped
  /// upload targets, so the content screen can state which job it's for.
  Future<JobSummary> fetchJobSummary({int? quoteId, int? extJobId}) async {
    if (quoteId != null) {
      final row =
          await _client
              .from('Quotes')
              .select('job_id, Jobs(id, event_type, date, lead_name)')
              .eq('id', quoteId)
              .maybeSingle();
      final job = row?['Jobs'] as Map<String, dynamic>?;
      return JobSummary(
        isExtJob: false,
        jobId: row?['job_id'] as int?,
        eventType: job?['event_type'] as String?,
        date: job?['date'] as String?,
        leadName: job?['lead_name'] as String?,
      );
    }
    final row =
        await _client
            .from('ExtJobs')
            .select('id, event_type, date, lead_name')
            .eq('id', extJobId as Object)
            .maybeSingle();
    return JobSummary(
      isExtJob: true,
      jobId: row?['id'] as int?,
      eventType: row?['event_type'] as String?,
      date: row?['date'] as String?,
      leadName: row?['lead_name'] as String?,
    );
  }

  /// Maps a video file extension to its MIME content type. Falls back to mp4.
  static String _videoContentType(String ext) => switch (ext.toLowerCase()) {
    'mov' => 'video/quicktime',
    'm4v' => 'video/x-m4v',
    'avi' => 'video/x-msvideo',
    'webm' => 'video/webm',
    _ => 'video/mp4',
  };

  /// PUTs [file] to [url] streaming straight from disk, reporting upload
  /// progress as a 0..1 fraction via [onProgress]. Streaming (instead of
  /// `readAsBytes`) lets us surface real upload progress and applies socket
  /// backpressure, so large original-quality clips don't balloon memory.
  Future<http.StreamedResponse> _putWithProgress(
    Uri url,
    File file,
    String contentType,
    void Function(double progress)? onProgress,
  ) async {
    final total = await file.length();
    var sent = 0;
    final request =
        http.StreamedRequest('PUT', url)
          ..headers['Content-Type'] = contentType
          ..contentLength = total;

    final body = file.openRead().transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          sent += chunk.length;
          if (total > 0) onProgress?.call((sent / total).clamp(0.0, 1.0));
          sink.add(chunk);
        },
      ),
    );

    // Start sending first (subscribes to the body), then feed it with
    // backpressure and close the request stream when the file is drained.
    final response = request.send();
    unawaited(request.sink.addStream(body).then((_) => request.sink.close()));
    return response;
  }

  /// Uploads a (pre-validated) clip to S3 and records it against the job.
  ///
  /// The clip is uploaded **untouched, in its original quality** — these clips
  /// are meant for social media, so we must not re-encode/compress them. The
  /// 15s / 9:16 rule is enforced client-side before upload (`validateContentVideo`).
  Future<void> uploadJobContent({
    required String userId,
    required String filePath,
    int? quoteId,
    int? extJobId,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    // Preserve the original file's name + format (no re-encode) so quality is
    // untouched and the S3 object carries the correct extension/content type.
    final originalName = filePath.split('/').last;
    final ext =
        originalName.contains('.') ? originalName.split('.').last : 'mp4';
    final fileName =
        originalName.contains('.') ? originalName : '$originalName.mp4';
    final contentType = _videoContentType(ext);

    final signedUrlUri = Uri.parse(
      '$_webAppBaseUrl/api/files/signed-url'
      '?fileName=${Uri.encodeComponent(fileName)}'
      '&contentType=${Uri.encodeComponent(contentType)}'
      '&type=job_content'
      '&userId=${Uri.encodeComponent(userId)}',
    );
    final signedUrlRes = await http.get(signedUrlUri);
    if (signedUrlRes.statusCode < 200 || signedUrlRes.statusCode >= 300) {
      throw Exception('Could not get signed URL (${signedUrlRes.statusCode})');
    }
    final signedUrl =
        (jsonDecode(signedUrlRes.body) as Map<String, dynamic>)['url']
            as String;
    final fileUrl = signedUrl.split('?').first;

    final uploadRes = await _putWithProgress(
      Uri.parse(signedUrl),
      file,
      contentType,
      onProgress,
    );
    if (uploadRes.statusCode < 200 || uploadRes.statusCode >= 300) {
      throw Exception('S3 upload failed (${uploadRes.statusCode})');
    }

    // Best-effort thumbnail so web + admin show a preview (not just a placeholder).
    final thumbnailUrl = await _uploadThumbnail(
      userId: userId,
      videoPath: filePath,
      baseName: fileName,
    );

    final recordRes = await http.post(
      Uri.parse('$_webAppBaseUrl/api/files/job-content'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _accessToken,
      },
      body: jsonEncode({
        'videoUrl': fileUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (quoteId != null) 'quoteId': quoteId,
        if (extJobId != null) 'extJobId': extJobId,
      }),
    );
    if (recordRes.statusCode < 200 || recordRes.statusCode >= 300) {
      throw Exception(
        'Could not save content (${recordRes.statusCode}): ${recordRes.body}',
      );
    }
  }

  /// Generates a JPEG thumbnail from the video and uploads it to S3, returning
  /// its public URL. Returns null on any failure (the clip is still usable).
  Future<String?> _uploadThumbnail({
    required String userId,
    required String videoPath,
    required String baseName,
  }) async {
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 75,
      );
      if (bytes == null) return null;

      final thumbName = 'thumbnail_$baseName.jpg';
      const thumbContentType = 'image/jpeg';
      final signedUrlUri = Uri.parse(
        '$_webAppBaseUrl/api/files/signed-url'
        '?fileName=${Uri.encodeComponent(thumbName)}'
        '&contentType=${Uri.encodeComponent(thumbContentType)}'
        '&type=thumbnail'
        '&userId=${Uri.encodeComponent(userId)}',
      );
      final signedUrlRes = await http.get(signedUrlUri);
      if (signedUrlRes.statusCode < 200 || signedUrlRes.statusCode >= 300)
        return null;
      final signedUrl =
          (jsonDecode(signedUrlRes.body) as Map<String, dynamic>)['url']
              as String;

      final uploadRes = await http.put(
        Uri.parse(signedUrl),
        headers: {'Content-Type': thumbContentType},
        body: bytes,
      );
      if (uploadRes.statusCode < 200 || uploadRes.statusCode >= 300)
        return null;

      return signedUrl.split('?').first;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteJobContent(int fileId) async {
    final res = await http.delete(
      Uri.parse('$_webAppBaseUrl/api/files'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _accessToken,
      },
      body: jsonEncode({'id': fileId}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Delete failed (${res.statusCode}): ${res.body}');
    }
  }
}
