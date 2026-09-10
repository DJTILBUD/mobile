import 'package:dj_tilbud_app/features/first_win/domain/entities/first_win_decision.dart';

abstract class FirstWinRepository {
  /// Whether the first-win walkthrough should run, and which variant.
  Future<FirstWinDecision> decide({required String userId, required bool isDj});

  /// [variant] must be the one [decide] returned — the DB RPC rejects a
  /// musician call without it.
  Future<void> markShown({required bool isDj, MusicianVariant? variant});
}
