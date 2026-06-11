import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';

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

  /// Debug-only (super-owner impersonation): establishes a session from an
  /// admin-issued magic-link token hash. The caller MUST set
  /// [NotificationsService.setImpersonating] to `true` before calling this, so
  /// the resulting `signedIn` event does not register a device token.
  Future<AuthResponse> verifyMagicTokenHash(String tokenHash) {
    return _auth.verifyOTP(type: OtpType.magiclink, tokenHash: tokenHash);
  }

  Future<void> signOut() async {
    await NotificationsService.removeToken();
    await _auth.signOut();
    // Leave impersonation mode so a subsequent real login registers normally.
    await NotificationsService.setImpersonating(false);
  }

  Future<void> resetPasswordForEmail(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  /// Checks whether a row exists in [table] for the given [userId].
  Future<bool> hasProfileInTable(String table, String userId) async {
    try {
      final result =
          await _client.from(table).select('id').eq('id', userId).maybeSingle();
      debugPrint('hasProfileInTable($table, $userId) → ${result != null}');
      return result != null;
    } catch (e) {
      debugPrint('hasProfileInTable($table, $userId) ERROR: $e');
      return false;
    }
  }
}
