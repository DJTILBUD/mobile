import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarRemoteDatasource {
  CalendarRemoteDatasource(this._client);

  final SupabaseClient _client;

  /// Fetches won Quotes (with joined Job data) for a DJ.
  Future<List<Map<String, dynamic>>> fetchDjWonQuotes(String userId) async {
    return _client
        .from('Quotes')
        .select(
            'id, job:Jobs(id, event_type, date, time_start, time_end, city, region, guests_amount)')
        .eq('dj_id', userId)
        .eq('status', 'won');
  }

  /// Fetches ExtJobs directly assigned to a DJ (confirmed bookings).
  Future<List<Map<String, dynamic>>> fetchDjAssignedExtJobs(
      String userId) async {
    return _client
        .from('ExtJobs')
        .select('id, event_type, date, start_time, end_time, location, region, guests_amount')
        .eq('assigned_dj_id', userId)
        .inFilter('status', ['closed', 'customer_contacted', 'ready_for_billing']);
  }

  /// Fetches won ServiceOffers linked to internal Jobs for a musician.
  Future<List<Map<String, dynamic>>> fetchMusicianWonJobOffers(
      String userId) async {
    return _client
        .from('ServiceOffers')
        .select(
            'id, job:Jobs!ServiceOffers_job_id_fkey(id, event_type, date, time_start, time_end, city, region, guests_amount)')
        .eq('musician_id', userId)
        .eq('status', 'won')
        .not('job_id', 'is', null);
  }

  /// Fetches won ServiceOffers linked to ExtJobs for a musician.
  Future<List<Map<String, dynamic>>> fetchMusicianWonExtJobOffers(
      String userId) async {
    return _client
        .from('ServiceOffers')
        .select(
            'id, ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(id, event_type, date, start_time, end_time, location, region, guests_amount)')
        .eq('musician_id', userId)
        .eq('status', 'won')
        .not('ext_job_id', 'is', null);
  }

  // ── Unavailable dates (DJ) ──

  Future<List<Map<String, dynamic>>> fetchDjUnavailableDates(String userId) async {
    return _client
        .from('UnavailableDates')
        .select('id, unavailable_date')
        .eq('profile_type', 'dj')
        .eq('dj_id', userId);
  }

  Future<Map<String, dynamic>> createDjUnavailableDate(String userId, String dateStr) async {
    return _client
        .from('UnavailableDates')
        .insert({'profile_type': 'dj', 'dj_id': userId, 'unavailable_date': dateStr, 'source': 'manual'})
        .select('id')
        .single();
  }

  Future<void> deleteDjUnavailableDate(int id) async {
    await _client.from('UnavailableDates').delete().eq('id', id);
  }

  // ── Unavailable dates (Musician) ──

  Future<List<Map<String, dynamic>>> fetchMusicianUnavailableDates(String userId) async {
    return _client
        .from('UnavailableDates')
        .select('id, unavailable_date')
        .eq('profile_type', 'musician')
        .eq('musician_id', userId);
  }

  Future<Map<String, dynamic>> createMusicianUnavailableDate(String userId, String dateStr) async {
    return _client
        .from('UnavailableDates')
        .insert({'profile_type': 'musician', 'musician_id': userId, 'unavailable_date': dateStr, 'source': 'manual'})
        .select('id')
        .single();
  }

  Future<void> deleteMusicianUnavailableDate(int id) async {
    await _client.from('UnavailableDates').delete().eq('id', id);
  }
}
