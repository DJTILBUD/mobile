import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfigRemoteDatasource {
  AppConfigRemoteDatasource(this._client);

  final SupabaseClient _client;

  /// Singleton row keyed on `id = 1`.
  Future<Map<String, dynamic>?> fetch() async {
    return _client
        .from('AppConfig')
        .select()
        .eq('id', 1)
        .maybeSingle();
  }
}
