import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';

class ProfileRemoteDatasource {
  ProfileRemoteDatasource(this._client);

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

  // ── DJ Profile ──

  Future<Map<String, dynamic>> fetchDjProfile(String userId) async {
    return _client.from('DjInfos').select().eq('id', userId).single();
  }

  Future<void> createDjProfile(Map<String, dynamic> data) async {
    await _client.from('DjInfos').insert(data);
  }

  Future<void> updateDjProfile(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    final payload = Map<String, dynamic>.from(data)..remove('id');
    final result =
        await _client.from('DjInfos').update(payload).eq('id', id).select();
    if (result.isEmpty)
      throw Exception('DjInfos update matched 0 rows (id=$id)');
  }

  // ── Musician Profile ──

  Future<Map<String, dynamic>> fetchMusicianProfile(String userId) async {
    return _client.from('Musicians').select().eq('id', userId).single();
  }

  Future<void> createMusicianProfile(Map<String, dynamic> data) async {
    await _client.from('Musicians').insert(data);
  }

  Future<void> updateMusicianProfile(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    final payload = Map<String, dynamic>.from(data)..remove('id');
    final result =
        await _client.from('Musicians').update(payload).eq('id', id).select();
    if (result.isEmpty)
      throw Exception('Musicians update matched 0 rows (id=$id)');
  }

  // ── Payment Info ──
  // Routed through the web-app Next.js API routes so AES-256-GCM
  // encryption/decryption of sensitive fields stays server-side
  // (same endpoints the web app uses).

  String _paymentInfoPath(bool isDj) =>
      isDj ? '/api/private-dj-info' : '/api/private-musician-info';

  Future<Map<String, dynamic>?> fetchPaymentInfo({
    required String userId,
    required bool isDj,
  }) async {
    final uri = Uri.parse('$_webAppBaseUrl${_paymentInfoPath(isDj)}');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'fetchPaymentInfo failed (${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>?;
  }

