import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dj_tilbud_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dj_tilbud_app/features/auth/data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final datasource = AuthRemoteDatasource(supabaseClient);
  return AuthRepositoryImpl(datasource);
});

final authStateProvider = StreamProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
