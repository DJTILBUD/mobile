import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';

/// Abstract auth repository — domain layer knows nothing about Supabase.
abstract class AuthRepository {
  /// Whether the user currently has an active session.
  bool get isAuthenticated;

  /// Stream of authentication state changes (true = signed in).
  Stream<bool> get authStateChanges;

  /// Signs in with email and password.
  /// Returns the detected [MusicianRole] on success.
  /// Throws [AppException] subtypes on failure.
  Future<MusicianRole> signIn({
    required String email,
    required String password,
  });

  /// Signs the current user out.
  Future<void> signOut();

  /// Sends a password reset email.
  Future<void> resetPassword({required String email});
}
