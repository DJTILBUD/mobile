import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';

/// Outcome of a sign-up attempt.
enum SignUpResult {
  /// Account created and a session is active (email confirmation disabled).
  /// The user has no role yet, so they must complete profile setup next.
  signedInNeedsSetup,

  /// Account created but no session yet — email confirmation is required.
  /// The user must click the link in their inbox before they can sign in.
  needsEmailConfirmation,
}

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

  /// Debug-only (super-owner impersonation): establishes a session from an
  /// admin-issued magic-link token hash and returns the detected [MusicianRole].
  /// Throws [AppException] subtypes on failure.
  Future<MusicianRole> signInWithMagicTokenHash(String tokenHash);

  /// Creates a new account with email and password.
  /// Returns whether the user is signed in (needs profile setup) or must first
  /// confirm their email. Throws [AppException] subtypes on failure
  /// (e.g. the email is already in use).
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  });

  /// Signs the current user out.
  Future<void> signOut();

  /// Sends a password reset email.
  Future<void> resetPassword({required String email});
}
