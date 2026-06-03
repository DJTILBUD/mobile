/// Platform fee fraction for a job, mirroring the web app's `getFeeForJob`
/// (`web-app/src/helpers/getFeeForJob.ts`): 20% for jobs created before
/// 2025-10-15 (UTC), 25% on/after. The DJ's payout share is `1 - djFeeForJob(...)`.
///
/// The web app keys this off the JOB's `created_at` (not the quote's), so callers
/// must pass `quote.job.createdAt` / `extJob.createdAt`.
double djFeeForJob(DateTime jobCreatedAt) {
  final feeChange = DateTime.utc(2025, 10, 15);
  return jobCreatedAt.toUtc().isBefore(feeChange) ? 0.20 : 0.25;
}

/// The DJ's share of the customer price for a job (`1 - fee`): 0.80 before
/// 2025-10-15, 0.75 on/after.
double djPayoutShareForJob(DateTime jobCreatedAt) => 1 - djFeeForJob(jobCreatedAt);
