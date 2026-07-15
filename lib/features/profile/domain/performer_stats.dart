/// Pure aggregation for the performer stats screen (DJ + saxophonist).
///
/// No Supabase, no widgets — the presentation layer normalises each role's very
/// different sources into [StatEntry] and this file does the maths, so both roles
/// get identical behaviour and it is unit-testable.
///
/// Money rules the caller must honour when building entries (see stats_provider):
///   • DJ internal job  → DjQuote.djPayout (date-aware fee + override).
///   • DJ external job  → ExtJob.honorar   (NEVER full_amount — that is the
///                        customer total and leaks our cut).
///   • Saxophonist      → ServiceOffer.musicianPayoutDkk.
///
/// WHICH bookings qualify is decided by the caller, not here: only jobs at status
/// `ready_for_billing` count (internal AND external). That status is the end of the
/// flow (closed → customer_contacted → ready_for_billing), so it already implies the
/// job happened — this file must NOT also filter on the date, or a job could be
/// silently dropped from someone's earnings.
library;

/// One completed booking, normalised across roles.
class StatEntry {
  const StatEntry({
    required this.date,
    required this.payoutDkk,
    this.eventType,
    this.region,
    this.guestsAmount,
    this.genres,
  });

  /// The event date (what the performer thinks of as "when I played").
  final DateTime date;

  /// What this performer is paid for the booking, in DKK.
  final int payoutDkk;

  final String? eventType;
  final String? region;
  final int? guestsAmount;
  final List<String>? genres;
}

class MonthBucket {
  const MonthBucket({
    required this.year,
    required this.month,
    required this.totalDkk,
    required this.jobs,
    this.upcomingDkk = 0,
    this.upcomingJobs = 0,
  });

  final int year;
  final int month; // 1-12
  final int totalDkk;
  final int jobs;

  /// The part of this month that is still ahead. Counted PER BOOKING, not by
  /// comparing the month to the current month — the current month can contain only
  /// future jobs (e.g. today is the 14th and the single job is on the 21st), and a
  /// month-level rule would wrongly present that as already earned.
  final int upcomingDkk;
  final int upcomingJobs;

  /// Every booking in this month is still ahead.
  bool get isUpcoming => jobs > 0 && upcomingJobs == jobs;

  /// Some, but not all, of this month is still ahead.
  bool get isPartlyUpcoming => upcomingJobs > 0 && upcomingJobs < jobs;
}

class CategoryBucket {
  const CategoryBucket({
    required this.label,
    required this.totalDkk,
    required this.jobs,
    this.upcomingDkk = 0,
    this.upcomingJobs = 0,
  });

  final String label;
  final int totalDkk;
  final int jobs;

  /// The part of this category still ahead. Tracked for the SAME reason as on
  /// MonthBucket: green means "tjent" everywhere on the screen, so a category made
  /// up of unplayed jobs must not render as earned money — otherwise the same job
  /// shows grey in the month list and green here, and the page contradicts itself.
  final int upcomingDkk;
  final int upcomingJobs;

  bool get isUpcoming => jobs > 0 && upcomingJobs == jobs;
  bool get isPartlyUpcoming => upcomingJobs > 0 && upcomingJobs < jobs;
}

class PerformerStats {
  const PerformerStats({
    required this.totalDkk,
    required this.earnedDkk,
    required this.upcomingDkk,
    required this.jobCount,
    required this.earnedJobCount,
    required this.upcomingJobCount,
    required this.avgPerJobDkk,
    required this.byMonth,
    required this.byEventType,
    required this.byRegion,
    required this.topGenres,
    this.busiestMonth,
    this.topWeekday,
    this.topWeekdayShare,
    this.avgGuests,
  });

  /// Everything at ready_for_billing, played or not.
  final int totalDkk;

  /// Only bookings whose event date has passed — the money actually earned.
  final int earnedDkk;

  /// Bookings still ahead: confirmed for billing but not played yet.
  final int upcomingDkk;

  final int jobCount;
  final int earnedJobCount;
  final int upcomingJobCount;
  final int avgPerJobDkk;

  bool get hasUpcoming => upcomingJobCount > 0;

  /// Chronological, oldest first. Only months that actually have a booking.
  final List<MonthBucket> byMonth;

  /// Sorted by job count desc, then earnings desc.
  final List<CategoryBucket> byEventType;
  final List<CategoryBucket> byRegion;

  /// Most-played genres, most frequent first (DJ only in practice).
  final List<String> topGenres;

  final MonthBucket? busiestMonth;

  /// 1 = Monday ... 7 = Sunday (matches DateTime.weekday).
  final int? topWeekday;

  /// Share of bookings falling on [topWeekday], 0..1.
  final double? topWeekdayShare;

  final int? avgGuests;

  bool get isEmpty => jobCount == 0;
}

