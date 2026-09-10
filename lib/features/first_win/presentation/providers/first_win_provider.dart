import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/first_win/data/datasources/first_win_remote_datasource.dart';
import 'package:dj_tilbud_app/features/first_win/data/repositories/first_win_repository_impl.dart';
import 'package:dj_tilbud_app/features/first_win/domain/entities/first_win_decision.dart';
import 'package:dj_tilbud_app/features/first_win/domain/repositories/first_win_repository.dart';

final firstWinRepositoryProvider = Provider<FirstWinRepository>((ref) {
  return FirstWinRepositoryImpl(FirstWinRemoteDatasource(supabase));
});

/// Whether the first-win tutorial should run for this role, and (for musicians)
/// which variant. Recomputed when invalidated.
final firstWinDecisionProvider =
    FutureProvider.family<FirstWinDecision, MusicianRole>((ref, role) async {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return const FirstWinDecision.hidden();
      final repo = ref.watch(firstWinRepositoryProvider);
      return repo.decide(userId: userId, isDj: role == MusicianRole.dj);
    });

/// Marks the walkthrough as seen. [variant] MUST be the one the decision
/// carried — a musician call without it is rejected by the DB RPC, which is why
/// the popup used to reappear on every launch.
Future<void> markFirstWinShown(
  WidgetRef ref,
  MusicianRole role, {
  MusicianVariant? variant,
}) async {
  final repo = ref.read(firstWinRepositoryProvider);
  await repo.markShown(isDj: role == MusicianRole.dj, variant: variant);
  ref.invalidate(firstWinDecisionProvider(role));
}
