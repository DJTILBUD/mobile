import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/first_win/data/datasources/first_win_remote_datasource.dart';
import 'package:dj_tilbud_app/features/first_win/data/repositories/first_win_repository_impl.dart';
import 'package:dj_tilbud_app/features/first_win/domain/repositories/first_win_repository.dart';

final firstWinRepositoryProvider = Provider<FirstWinRepository>((ref) {
  return FirstWinRepositoryImpl(FirstWinRemoteDatasource(supabase));
});

/// True iff the current user has at least one won quote/offer and has not yet
/// seen the first-win tutorial popup. Recomputed when invalidated.
final firstWinEligibleProvider =
    FutureProvider.family<bool, MusicianRole>((ref, role) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return false;
  final repo = ref.watch(firstWinRepositoryProvider);
  return repo.isEligible(
    userId: userId,
    isDj: role == MusicianRole.dj,
  );
});

Future<void> markFirstWinShown(WidgetRef ref, MusicianRole role) async {
  final repo = ref.read(firstWinRepositoryProvider);
  await repo.markShown(isDj: role == MusicianRole.dj);
  ref.invalidate(firstWinEligibleProvider(role));
}
