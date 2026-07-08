import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dj_tilbud_app/features/auth/data/datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  @override
  bool get isAuthenticated => _datasource.isAuthenticated;

  @override
  Stream<bool> get authStateChanges =>
      _datasource.authStateChanges.map((state) => state.session != null);

  @override
  Future<MusicianRole> signIn({
    required String email,
    required String password,
  }) async {
    final sb.AuthResponse response;
    try {
      response = await _datasource.signInWithPassword(
        email: email,
        password: password,
      );
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    }

    final userId = response.user?.id;
    if (userId == null) {
      throw const AuthException('Login fejlede. Prøv igen.');
    }

    final role = await _detectRole(userId);
    if (role == null) {
      // Keep user signed in — they need to complete setup
      throw const NeedsProfileSetupException();
    }

    return role;
  }

  @override
  Future<MusicianRole> signInWithMagicTokenHash(String tokenHash) async {
    final sb.AuthResponse response;
    try {
      response = await _datasource.verifyMagicTokenHash(tokenHash);
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    }

    final userId = response.user?.id;
    if (userId == null) {
      throw const AuthException('Impersonation fejlede. Prøv igen.');
    }

    final role = await _detectRole(userId);
    if (role == null) {
      // Keep the session — same semantics as password sign-in.
      throw const NeedsProfileSetupException();
    }

    return role;
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    final sb.AuthResponse response;
    try {
      response = await _datasource.signUpWithPassword(
        email: email,
        password: password,
      );
    } on sb.AuthException catch (e) {
      throw _mapSignUpException(e);
    }

    // Email confirmation is disabled (project default) → a session comes back and
    // the brand-new user has no role yet, so they continue to profile setup. If
    // confirmations are ever enabled there's no session, and they must verify via
    // the emailed link first (mirrors the web register flow).
    return response.session != null
        ? SignUpResult.signedInNeedsSetup
        : SignUpResult.needsEmailConfirmation;
  }

  @override
  Future<void> signOut() => _datasource.signOut();

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _datasource.resetPasswordForEmail(email);
    } on sb.AuthException catch (_) {
      throw const AuthException('Noget gik galt. Prøv igen senere.');
    }
  }

  Future<MusicianRole?> _detectRole(String userId) async {
    final results = await Future.wait([
      _datasource.hasProfileInTable('DjInfos', userId),
      _datasource.hasProfileInTable('Musicians', userId),
    ]);

    if (results[0]) return MusicianRole.dj;
    if (results[1]) return MusicianRole.instrumentalist;
    return null;
  }

  AppException _mapAuthException(sb.AuthException e) {
    debugPrint('AuthException: code=${e.statusCode} message=${e.message}');
    if (e.statusCode == '429') {
      return const AuthException(
        'Du kan kun forsøge at logge ind én gang i minuttet. Prøv venligst igen om lidt.',
      );
    }
    return const AuthException('Forkert email eller adgangskode. Prøv igen.');
  }

  AppException _mapSignUpException(sb.AuthException e) {
    debugPrint(
      'SignUp AuthException: code=${e.statusCode} message=${e.message}',
    );
    if (e.statusCode == '429') {
      return const AuthException(
        'For mange forsøg. Vent et øjeblik, og prøv igen.',
      );
    }
    final msg = e.message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('already exists')) {
      return const AuthException(
        'Der findes allerede en bruger med denne email. Prøv at logge ind i stedet.',
      );
    }
    if (msg.contains('password')) {
      return const AuthException(
        'Adgangskoden er for svag. Brug mindst 6 tegn.',
      );
    }
    if (msg.contains('valid email') || msg.contains('invalid email')) {
      return const AuthException('Indtast en gyldig email.');
    }
    return const AuthException('Kunne ikke oprette bruger. Prøv igen senere.');
  }
}
