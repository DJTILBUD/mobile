import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';

/// Whether a DJ may NOT bid on [job] because of an existing booking on the same
/// date. Mirrors the web app's `collidingQuote` helper exactly — keep them in
/// sync. The authoritative enforcement lives server-side in
/// `web-app/src/app/api/jobs/[job_id]/quotes`; this is the client-side mirror
/// used to disable the form and warn the DJ before they submit.
bool isDateColliding(Job job, List<DjQuote> quotes, List<ExtJob> extJobs) {
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // A confirmed/booked external job on the same date always blocks.
  if (extJobs.any((e) => sameDay(e.date, job.date))) return true;

  final activeOnDate = quotes.where((q) =>
      sameDay(q.job.date, job.date) &&
      q.jobId != job.id &&
      q.status != QuoteStatus.lost &&
      q.status != QuoteStatus.overwritten);

  // Already won a job on this date → no more bidding (max 1 won per date).
  if (activeOnDate.any((q) => q.status == QuoteStatus.won)) return true;

  // Otherwise allow up to 2 pending bids per date, not 3.
  final pending = activeOnDate.where((q) => q.status == QuoteStatus.pending);
  return pending.length >= 2;
}

/// Danish explanation for why [job]'s date is blocked, or null if it isn't.
/// Mirrors the three cases in the web `JobCollissionNotificationBanner`.
String? dateCollisionMessage(Job job, List<DjQuote> quotes, List<ExtJob> extJobs) {
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  if (extJobs.any((e) => sameDay(e.date, job.date))) {
    return 'Du kan ikke sende et bud på denne dato, da du allerede har et udvalgt job på samme dato.';
  }

  final activeOnDate = quotes.where((q) =>
      sameDay(q.job.date, job.date) &&
      q.jobId != job.id &&
      q.status != QuoteStatus.lost &&
      q.status != QuoteStatus.overwritten);

  if (activeOnDate.any((q) => q.status == QuoteStatus.won)) {
    return 'Du kan ikke sende et bud på denne dato, da du allerede har vundet et job på samme dato. Du kan kun have 1 vundet job per dato.';
  }

  final pending = activeOnDate.where((q) => q.status == QuoteStatus.pending);
  if (pending.length >= 2) {
    return 'Du kan ikke sende et bud på denne dato, da du allerede har afgivet bud på 2 andre jobs på samme dato. Du kan maksimalt byde på 2 jobs per dato.';
  }

  return null;
}
