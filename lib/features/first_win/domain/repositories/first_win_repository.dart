abstract class FirstWinRepository {
  Future<bool> isEligible({required String userId, required bool isDj});
  Future<void> markShown({required bool isDj});
}