/// Aggregates [entries] into the numbers the stats screen renders.
///
/// [entries] must already be scoped to qualifying bookings (`ready_for_billing`).
/// Pass [year] to scope to a single calendar year, or null for all time.
///
/// [now] does NOT filter anything — every entry counts. It only splits earned
/// (event date passed) from upcoming, because ready_for_billing jobs can sit months
/// in the future and calling that money "tjent" would be a lie.
PerformerStats computeStats(
  List<StatEntry> entries, {
  required DateTime now,
  int? year,
}) {
  final played =
      entries.where((e) => year == null || e.date.year == year).toList();

  if (played.isEmpty) {
    return const PerformerStats(
      totalDkk: 0,
      earnedDkk: 0,
      upcomingDkk: 0,
      jobCount: 0,
      earnedJobCount: 0,
      upcomingJobCount: 0,
      avgPerJobDkk: 0,
      byMonth: [],
      byEventType: [],
      byRegion: [],
      topGenres: [],
    );
  }

  final totalDkk = played.fold<int>(0, (sum, e) => sum + e.payoutDkk);
  final earned = played.where((e) => e.date.isBefore(now)).toList();
  final upcoming = played.where((e) => !e.date.isBefore(now)).toList();
  final earnedDkk = earned.fold<int>(0, (sum, e) => sum + e.payoutDkk);
  final upcomingDkk = upcoming.fold<int>(0, (sum, e) => sum + e.payoutDkk);

  // ── Month buckets ────────────────────────────────────────────────────────
  // Upcoming is accumulated PER BOOKING. A month-level "is this month after the
  // current month" rule is wrong: on the 14th, a month whose only job is on the 21st
  // is entirely still ahead, yet that rule would show it as earned.
  final monthKeys = <String, MonthBucket>{};
  for (final e in played) {
    final key = '${e.date.year}-${e.date.month}';
    final existing = monthKeys[key];
    final entryIsUpcoming = !e.date.isBefore(now);
    monthKeys[key] = MonthBucket(
      year: e.date.year,
      month: e.date.month,
      totalDkk: (existing?.totalDkk ?? 0) + e.payoutDkk,
      jobs: (existing?.jobs ?? 0) + 1,
      upcomingDkk:
          (existing?.upcomingDkk ?? 0) + (entryIsUpcoming ? e.payoutDkk : 0),
      upcomingJobs: (existing?.upcomingJobs ?? 0) + (entryIsUpcoming ? 1 : 0),
    );
  }
  final byMonth =
      monthKeys.values.toList()..sort((a, b) {
        final byYear = a.year.compareTo(b.year);
        return byYear != 0 ? byYear : a.month.compareTo(b.month);
      });

  // ── Category buckets (event type + region) ───────────────────────────────
  List<CategoryBucket> group(String? Function(StatEntry) selector) {
    final map = <String, CategoryBucket>{};
    for (final e in played) {
      final raw = selector(e)?.trim();
      if (raw == null || raw.isEmpty) continue; // unknown => not a category
      final label = _titleCase(raw);
      final existing = map[label];
      final entryIsUpcoming = !e.date.isBefore(now);
      map[label] = CategoryBucket(
        label: label,
        totalDkk: (existing?.totalDkk ?? 0) + e.payoutDkk,
        jobs: (existing?.jobs ?? 0) + 1,
        upcomingDkk:
            (existing?.upcomingDkk ?? 0) + (entryIsUpcoming ? e.payoutDkk : 0),
        upcomingJobs: (existing?.upcomingJobs ?? 0) + (entryIsUpcoming ? 1 : 0),
      );
    }
    return map.values.toList()..sort((a, b) {
      final byJobs = b.jobs.compareTo(a.jobs);
      return byJobs != 0 ? byJobs : b.totalDkk.compareTo(a.totalDkk);
    });
  }

  // ── Extras ───────────────────────────────────────────────────────────────
  final busiest = byMonth.reduce((a, b) => b.jobs > a.jobs ? b : a);

  final weekdayCounts = <int, int>{};
  for (final e in played) {
    weekdayCounts[e.date.weekday] = (weekdayCounts[e.date.weekday] ?? 0) + 1;
  }
  int? topWeekday;
  double? topWeekdayShare;
  if (weekdayCounts.isNotEmpty) {
    final top = weekdayCounts.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );
    topWeekday = top.key;
    topWeekdayShare = top.value / played.length;
  }

  final guests = played.map((e) => e.guestsAmount).whereType<int>().toList();
  final avgGuests =
      guests.isEmpty
          ? null
          : (guests.fold<int>(0, (s, g) => s + g) / guests.length).round();

  final genreCounts = <String, int>{};
  for (final e in played) {
    for (final g in e.genres ?? const <String>[]) {
      final label = g.trim();
      if (label.isEmpty) continue;
      genreCounts[label] = (genreCounts[label] ?? 0) + 1;
    }
  }
  final topGenres =
      (genreCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .map((e) => e.key)
          .take(3)
          .toList();

  return PerformerStats(
    totalDkk: totalDkk,
    earnedDkk: earnedDkk,
    upcomingDkk: upcomingDkk,
    jobCount: played.length,
    earnedJobCount: earned.length,
    upcomingJobCount: upcoming.length,
    avgPerJobDkk: (totalDkk / played.length).round(),
    byMonth: byMonth,
    byEventType: group((e) => e.eventType),
    byRegion: group((e) => e.region),
    topGenres: topGenres,
    busiestMonth: busiest,
    topWeekday: topWeekday,
    topWeekdayShare: topWeekdayShare,
    avgGuests: avgGuests,
  );
}

/// The calendar years present in [entries], newest first — drives the year filter
/// so we never offer a year the performer has no bookings in.
List<int> statYears(List<StatEntry> entries) {
  return entries.map((e) => e.date.year).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
}

/// `bryllup` / `BRYLLUP` -> `Bryllup`. Event types are free text in the DB with
/// inconsistent casing, so normalise for display AND grouping (otherwise
/// "Bryllup" and "bryllup" become two separate rows).
String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

const _danishMonths = [
  'Januar',
  'Februar',
  'Marts',
  'April',
  'Maj',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'December',
];

String danishMonthName(int month) => _danishMonths[month - 1];

String danishMonthShort(int month) => danishMonthName(month).substring(0, 3);

const _danishWeekdays = [
  'mandag',
  'tirsdag',
  'onsdag',
  'torsdag',
  'fredag',
  'lørdag',
  'søndag',
];

String danishWeekdayName(int weekday) => _danishWeekdays[weekday - 1];
