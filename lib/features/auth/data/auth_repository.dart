import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';

class AuthRepository {
  GoTrueClient get _auth => supabase.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Session? get currentSession => _auth.currentSession;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword({required String email}) {
    return _auth.resetPasswordForEmail(email);
  }
}
