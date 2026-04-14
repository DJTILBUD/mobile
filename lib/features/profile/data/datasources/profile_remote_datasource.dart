import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';

class ProfileRemoteDatasource {
  ProfileRemoteDatasource(this._client);

  final SupabaseClient _client;

  // ── DJ Profile ──

  Future<Map<String, dynamic>> fetchDjProfile(String userId) async {
    return _client.from('DjInfos').select().eq('id', userId).single();
  }

  Future<void> createDjProfile(Map<String, dynamic> data) async {
    await _client.from('DjInfos').insert(data);
  }

  Future<void> updateDjProfile(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await _client.from('DjInfos').update(data).eq('id', id);
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
    await _client.from('Musicians').update(data).eq('id', id);
  }

  // ── Payment Info ──

  Future<Map<String, dynamic>?> fetchPaymentInfo({
    required String userId,
    required bool isDj,
  }) async {
    final table = isDj ? 'PrivateDjInfos' : 'PrivateMusiciansInfo';
    final results = await _client.from(table).select().eq('id', userId);
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> upsertPaymentInfo({
    required String userId,
    required bool isDj,
    required Map<String, dynamic> data,
  }) async {
    final table = isDj ? 'PrivateDjInfos' : 'PrivateMusiciansInfo';
    await _client.from(table).upsert({'id': userId, ...data});
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
  }) async {
    final file = File(filePath);
    final ext = filePath.split('.').last;
    final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('user-files').upload(storagePath, file);
    final url = _client.storage.from('user-files').getPublicUrl(storagePath);

    return _client
        .from('UserFiles')
        .insert({
          'user_id': userId,
          'url': url,
          'type': type.toDbString(),
        })
        .select()
        .single();
  }

  Future<void> deleteFile(int fileId) async {
    await _client.from('UserFiles').delete().eq('id', fileId);
  }

  // ── Standard Messages ──

  Future<List<Map<String, dynamic>>> fetchStandardMessages(
      String userId) async {
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
    final readJoin = isDj
        ? 'AdminMessageReads!left(readAt, djId)'
        : 'AdminMessageReads!left(readAt, musicianId)';
    return _client
        .from('AdminMessages')
        .select('*, $readJoin')
        .inFilter('target_audience', audiences)
        .order('createdAt', ascending: false);
  }

  Future<void> markAdminMessageRead({
    required int messageId,
    required String userId,
    required bool isDj,
  }) async {
    final payload = isDj
        ? {'messageId': messageId, 'djId': userId}
        : {'messageId': messageId, 'musicianId': userId};
    await _client
        .from('AdminMessageReads')
        .upsert(payload, onConflict: isDj ? 'messageId,djId' : 'messageId,musicianId');
  }

  // ── iCal Token ──

  Future<String?> fetchIcalToken({
    required String userId,
    required bool isDj,
  }) async {
    final table = isDj ? 'DjInfos' : 'Musicians';
    final row = await _client
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
    await _client
        .from(table)
        .update({'ical_token': token})
        .eq('id', userId);
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
}
