import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._client);

  final SupabaseClient _client;
  GoTrueClient get _auth => _client.auth;

  bool get isAuthenticated => _auth.currentSession != null;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPasswordForEmail(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  /// Checks whether a row exists in [table] for the given [userId].
  Future<bool> hasProfileInTable(String table, String userId) async {
    try {
      final result = await _client
          .from(table)
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      debugPrint('hasProfileInTable($table, $userId) → ${result != null}');
      return result != null;
    } catch (e) {
      debugPrint('hasProfileInTable($table, $userId) ERROR: $e');
      return false;
    }
  }
}
