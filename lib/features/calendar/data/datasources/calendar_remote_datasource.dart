import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarRemoteDatasource {
  CalendarRemoteDatasource(this._client);

  final SupabaseClient _client;

  /// Fetches won Quotes (with joined Job data) for a DJ.
  ///
  /// `created_at`, `requested_saxophonist` and `requested_musician_hours` are
  /// selected because the DJ-facing budget label is sax- and tier-adjusted
  /// (`djBudgetLabelFromParts`). Without them the calendar would show the raw
  /// customer budget while the job list shows the adjusted one.
  Future<List<Map<String, dynamic>>> fetchDjWonQuotes(String userId) async {
    return _client
        .from('Quotes')
        .select(
          'id, job:Jobs(id, event_type, date, time_start, time_end, city, region, guests_amount, budget_start, budget_end, created_at, requested_saxophonist, requested_musician_hours)',
        )
        .eq('dj_id', userId)
        .eq('status', 'won');
  }

  /// Fetches ExtJobs directly assigned to a DJ (confirmed bookings).
  Future<List<Map<String, dynamic>>> fetchDjAssignedExtJobs(
    String userId,
  ) async {
    return _client
        .from('ExtJobs')
        .select(
          'id, event_type, date, start_time, end_time, location, region, guests_amount, budget_target',
        )
        .eq('assigned_dj_id', userId)
        .inFilter('status', [
          'closed',
          'customer_contacted',
          'ready_for_billing',
        ]);
  }

  /// Fetches won ServiceOffers linked to internal Jobs for a musician.
  ///
  /// `price_dkk`/`musician_payout_dkk` are the offer's own money: an offer has a
  /// customer price and a musician payout, and nothing to do with the job's
  /// budget. The job's budget columns are deliberately NOT selected.
  Future<List<Map<String, dynamic>>> fetchMusicianWonJobOffers(
    String userId,
  ) async {
    return _client
        .from('ServiceOffers')
        .select(
          'id, price_dkk, musician_payout_dkk, job:Jobs!ServiceOffers_job_id_fkey(id, event_type, date, time_start, time_end, city, region, guests_amount)',
        )
        .eq('musician_id', userId)
        .eq('status', 'won')
        .not('job_id', 'is', null);
  }

  /// Fetches won ServiceOffers linked to ExtJobs for a musician.
  ///
  /// As above: the figure shown is the offer's own payout, so `budget_target` is
  /// deliberately NOT selected.
  Future<List<Map<String, dynamic>>> fetchMusicianWonExtJobOffers(
    String userId,
  ) async {
    return _client
        .from('ServiceOffers')
        .select(
          'id, price_dkk, musician_payout_dkk, ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(id, event_type, date, start_time, end_time, location, region, guests_amount)',
        )
        .eq('musician_id', userId)
        .eq('status', 'won')
        .not('ext_job_id', 'is', null);
  }

  // ── Unavailable dates (DJ) ──

  Future<List<Map<String, dynamic>>> fetchDjUnavailableDates(
    String userId,
  ) async {
    return _client
        .from('UnavailableDates')
        .select('id, unavailable_date')
        .eq('profile_type', 'dj')
        .eq('dj_id', userId);
  }

  Future<Map<String, dynamic>> createDjUnavailableDate(
    String userId,
    String dateStr,
  ) async {
    return _client
        .from('UnavailableDates')
        .insert({
          'profile_type': 'dj',
          'dj_id': userId,
          'unavailable_date': dateStr,
          'source': 'manual',
        })
        .select('id')
        .single();
  }

  Future<void> deleteDjUnavailableDate(int id) async {
    await _client.from('UnavailableDates').delete().eq('id', id);
  }

  // ── Unavailable dates (Musician) ──

  Future<List<Map<String, dynamic>>> fetchMusicianUnavailableDates(
    String userId,
  ) async {
    return _client
        .from('UnavailableDates')
        .select('id, unavailable_date')
        .eq('profile_type', 'musician')
        .eq('musician_id', userId);
  }

  Future<Map<String, dynamic>> createMusicianUnavailableDate(
    String userId,
    String dateStr,
  ) async {
    return _client
        .from('UnavailableDates')
        .insert({
          'profile_type': 'musician',
          'musician_id': userId,
          'unavailable_date': dateStr,
          'source': 'manual',
        })
        .select('id')
        .single();
  }

  Future<void> deleteMusicianUnavailableDate(int id) async {
    await _client.from('UnavailableDates').delete().eq('id', id);
  }
}
