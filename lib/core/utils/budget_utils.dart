import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';

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
      adjusted -= 3900;
    } else if (requestedMusicianHours == 1) {
      adjusted -= 4200;
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

String _fmtKr(int n) =>
    NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

/// The DJ-facing budget label for a job (tier-adjusted, invariant-safe).
/// Single source of truth shared by `JobCard` and the home calendar so the
/// DJ never sees a figure that differs between surfaces.
/// Returns null when no budget can be shown.
String? djAdjustedBudgetLabel(Job job, String? djTier) {
  final noBudget = job.budgetStart == null && job.budgetEnd == null;

  // B-tier fallback: show fixed range when no budget is provided.
  if (djTier == 'B' && noBudget && !job.isExtJob) {
    return '${_fmtKr(3500)} – ${_fmtKr(6500)} kr.';
  }

  final adjEnd = adjustBudgetForDjView(
    budget: job.budgetEnd ?? job.budgetStart,
    requestedSaxophonist: job.requestedSaxophonist,
    requestedMusicianHours: job.requestedMusicianHours,
    djTier: djTier,
    maxBudget: job.budgetEnd,
    jobCreatedAt: job.createdAt,
  );
  if (adjEnd == null) return null;

  if (job.budgetStart != null && job.budgetStart != job.budgetEnd) {
    final adjStart = adjustBudgetForDjView(
      budget: job.budgetStart,
      requestedSaxophonist: job.requestedSaxophonist,
      requestedMusicianHours: job.requestedMusicianHours,
      djTier: djTier,
      maxBudget: job.budgetEnd,
      jobCreatedAt: job.createdAt,
    );
    if (adjStart != null) {
      final adjEndClamped = adjEnd > adjStart ? adjEnd : adjStart;
      return '${_fmtKr(adjStart.toInt())} – ${_fmtKr(adjEndClamped.toInt())} kr.';
    }
  }
  return '${_fmtKr(adjEnd.toInt())} kr.';
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
