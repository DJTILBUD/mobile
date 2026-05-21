import 'package:supabase_flutter/supabase_flutter.dart';

class FirstWinRemoteDatasource {
  FirstWinRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<DateTime?> fetchShownAt({required String userId, required bool isDj}) async {
    final table = isDj ? 'DjInfos' : 'Musicians';
    final row = await _client
        .from(table)
        .select('first_win_shown_at')
        .eq('id', userId)
        .maybeSingle();
    final value = row?['first_win_shown_at'] as String?;
    return value == null ? null : DateTime.parse(value);
  }

  Future<bool> hasWon({required String userId, required bool isDj}) async {
    if (isDj) {
      final rows = await _client
          .from('Quotes')
          .select('id')
          .eq('dj_id', userId)
          .eq('status', 'won')
          .limit(1);
      return rows.isNotEmpty;
    }
    final rows = await _client
        .from('ServiceOffers')
        .select('id')
        .eq('musician_id', userId)
        .eq('status', 'won')
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<void> markShown({required bool isDj}) async {
    await _client.rpc('mark_first_win_shown', params: {
      'p_role': isDj ? 'dj' : 'musician',
    });
  }
}
