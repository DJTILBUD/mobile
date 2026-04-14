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
        'Bas lige ned makker! Du kan kun forsøge at logge ind hvert 60. sekund.',
      );
    }
    return const AuthException('Forkert email eller adgangskode. Prøv igen.');
  }
}
