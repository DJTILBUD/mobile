import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/core/utils/sax_high_season.dart';
import 'package:dj_tilbud_app/core/utils/musician_price.dart';
import 'package:dj_tilbud_app/core/utils/budget_utils.dart';

/// Parity tests for season saxophone pricing.
///
/// `web-app/src/helpers/saxHighSeason.ts`, `calculateMusicianOfferPrice.ts` and
/// `calculateCustomerMusicianPrice.ts` are the source of truth. Every expected value below is what
/// the web helpers return for the same inputs — if they change, change these numbers and the Dart
/// helpers together.
void main() {
  // Either side of the rollout cutoff (saxSeasonPricingStart = 2026-08-24).
  final preLaunch = DateTime.utc(2026, 7, 10);
  final postLaunch = DateTime.utc(2026, 8, 25);
  // Before the separate 2026-07-06 customer-price cutoff.
  final legacy = DateTime.utc(2026, 6, 1);

  final seasonDate = DateTime(2027, 6, 5); // Saturday in June
  final offSeasonDate = DateTime(2027, 6, 4); // Friday in June

  group('isSaxHighSeason', () {
    test('matches Saturdays inside the seasonal windows', () {
      expect(
        isSaxHighSeason(DateTime(2027, 5, 22)),
        isTrue,
      ); // last 2 weeks of May
      expect(isSaxHighSeason(DateTime(2027, 6, 5)), isTrue); // all of June
      expect(isSaxHighSeason(DateTime(2027, 8, 7)), isTrue); // all of August
      expect(
        isSaxHighSeason(DateTime(2027, 9, 4)),
        isTrue,
      ); // first 2 weeks of September
    });

    test('rejects Saturdays outside the windows', () {
      expect(
        isSaxHighSeason(DateTime(2027, 5, 15)),
        isFalse,
      ); // May, before the 18th
      expect(isSaxHighSeason(DateTime(2027, 2, 13)), isFalse); // wrong month

      // The extras set covers the 3rd and 4th Saturdays of September every year, so those dates
      // assert the extras, not the recurring rule. Pick a late-September Saturday that is neither,
      // and prove it is outside the extras rather than assuming it.
      final lateSeptemberSaturday = DateTime(2028, 9, 30);
      expect(
        saxHighSeasonExtraDates.contains('2028-09-30'),
        isFalse,
      );
      expect(
        isSaxHighSeason(lateSeptemberSaturday),
        isFalse,
      ); // September, after the 14th
    });

    test('rejects non-Saturdays inside the windows', () {
      expect(isSaxHighSeason(DateTime(2027, 6, 4)), isFalse); // Friday
      expect(isSaxHighSeason(DateTime(2027, 6, 6)), isFalse); // Sunday
    });

    test('treats 4 July as seasonal only when it lands on a Saturday', () {
      expect(isSaxHighSeason(DateTime(2026, 7, 4)), isTrue); // Saturday
      expect(
        isSaxHighSeason(DateTime(2027, 7, 3)),
        isFalse,
      ); // Saturday, not the 4th
      expect(
        isSaxHighSeason(DateTime(2027, 7, 4)),
        isFalse,
      ); // the 4th, but a Sunday
    });

    test(
      'honours the explicit extra dates regardless of the Saturday rule',
      () {
        expect(isSaxHighSeason(DateTime(2026, 11, 27)), isTrue); // a Friday
        expect(
          isSaxHighSeason(DateTime(2026, 9, 19)),
          isTrue,
        ); // Saturday after 14 Sept
      },
    );

    test('returns false for a null date', () {
      expect(isSaxHighSeason(null), isFalse);
    });
  });

  group('isSaxSeasonPricingActive', () {
    test('requires both a seasonal event date and a post-launch job', () {
      expect(isSaxSeasonPricingActive(postLaunch, seasonDate), isTrue);
      expect(isSaxSeasonPricingActive(preLaunch, seasonDate), isFalse);
      expect(isSaxSeasonPricingActive(postLaunch, offSeasonDate), isFalse);
    });

    test('includes a job created exactly at the launch instant', () {
      expect(
        isSaxSeasonPricingActive(saxSeasonPricingStart, seasonDate),
        isTrue,
      );
      expect(
        isSaxSeasonPricingActive(
          saxSeasonPricingStart.subtract(const Duration(milliseconds: 1)),
          seasonDate,
        ),
        isFalse,
      );
    });

    test('treats a missing creation date as post-launch', () {
      expect(isSaxSeasonPricingActive(null, seasonDate), isTrue);
    });

    test('is false whenever the event date is missing', () {
      expect(isSaxSeasonPricingActive(postLaunch, null), isFalse);
    });
  });

  group('calculateMusicianOfferPrice — payout', () {
    test('standard payouts off season', () {
      expect(calculateMusicianOfferPrice(0.5, postLaunch, offSeasonDate), 3150);
      expect(calculateMusicianOfferPrice(1, postLaunch, offSeasonDate), 3350);
      expect(calculateMusicianOfferPrice(1.5, postLaunch, offSeasonDate), 4000);
    });

    test('season payouts on a season date', () {
      expect(calculateMusicianOfferPrice(0.5, postLaunch, seasonDate), 3900);
      expect(calculateMusicianOfferPrice(1, postLaunch, seasonDate), 4150);
      expect(calculateMusicianOfferPrice(1.5, postLaunch, seasonDate), 5000);
    });

    test('a pre-launch job stays on the standard payouts', () {
      expect(calculateMusicianOfferPrice(1, preLaunch, seasonDate), 3350);
    });

    test('keeps the +800 half-hour increment above 1.5h in both tables', () {
      expect(calculateMusicianOfferPrice(2, postLaunch, offSeasonDate), 4800);
      expect(calculateMusicianOfferPrice(2, postLaunch, seasonDate), 5800);
    });
  });

  group('calculateCustomerMusicianPrice — customer price', () {
    test('legacy table for jobs created before 2026-07-06', () {
      expect(calculateCustomerMusicianPrice(0.5, legacy), 3900);
      expect(calculateCustomerMusicianPrice(1, legacy), 4200);
      expect(calculateCustomerMusicianPrice(1.5, legacy), 5000);
    });

    test('standard table off season', () {
      expect(
        calculateCustomerMusicianPrice(0.5, postLaunch, offSeasonDate),
        4090,
      );
      expect(
        calculateCustomerMusicianPrice(1, postLaunch, offSeasonDate),
        4350,
      );
      expect(
        calculateCustomerMusicianPrice(1.5, postLaunch, offSeasonDate),
        5190,
      );
    });

    test('season table on a season date', () {
      expect(calculateCustomerMusicianPrice(0.5, postLaunch, seasonDate), 5090);
      expect(calculateCustomerMusicianPrice(1, postLaunch, seasonDate), 5400);
      expect(calculateCustomerMusicianPrice(1.5, postLaunch, seasonDate), 6490);
    });

    test('a pre-launch job keeps its own table even for a season date', () {
      expect(calculateCustomerMusicianPrice(1, preLaunch, seasonDate), 4350);
      expect(calculateCustomerMusicianPrice(1, legacy, seasonDate), 4200);
    });

    // Payout share per the pricing sheet: 76.62 / 76.85 / 77.04 %, i.e. a 23.38 / 23.15 / 22.96 %
    // cut. The season figures are rounded to clean numbers, so they sit near 23% rather than on it.
    test('holds ~23% margin on the season table', () {
      for (final hours in [0.5, 1.0, 1.5]) {
        final payout = calculateMusicianOfferPrice(
          hours,
          postLaunch,
          seasonDate,
        );
        final customer = calculateCustomerMusicianPrice(
          hours,
          postLaunch,
          seasonDate,
        );
        final margin = (customer - payout) / customer;
        expect(margin, greaterThan(0.225));
        expect(margin, lessThan(0.235));
      }
    });
  });

  group('adjustBudgetForDjView — season deduction', () {
    test('deducts the SEASON sax price on a season date', () {
      // web: 12000 - 5400 = 6600, then -250 (>6500) = 6350
      expect(
        adjustBudgetForDjView(
          budget: 12000,
          requestedSaxophonist: true,
          requestedMusicianHours: 1,
          jobCreatedAt: postLaunch,
          eventDate: seasonDate,
        ),
        6350,
      );
    });

    test('deducts the standard sax price off season', () {
      // web: 12000 - 4350 = 7650, then -500 (>7500) and -250 (>6500) = 6900
      expect(
        adjustBudgetForDjView(
          budget: 12000,
          requestedSaxophonist: true,
          requestedMusicianHours: 1,
          jobCreatedAt: postLaunch,
          eventDate: offSeasonDate,
        ),
        6900,
      );
    });

    test(
      'a pre-launch job keeps the standard deduction even on a season date',
      () {
        expect(
          adjustBudgetForDjView(
            budget: 12000,
            requestedSaxophonist: true,
            requestedMusicianHours: 1,
            jobCreatedAt: preLaunch,
            eventDate: seasonDate,
          ),
          6900,
        );
      },
    );

    test('still caps at the 1.5 tier on a season date', () {
      for (final hours in [1.5, 2.0, 3.0]) {
        // 12000 - 6490 = 5510, which clears neither the 7500 nor the 6500 threshold.
        expect(
          adjustBudgetForDjView(
            budget: 12000,
            requestedSaxophonist: true,
            requestedMusicianHours: hours,
            jobCreatedAt: postLaunch,
            eventDate: seasonDate,
          ),
          5510,
          reason: '$hours hours must deduct the 1.5-tier season price',
        );
      }
    });

    test('omitting the event date falls back to the standard deduction', () {
      expect(
        adjustBudgetForDjView(
          budget: 12000,
          requestedSaxophonist: true,
          requestedMusicianHours: 1,
          jobCreatedAt: postLaunch,
        ),
        6900,
      );
    });
  });
}
