import 'package:dj_tilbud_app/features/first_win/data/datasources/first_win_remote_datasource.dart';
import 'package:dj_tilbud_app/features/first_win/domain/repositories/first_win_repository.dart';

class FirstWinRepositoryImpl implements FirstWinRepository {
  FirstWinRepositoryImpl(this._datasource);

  final FirstWinRemoteDatasource _datasource;

  @override
  Future<bool> isEligible({required String userId, required bool isDj}) async {
    final shownAt = await _datasource.fetchShownAt(userId: userId, isDj: isDj);
    if (shownAt != null) return false;
    return _datasource.hasWon(userId: userId, isDj: isDj);
  }

  @override
  Future<void> markShown({required bool isDj}) {
    return _datasource.markShown(isDj: isDj);
  }
}
