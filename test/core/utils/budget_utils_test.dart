import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/core/utils/budget_utils.dart';

/// Parity tests for `adjustBudgetForDjView`.
///
/// The web-app's `web-app/src/helpers/adjustBudgetForDjView.ts` is the source of
/// truth for the DJ-facing budget. A DJ must never see a different figure in the
/// app than on the web, so every expected value below is what the web helper
/// returns for the same inputs. If the web helper changes, change these numbers
/// and the Dart helper together.
void main() {
  group('adjustBudgetForDjView — must mirror the web app exactly', () {
    test('returns null for a null or zero budget', () {
      expect(adjustBudgetForDjView(budget: null), isNull);
      expect(adjustBudgetForDjView(budget: 0), isNull);
    });

    test('applies the >7500 then >6500 deductions in order', () {
      // web: 20000 -> -500 (>7500) -> -250 (>6500) = 19250
      expect(adjustBudgetForDjView(budget: 20000), 19250);
    });

    test('no sax requested means no sax deduction', () {
      // web: sax block is skipped entirely; 10000 -> -500 -> -250 = 9250
      expect(
        adjustBudgetForDjView(budget: 10000, requestedSaxophonist: false),
        9250,
      );
    });

    test('does not deduct the sax cost at or below a 7000 budget', () {
      // web: `budget > 7000` gates the sax block. 7000 -> -250 (>6500) = 6750
      expect(
        adjustBudgetForDjView(
          budget: 7000,
          requestedSaxophonist: true,
          requestedMusicianHours: 1,
        ),
        6750,
      );
    });

    group('sax deduction is a FLAT value, never keyed on created_at', () {
      // The web helper's "fee increase" commit bumped 3900/4200/5000 to
      // 4090/4350/5190 outright and added NO date branch, so these apply to
      // every job regardless of age. Mobile previously kept the old values for
      // jobs created before 2026-07-06, which showed DJs a HIGHER budget than
      // the web on older jobs. These cases lock that regression out.
      final beforeFeeIncrease = DateTime.utc(2026, 1, 1);
      final afterFeeIncrease = DateTime.utc(2026, 7, 10);

      test('0.5 hours deducts 4090 regardless of created_at', () {
        // web: 10000 - 4090 = 5910 (no further deduction; 5910 <= 6500)
        for (final createdAt in [null, beforeFeeIncrease, afterFeeIncrease]) {
          expect(
            adjustBudgetForDjView(
              budget: 10000,
              requestedSaxophonist: true,
              requestedMusicianHours: 0.5,
              jobCreatedAt: createdAt,
            ),
            5910,
            reason: 'created_at $createdAt must not change the sax deduction',
          );
        }
      });

      test('1 hour deducts 4350 regardless of created_at', () {
        // web: 10000 - 4350 = 5650
        for (final createdAt in [null, beforeFeeIncrease, afterFeeIncrease]) {
          expect(
            adjustBudgetForDjView(
              budget: 10000,
              requestedSaxophonist: true,
              requestedMusicianHours: 1,
              jobCreatedAt: createdAt,
            ),
            5650,
            reason: 'created_at $createdAt must not change the sax deduction',
          );
        }
      });

      test('1.5 hours or more deducts 5190 regardless of created_at', () {
        // web: `>= 1.5` branch. 10000 - 5190 = 4810
        for (final hours in [1.5, 2.0, 3.0]) {
          for (final createdAt in [null, beforeFeeIncrease, afterFeeIncrease]) {
            expect(
              adjustBudgetForDjView(
                budget: 10000,
                requestedSaxophonist: true,
                requestedMusicianHours: hours,
                jobCreatedAt: createdAt,
              ),
              4810,
              reason: '$hours hours / created_at $createdAt',
            );
          }
        }
      });
    });

    group('B-tier 24h deduction', () {
      test('deducts 500 more for a B-tier DJ inside the 24h window', () {
        // web: 20000 -> -500 -> -250 -> -500 (B-tier, maxBudget > 5000) = 18750
        expect(
          adjustBudgetForDjView(
            budget: 20000,
            djTier: 'B',
            maxBudget: 20000,
            jobCreatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          18750,
        );
      });

      test('does not deduct once the 24h window has passed', () {
        expect(
          adjustBudgetForDjView(
            budget: 20000,
            djTier: 'B',
            maxBudget: 20000,
            jobCreatedAt: DateTime.now().subtract(const Duration(hours: 25)),
          ),
          19250,
        );
      });

      test('does not deduct when the top budget is 5000 or below', () {
        // web: `(maxBudget ?? budget) <= 5000` disables the B-tier deduction.
        expect(
          adjustBudgetForDjView(
            budget: 5000,
            djTier: 'B',
            maxBudget: 5000,
            jobCreatedAt: DateTime.now(),
          ),
          5000,
        );
      });

      test('does not apply to an A-tier DJ', () {
        expect(
          adjustBudgetForDjView(
            budget: 20000,
            djTier: 'A',
            maxBudget: 20000,
            jobCreatedAt: DateTime.now(),
          ),
          19250,
        );
      });
    });
  });
}
