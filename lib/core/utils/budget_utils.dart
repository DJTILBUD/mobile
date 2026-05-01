// Jobs created before this date pay the legacy 20% fee; on/after pay 25%.
final _feeChangeDate = DateTime.utc(2025, 10, 15);

/// Returns the platform fee fraction (0.20 or 0.25) for a job based on its
/// creation date. Mirrors `getFeeForJob` from the web app.
double getFeeForJob(DateTime jobCreatedAt) {
  return jobCreatedAt.isBefore(_feeChangeDate) ? 0.20 : 0.25;
}

const _bTierBudgetDeduction = 500;
const _bTierDeductionWindowMs = 24 * 60 * 60 * 1000;
const _fourHoursMs = 4 * 60 * 60 * 1000;

bool _isBTierDeductionActive(
  double budget,
  String? djTier,
  double? maxBudget,
  DateTime? jobCreatedAt,
) {
  if (djTier != 'B') return false;
  if ((maxBudget ?? budget) <= 5000) return false;
  if (jobCreatedAt == null) return true;

  final ageMs = DateTime.now().difference(jobCreatedAt).inMilliseconds;
  return ageMs < _bTierDeductionWindowMs;
}

/// Mirrors `adjustBudgetForDjView` from the web app.
/// Returns null when [budget] is null or zero.
double? adjustBudgetForDjView({
  required double? budget,
  bool requestedSaxophonist = false,
  double? requestedMusicianHours,
  String? djTier,
  double? maxBudget,
  DateTime? jobCreatedAt,
}) {
  if (budget == null || budget == 0) return null;

  var adjusted = budget;

  if (requestedSaxophonist && requestedMusicianHours != null && budget > 7000) {
    if (requestedMusicianHours == 0.5) {
      adjusted -= 3500;
    } else if (requestedMusicianHours == 1) {
      adjusted -= 4000;
    } else if (requestedMusicianHours >= 1.5) {
      adjusted -= 5000;
    }
  }

  if (adjusted > 7500) adjusted -= 500;
  if (adjusted > 6500) adjusted -= 250;

  if (_isBTierDeductionActive(budget, djTier, maxBudget, jobCreatedAt)) {
    adjusted -= _bTierBudgetDeduction;
  }

  return adjusted;
}

/// Returns true if [jobCreatedAt] is within the first 4 hours.
bool isWithinFirstFourHours(DateTime jobCreatedAt) {
  final ageMs = DateTime.now().difference(jobCreatedAt).inMilliseconds;
  return ageMs >= 0 && ageMs < _fourHoursMs;
}

/// Returns true when a B-tier DJ should see the budget as having just
/// "increased" — i.e. the 24h deduction window has passed.
/// Mirrors `hasBTierBudgetIncreaseAfter24h` from the web app.
bool hasBTierBudgetIncreaseAfter24h({
  required double? budget,
  required String? djTier,
  required double? maxBudget,
  required DateTime? jobCreatedAt,
}) {
  if (budget == null || djTier != 'B') return false;
  if ((maxBudget ?? budget) <= 5000) return false;
  // Deduction is no longer active → budget has "increased"
  return !_isBTierDeductionActive(budget, djTier, maxBudget, jobCreatedAt);
}