  Future<void> upsertPaymentInfo({
    required String userId,
    required bool isDj,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('$_webAppBaseUrl${_paymentInfoPath(isDj)}');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'upsertPaymentInfo failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  // ── DJ Job Filters ──

  Future<Map<String, dynamic>?> fetchDjJobFilters(String userId) async {
    final rows = await _client
        .from('DjJobFilters')
        .select()
        .eq('dj_id', userId);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> saveDjJobFilters(Map<String, dynamic> data) async {
    await _client.from('DjJobFilters').upsert(data, onConflict: 'dj_id');
  }

  // ── Musician Job Filters ──

  Future<Map<String, dynamic>?> fetchMusicianJobFilters(String userId) async {
    final rows = await _client
        .from('MusicianJobFilters')
        .select()
        .eq('musician_id', userId);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> saveMusicianJobFilters(Map<String, dynamic> data) async {
    await _client
        .from('MusicianJobFilters')
        .upsert(data, onConflict: 'musician_id');
  }

  // ── Reviews ──

  Future<List<Map<String, dynamic>>> fetchReviews({
    required String userId,
    required bool isDj,
  }) async {
    final column = isDj ? 'dj_id' : 'musician_id';
    return _client
        .from('Reviews')
        .select()
        .eq(column, userId)
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> createReview({
    required String userId,
    required bool isDj,
    required Map<String, dynamic> data,
  }) async {
    final column = isDj ? 'dj_id' : 'musician_id';
    return _client
        .from('Reviews')
        .insert({column: userId, ...data})
        .select()
        .single();
  }

  Future<void> updateReview({
    required String reviewId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('Reviews').update(data).eq('id', reviewId);
  }

  Future<void> deleteReview(String reviewId) async {
    await _client.from('Reviews').delete().eq('id', reviewId);
  }

  // ── User Files ──

  Future<List<Map<String, dynamic>>> fetchUserFiles(String userId) async {
    return _client
        .from('UserFiles')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);
  }

  Future<Map<String, dynamic>> uploadFile({
    required String userId,
    required String filePath,
    required UserFileType type,
    String? description,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    final fileName = filePath.split('/').last;
    final contentType = _mimeType(filePath);

    // 1. Get a pre-signed S3 upload URL from the web app API
    final signedUrlUri = Uri.parse(
      '$_webAppBaseUrl/api/files/signed-url'
      '?fileName=${Uri.encodeComponent(fileName)}'
      '&contentType=${Uri.encodeComponent(contentType)}'
      '&type=${Uri.encodeComponent(type.toDbString())}'
      '&userId=${Uri.encodeComponent(userId)}',
    );
    final signedUrlRes = await http.get(signedUrlUri);
    if (signedUrlRes.statusCode < 200 || signedUrlRes.statusCode >= 300) {
      throw Exception('Could not get signed URL (${signedUrlRes.statusCode})');
    }
    final signedUrl =
        (jsonDecode(signedUrlRes.body) as Map<String, dynamic>)['url']
            as String;
    // The public URL is the signed URL without query params
    final fileUrl = signedUrl.split('?').first;

    // 2. Upload directly to S3, streaming from disk so we can report real
    // upload progress (matters for large videos on slow connections).
    final uploadRes = await _putWithProgress(
      Uri.parse(signedUrl),
      file,
      contentType,
      onProgress,
    );
    if (uploadRes.statusCode < 200 || uploadRes.statusCode >= 300) {
      throw Exception('S3 upload failed (${uploadRes.statusCode})');
    }

    // 3. Store metadata in UserFiles table
    final row =
        await _client
            .from('UserFiles')
            .insert({
              'user_id': userId,
              'url': fileUrl,
              'type': type.toDbString(),
              if (description != null && description.trim().isNotEmpty)
                'description': description.trim(),
            })
            .select()
            .single();

    // 4. Videos get a poster: a separate `type='thumbnail'` row linked to the video
    //    via `thumbnail_video_id`, so web + admin + mobile show a preview instead of a
    //    grey placeholder. Best-effort (the video is still usable if this fails).
    //    Mirrors the job-content uploader + web-app `useFiles.createFile`.
    if (type == UserFileType.profileVideo || type == UserFileType.commonVideo) {
      final thumbnailUrl = await _uploadThumbnail(
        userId: userId,
        videoPath: filePath,
        baseName: fileName,
      );
      if (thumbnailUrl != null) {
        await _client.from('UserFiles').insert({
          'user_id': userId,
          'url': thumbnailUrl,
          'type': 'thumbnail',
          'thumbnail_video_id': row['id'],
        });
      }
    }

    return row;
  }

  /// Generates a JPEG poster from [videoPath] and uploads it to S3, returning its
  /// public URL (or null on any failure — the video is still usable). Mirrors
  /// `job_content_remote_datasource._uploadThumbnail`.
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
      if (signedUrlRes.statusCode < 200 || signedUrlRes.statusCode >= 300) {
        return null;
      }
      final signedUrl =
          (jsonDecode(signedUrlRes.body) as Map<String, dynamic>)['url']
              as String;

      final uploadRes = await http.put(
        Uri.parse(signedUrl),
        headers: {'Content-Type': thumbContentType},
        body: bytes,
      );
      if (uploadRes.statusCode < 200 || uploadRes.statusCode >= 300) {
        return null;
      }
      return signedUrl.split('?').first;
    } catch (_) {
      return null;
    }
  }

  /// PUTs [file] to [url] streaming straight from disk, reporting upload
  /// progress as a 0..1 fraction via [onProgress]. Streaming (instead of
  /// `readAsBytes`) surfaces real progress and avoids loading large videos
  /// fully into memory. Mirrors the job-content uploader.
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

    final response = request.send();
    unawaited(request.sink.addStream(body).then((_) => request.sink.close()));
    return response;
  }

  Future<void> deleteFile(int fileId) async {
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

  // ── Standard Messages ──

  Future<List<Map<String, dynamic>>> fetchStandardMessages(
    String userId,
  ) async {
    return _client
        .from('StandardMessages')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> createStandardMessage({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    return _client
        .from('StandardMessages')
        .insert({'user_id': userId, ...data})
        .select()
        .single();
  }

  Future<void> updateStandardMessage({
    required int messageId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('StandardMessages').update(data).eq('id', messageId);
  }

  Future<void> deleteStandardMessage(int messageId) async {
    await _client.from('StandardMessages').delete().eq('id', messageId);
  }

  Future<List<Map<String, dynamic>>> fetchAdminMessages({
    required String userId,
    required bool isDj,
  }) async {
    final audiences = isDj ? ['dj', 'both'] : ['musician', 'both'];
    final readJoin =
        isDj
            ? 'AdminMessageReads!left(readAt, djId)'
            : 'AdminMessageReads!left(readAt, musicianId)';
    final userCreatedAt = _client.auth.currentUser?.createdAt;
    var query = _client
        .from('AdminMessages')
        .select('*, $readJoin')
        .inFilter('target_audience', audiences);
    if (userCreatedAt != null) {
      query = query.gte('createdAt', userCreatedAt);
    }
    return query.order('createdAt', ascending: false);
  }

  Future<void> markAdminMessageRead({
    required int messageId,
    required String userId,
    required bool isDj,
  }) async {
    final payload =
        isDj
            ? {'messageId': messageId, 'djId': userId}
            : {'messageId': messageId, 'musicianId': userId};
    await _client.from('AdminMessageReads').insert(payload);
  }

  // ── Onboarding ──

  Future<void> setOnboardingCompleted({
    required String userId,
    required bool isDj,
  }) async {
    final table = isDj ? 'DjInfos' : 'Musicians';
    await _client
        .from(table)
        .update({'onboarding_completed_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  // ── iCal Token ──

  Future<String?> fetchIcalToken({
    required String userId,
    required bool isDj,
  }) async {
    final table = isDj ? 'DjInfos' : 'Musicians';
    final row =
        await _client
            .from(table)
            .select('ical_token')
            .eq('id', userId)
            .maybeSingle();
    return row?['ical_token'] as String?;
  }

  Future<String> generateIcalToken({
    required String userId,
    required bool isDj,
  }) async {
    final token = _generateUuid();
    final table = isDj ? 'DjInfos' : 'Musicians';
    await _client.from(table).update({'ical_token': token}).eq('id', userId);
    return token;
  }

  static String _generateUuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static String _mimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'avi' => 'video/x-msvideo',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'wav' => 'audio/wav',
      'ogg' => 'audio/ogg',
      _ => 'application/octet-stream',
    };
  }
}
