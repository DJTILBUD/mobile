import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/utils/musician_price.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';

// Fee brackets by job creation date: 20% before 2025-10-15, 25% until
// 2026-07-06, 28.5% on/after.
final _feeChangeDate = DateTime.utc(2025, 10, 15);
final _secondFeeChangeDate = DateTime.utc(2026, 7, 6);

/// Returns the platform fee fraction (0.20, 0.25 or 0.285) for a job based on its
/// creation date. Mirrors `getFeeForJob` from the web app.
double getFeeForJob(DateTime jobCreatedAt) {
  if (jobCreatedAt.isBefore(_feeChangeDate)) return 0.20;
  if (jobCreatedAt.isBefore(_secondFeeChangeDate)) return 0.25;
  return 0.285;
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
    // Sax cost deducted from the DJ-facing budget. Flat values, NOT keyed on
    // created_at: the web-app's adjustBudgetForDjView applies these to every job
    // regardless of age (its "fee increase" commit bumped 3900/4200/5000 to
    // 4090/4350/5190 outright and added no date branch). A date branch here made
    // mobile show a higher budget than the web for jobs created before
    // 2026-07-06. Keep these three numbers byte-identical to the web helper.
    if (requestedMusicianHours == 0.5) {
      adjusted -= 4090;
    } else if (requestedMusicianHours == 1) {
      adjusted -= 4350;
    } else if (requestedMusicianHours >= 1.5) {
      adjusted -= 5190;
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

/// The DJ-facing budget label, built from raw job fields.
///
/// THE single implementation of the DJ budget label. One job must render the
/// exact same figure on every surface (list card, jobs calendar, calendar tab,
/// job detail, quote detail), so every DJ-facing budget string must come from
/// here — never from a raw `budget_start`/`budget_end` format. Use
/// [djAdjustedBudgetLabel] when you hold a [Job]; use this directly in the data
/// layer where only raw columns are available.
///
/// Returns null when no budget can be shown.
String? djBudgetLabelFromParts({
  required double? budgetStart,
  required double? budgetEnd,
  required String? djTier,
  bool requestedSaxophonist = false,
  double? requestedMusicianHours,
  DateTime? jobCreatedAt,
  bool isExtJob = false,
}) {
  final noBudget = budgetStart == null && budgetEnd == null;

  // B-tier fallback: show fixed range when no budget is provided.
  if (djTier == 'B' && noBudget && !isExtJob) {
    return '${_fmtKr(3500)} – ${_fmtKr(6500)} kr.';
  }

  final adjEnd = adjustBudgetForDjView(
    budget: budgetEnd ?? budgetStart,
    requestedSaxophonist: requestedSaxophonist,
    requestedMusicianHours: requestedMusicianHours,
    djTier: djTier,
    maxBudget: budgetEnd,
    jobCreatedAt: jobCreatedAt,
  );
  if (adjEnd == null) return null;

  if (budgetStart != null && budgetStart != budgetEnd) {
    final adjStart = adjustBudgetForDjView(
      budget: budgetStart,
      requestedSaxophonist: requestedSaxophonist,
      requestedMusicianHours: requestedMusicianHours,
      djTier: djTier,
      maxBudget: budgetEnd,
      jobCreatedAt: jobCreatedAt,
    );
    if (adjStart != null) {
      final adjEndClamped = adjEnd > adjStart ? adjEnd : adjStart;
      return '${_fmtKr(adjStart.toInt())} – ${_fmtKr(adjEndClamped.toInt())} kr.';
    }
  }
  return '${_fmtKr(adjEnd.toInt())} kr.';
}

/// The DJ-facing budget label for a job (tier-adjusted, invariant-safe).
/// Thin wrapper over [djBudgetLabelFromParts] so a [Job] and a raw DB row can
/// never produce different figures for the same job.
String? djAdjustedBudgetLabel(Job job, String? djTier) =>
    djBudgetLabelFromParts(
      budgetStart: job.budgetStart,
      budgetEnd: job.budgetEnd,
      djTier: djTier,
      requestedSaxophonist: job.requestedSaxophonist,
      requestedMusicianHours: job.requestedMusicianHours,
      jobCreatedAt: job.createdAt,
      isExtJob: job.isExtJob,
    );

/// The musician-facing figure for a job they have NOT bid on yet: the estimated
/// price they would be paid. Never the customer's budget. Shared by the jobs
/// list, the jobs calendar and the calendar tab.
String musicianBudgetLabel(Job job) {
  final price = calculateMusicianOfferPrice(
    job.requestedMusicianHours,
    job.createdAt,
  );
  return '${_fmtKr(price)} kr.';
}

/// The musician-facing figure for a submitted or won `ServiceOffer`: their own
/// payout, i.e. the "Din udbetaling" line on the offer card.
///
/// A ServiceOffer has nothing to do with the customer's budget — it carries a
/// price to the customer (`price_dkk`) and a payout to the musician
/// (`musician_payout_dkk`). The job's `budget_start`/`budget_end` are unrelated
/// and must never be shown against an offer.
String musicianOfferPayoutLabel({
  required int priceDkk,
  int? musicianPayoutDkk,
}) => '${_fmtKr(musicianPayoutDkk ?? priceDkk)} kr.';

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
