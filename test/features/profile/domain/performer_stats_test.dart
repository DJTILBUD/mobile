import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/profile/domain/performer_stats.dart';

void main() {
  // Fixed 'today' so earned-vs-upcoming is deterministic.
  final now = DateTime(2026, 7, 14);

  StatEntry entry(
    DateTime date,
    int payout, {
    String? eventType,
    String? region,
    int? guests,
    List<String>? genres,
  }) => StatEntry(
    date: date,
    payoutDkk: payout,
    eventType: eventType,
    region: region,
    guestsAmount: guests,
    genres: genres,
  );

  group('computeStats — counts exactly the entries it is given', () {
    // The ready_for_billing gate lives in stats_provider. This function must NOT
    // second-guess it by also filtering on the date, or a legitimately billable
    // job could silently vanish from someone's earnings.
    test('every entry counts, regardless of its date', () {
      final stats = computeStats([
        entry(DateTime(2026, 6, 1), 5000),
        entry(DateTime(2026, 12, 24), 4000),
      ], now: now);

      expect(stats.jobCount, 2);
      expect(stats.totalDkk, 9000);
    });

    test('empty input yields a zeroed, empty result rather than throwing', () {
      final stats = computeStats([], now: now);
      expect(stats.isEmpty, true);
      expect(stats.totalDkk, 0);
      expect(stats.jobCount, 0);
      expect(stats.avgPerJobDkk, 0);
      expect(stats.byMonth, isEmpty);
      expect(stats.busiestMonth, isNull);
    });

    test(
      'a year with no entries is empty (no divide-by-zero on the average)',
      () {
        final stats = computeStats(
          [entry(DateTime(2026, 1, 1), 5000)],
          now: now,
          year: 2024,
        );
        expect(stats.isEmpty, true);
        expect(stats.avgPerJobDkk, 0);
      },
    );
  });

  // ready_for_billing does NOT mean the event happened — real profiles carry
  // ready_for_billing jobs months ahead. Everything still counts in the totals, but
  // "tjent" must only ever be the part that has actually been played.
  group('computeStats — earned vs upcoming', () {
    final mixed = [
      entry(DateTime(2026, 6, 1), 5000), // played
      entry(DateTime(2026, 7, 1), 3000), // played (earlier this month)
      entry(DateTime(2026, 10, 4), 4000), // booked ahead
      entry(DateTime(2026, 11, 20), 2000), // booked ahead
    ];

    test('splits money into earned (past) and upcoming (future)', () {
      final stats = computeStats(mixed, now: now);
      expect(stats.totalDkk, 14000);
      expect(stats.earnedDkk, 8000); // only the two played
      expect(stats.upcomingDkk, 6000); // only the two ahead
      expect(stats.earnedJobCount, 2);
      expect(stats.upcomingJobCount, 2);
      expect(stats.jobCount, 4); // total still counts everything
      expect(stats.hasUpcoming, true);
    });

    test('a profile with nothing booked ahead reports no upcoming', () {
      final stats = computeStats([entry(DateTime(2026, 6, 1), 5000)], now: now);
      expect(stats.earnedDkk, 5000);
      expect(stats.upcomingDkk, 0);
      expect(stats.hasUpcoming, false);
    });

    test('a month whose bookings are all ahead is flagged upcoming', () {
      final stats = computeStats(mixed, now: now);
      final byKey = {for (final b in stats.byMonth) '${b.year}-${b.month}': b};
      expect(byKey['2026-6']!.isUpcoming, false); // past
      expect(byKey['2026-7']!.isUpcoming, false); // played earlier this month
      expect(byKey['2026-10']!.isUpcoming, true);
      expect(byKey['2026-11']!.isUpcoming, true);
    });

    // The bug this pins: on the 14th, a job on the 21st is NOT played. Flagging by
    // month ("July is the current month, so it counts as earned") got this wrong.
    test(
      'CURRENT month counts as upcoming when its only job is still ahead',
      () {
        final stats = computeStats([
          entry(DateTime(2026, 7, 21), 4000), // later this month
        ], now: now); // now = 2026-07-14

        expect(stats.earnedDkk, 0);
        expect(stats.upcomingDkk, 4000);
        expect(stats.upcomingJobCount, 1);
        final july = stats.byMonth.single;
        expect(july.month, 7);
        expect(
          july.isUpcoming,
          true,
        ); // fully ahead, despite being "this month"
        expect(july.isPartlyUpcoming, false);
      },
    );

    // Regression: the month list and the category lists must agree about the SAME
    // job. A year containing only future bookings rendered grey under "Marts 2027"
    // but full green under Eventtyper / Hvor i landet, i.e. green ("tjent") money
    // the performer had not earned.
    test('categories carry the upcoming split, exactly like months do', () {
      final stats = computeStats([
        entry(
          DateTime(2027, 3, 6),
          5250,
          eventType: 'Bryllup',
          region: 'Sønderjylland',
        ),
      ], now: now); // now = 2026-07-14, so this is entirely ahead

      expect(stats.byMonth.single.isUpcoming, true);
      // ...and every category agrees rather than claiming it as earned.
      expect(stats.byEventType.single.isUpcoming, true);
      expect(stats.byEventType.single.upcomingJobs, 1);
      expect(stats.byRegion.single.isUpcoming, true);
      expect(stats.byRegion.single.upcomingJobs, 1);
    });

    test('a category with a mix of played and upcoming reports both', () {
      final stats = computeStats([
        entry(DateTime(2026, 6, 1), 4000, eventType: 'Bryllup'), // played
        entry(DateTime(2026, 12, 1), 6000, eventType: 'Bryllup'), // ahead
      ], now: now);

      final bryllup = stats.byEventType.single;
      expect(bryllup.jobs, 2);
      expect(bryllup.upcomingJobs, 1);
      expect(bryllup.upcomingDkk, 6000);
      expect(bryllup.isUpcoming, false); // not ALL ahead
      expect(bryllup.isPartlyUpcoming, true);
    });

    test('a part-played month reports how many are still ahead', () {
      final stats = computeStats([
        entry(DateTime(2026, 7, 2), 3000), // played
        entry(DateTime(2026, 7, 21), 4000), // still ahead
      ], now: now);

      final july = stats.byMonth.single;
      expect(july.jobs, 2);
      expect(july.totalDkk, 7000);
      expect(july.upcomingJobs, 1);
      expect(july.upcomingDkk, 4000);
      expect(july.isUpcoming, false); // not ALL ahead
      expect(july.isPartlyUpcoming, true);
      // ...and the split still attributes the money correctly.
      expect(stats.earnedDkk, 3000);
      expect(stats.upcomingDkk, 4000);
    });
  });

  group('computeStats — totals and year filter', () {
    final entries = [
      entry(DateTime(2026, 6, 1), 4000),
      entry(DateTime(2026, 6, 20), 6000),
      entry(DateTime(2026, 5, 3), 3000),
      entry(DateTime(2025, 8, 9), 10000), // last year
    ];

    test('all-time totals and average', () {
      final stats = computeStats(entries, now: now);
      expect(stats.totalDkk, 23000);
      expect(stats.jobCount, 4);
      expect(stats.avgPerJobDkk, 5750);
    });

    test('year filter scopes everything to that calendar year', () {
      final stats = computeStats(entries, now: now, year: 2026);
      expect(stats.totalDkk, 13000);
      expect(stats.jobCount, 3);
      expect(stats.byMonth.length, 2);
    });

    test('months are chronological with per-month totals and counts', () {
      final stats = computeStats(entries, now: now, year: 2026);
      expect(stats.byMonth.first.month, 5);
      expect(stats.byMonth.first.totalDkk, 3000);
      expect(stats.byMonth.first.jobs, 1);
      expect(stats.byMonth.last.month, 6);
      expect(stats.byMonth.last.totalDkk, 10000);
      expect(stats.byMonth.last.jobs, 2);
    });

    test('busiest month is by job count, not earnings', () {
      final stats = computeStats([
        entry(DateTime(2026, 5, 1), 50000), // one huge job
        entry(DateTime(2026, 6, 1), 1000),
        entry(DateTime(2026, 6, 2), 1000),
      ], now: now);
      expect(stats.busiestMonth!.month, 6);
    });
  });

  group('computeStats — categories', () {
    test('groups by event type, case-insensitively', () {
      final stats = computeStats([
        entry(DateTime(2026, 1, 1), 1000, eventType: 'Bryllup'),
        entry(DateTime(2026, 2, 1), 2000, eventType: 'bryllup'), // same thing
        entry(DateTime(2026, 3, 1), 500, eventType: 'Firmafest'),
      ], now: now);

      expect(stats.byEventType.length, 2);
      expect(stats.byEventType.first.label, 'Bryllup');
      expect(stats.byEventType.first.jobs, 2);
      expect(stats.byEventType.first.totalDkk, 3000);
    });

    test('null/blank categories are skipped, not bucketed as "unknown"', () {
      final stats = computeStats([
        entry(DateTime(2026, 1, 1), 1000, eventType: 'Bryllup', region: null),
        entry(DateTime(2026, 2, 1), 1000, eventType: null, region: '  '),
      ], now: now);

      expect(stats.byEventType.length, 1);
      expect(stats.byRegion, isEmpty);
      expect(stats.jobCount, 2); // still counted in the totals
    });

    test('categories sort by job count desc', () {
      final stats = computeStats([
        entry(DateTime(2026, 1, 1), 100, region: 'Fyn'),
        entry(DateTime(2026, 2, 1), 100, region: 'Hovedstaden'),
        entry(DateTime(2026, 3, 1), 100, region: 'Hovedstaden'),
      ], now: now);
      expect(stats.byRegion.first.label, 'Hovedstaden');
      expect(stats.byRegion.first.jobs, 2);
    });
  });

  group('computeStats — extras', () {
    test('top weekday and its share', () {
      // 2026-06-06 and 2026-06-13 are Saturdays; 2026-06-10 is a Wednesday.
      final stats = computeStats([
        entry(DateTime(2026, 6, 6), 100),
        entry(DateTime(2026, 6, 13), 100),
        entry(DateTime(2026, 6, 10), 100),
      ], now: now);

      expect(stats.topWeekday, DateTime.saturday);
      expect(stats.topWeekdayShare, closeTo(2 / 3, 0.001));
      expect(danishWeekdayName(stats.topWeekday!), 'lørdag');
    });

    test('average guests ignores entries with no guest count', () {
      final stats = computeStats([
        entry(DateTime(2026, 1, 1), 100, guests: 100),
        entry(DateTime(2026, 2, 1), 100, guests: 200),
        entry(DateTime(2026, 3, 1), 100, guests: null),
      ], now: now);
      expect(stats.avgGuests, 150);
    });

    test('top genres are the 3 most frequent', () {
      final stats = computeStats([
        entry(DateTime(2026, 1, 1), 100, genres: ['Pop', 'Disco']),
        entry(DateTime(2026, 2, 1), 100, genres: ['Pop', 'Rock']),
        entry(DateTime(2026, 3, 1), 100, genres: ['Pop', 'Disco', 'Techno']),
      ], now: now);
      expect(stats.topGenres.first, 'Pop');
      expect(stats.topGenres.length, 3);
    });
  });

  group('statYears', () {
    test('returns the years present, deduped, newest first', () {
      final years = statYears([
        entry(DateTime(2025, 1, 1), 1),
        entry(DateTime(2026, 1, 1), 1),
        entry(DateTime(2026, 5, 1), 1),
      ]);
      expect(years, [2026, 2025]);
    });

    test('no entries yields no years (year filter offers nothing)', () {
      expect(statYears([]), isEmpty);
    });
  });

  group('danish labels', () {
    test('month names', () {
      expect(danishMonthName(1), 'Januar');
      expect(danishMonthName(12), 'December');
      expect(danishMonthShort(6), 'Jun');
    });
  });
}
