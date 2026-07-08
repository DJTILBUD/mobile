/// Platform fee fraction for a job, mirroring the web app's `getFeeForJob`
/// (`web-app/src/helpers/getFeeForJob.ts`): 20% for jobs created before
/// 2025-10-15 (UTC), 25% until 2026-07-06, 28.5% on/after. The DJ's payout
/// share is `1 - djFeeForJob(...)`.
///
/// The web app keys this off the JOB's `created_at` (not the quote's), so callers
/// must pass `quote.job.createdAt` / `extJob.createdAt`.
double djFeeForJob(DateTime jobCreatedAt) {
  final created = jobCreatedAt.toUtc();
  if (created.isBefore(DateTime.utc(2025, 10, 15))) return 0.20;
  if (created.isBefore(DateTime.utc(2026, 7, 6))) return 0.25;
  return 0.285;
}

/// The DJ's share of the customer price for a job (`1 - fee`): 0.80 before
/// 2025-10-15, 0.75 until 2026-07-06, 0.715 on/after.
double djPayoutShareForJob(DateTime jobCreatedAt) =>
    1 - djFeeForJob(jobCreatedAt);

/// Formats a fee fraction as a Danish percent label (no float noise):
/// 0.20 -> "20", 0.25 -> "25", 0.285 -> "28,5".
String formatFeePercent(double fee) {
  final pct = (fee * 1000).round() / 10;
  return pct == pct.roundToDouble()
      ? pct.toInt().toString()
      : pct.toString().replaceAll('.', ',');
}
