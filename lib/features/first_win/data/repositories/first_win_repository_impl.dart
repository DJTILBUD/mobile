import 'package:dj_tilbud_app/features/first_win/data/datasources/first_win_remote_datasource.dart';
import 'package:dj_tilbud_app/features/first_win/domain/entities/first_win_decision.dart';
import 'package:dj_tilbud_app/features/first_win/domain/repositories/first_win_repository.dart';

class FirstWinRepositoryImpl implements FirstWinRepository {
  FirstWinRepositoryImpl(this._datasource);

  final FirstWinRemoteDatasource _datasource;

  @override
  Future<FirstWinDecision> decide({
    required String userId,
    required bool isDj,
  }) async {
    if (isDj) {
      final shownAt = await _datasource.fetchDjShownAt(userId);
      if (shownAt != null) return const FirstWinDecision.hidden();
      final hasWon = await _datasource.djHasWon(userId);
      return FirstWinDecision(shouldShow: hasWon);
    }

    // For musicians "has won" and "which popup is pending" are one query — a
    // pending variant is only returned when a real win backs it.
    final variant = await _datasource.fetchMusicianVariantToShow(userId);
    if (variant == null) return const FirstWinDecision.hidden();
    return FirstWinDecision(shouldShow: true, musicianVariant: variant);
  }

  @override
  Future<void> markShown({required bool isDj, MusicianVariant? variant}) {
    return _datasource.markShown(isDj: isDj, variant: variant);
  }
}
