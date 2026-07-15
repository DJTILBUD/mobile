import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/core/utils/budget_utils.dart';
import 'package:dj_tilbud_app/features/calendar/data/models/calendar_event_model.dart';

/// One job must show ONE budget everywhere in the app.
///
/// The calendar builds its events from raw DB rows while the job list builds
/// them from `Job` entities. Both must go through `djBudgetLabelFromParts`, or a
/// DJ sees the sax/tier-adjusted figure in the list and the raw customer budget
/// on the calendar for the same job. These tests pin the calendar side to the
/// same builder.
void main() {
  Map<String, dynamic> quoteRow({
    num? budgetStart = 10000,
    num? budgetEnd = 10000,
    bool sax = false,
    num? musicianHours,
    String createdAt = '2026-01-01T00:00:00Z',
  }) => {
    'id': 1,
    'job': {
      'id': 42,
      'event_type': 'Bryllup',
      'date': '2026-09-01',
      'time_start': '20:00:00',
      'time_end': '02:00:00',
      'city': 'København',
      'region': 'Hovedstaden',
      'guests_amount': 100,
      'budget_start': budgetStart,
      'budget_end': budgetEnd,
      'created_at': createdAt,
      'requested_saxophonist': sax,
      'requested_musician_hours': musicianHours,
    },
  };

  group(
    'CalendarEventModel.fromDjQuoteJson — budget must match the job list',
    () {
      test(
        'deducts the sax cost instead of showing the raw customer budget',
        () {
          final event = CalendarEventModel.fromDjQuoteJson(
            quoteRow(sax: true, musicianHours: 1),
          );

          // 10000 - 4350 (1h sax) = 5650. The raw budget would be "10.000 kr.".
          expect(event.budgetDisplay, '5.650 kr.');
          expect(
            event.budgetDisplay,
            isNot(contains('10.000')),
            reason: 'the calendar must never show the raw customer budget',
          );
        },
      );

      test('matches djBudgetLabelFromParts exactly for the same job', () {
        final event = CalendarEventModel.fromDjQuoteJson(
          quoteRow(
            budgetStart: 8000,
            budgetEnd: 12000,
            sax: true,
            musicianHours: 2,
          ),
          djTier: 'A',
        );

        expect(
          event.budgetDisplay,
          djBudgetLabelFromParts(
            budgetStart: 8000,
            budgetEnd: 12000,
            djTier: 'A',
            requestedSaxophonist: true,
            requestedMusicianHours: 2,
            jobCreatedAt: DateTime.parse('2026-01-01T00:00:00Z'),
          ),
        );
      });

      test('applies the B-tier deduction when a tier is passed', () {
        final createdAt = DateTime.now().toUtc().toIso8601String();

        final bTier = CalendarEventModel.fromDjQuoteJson(
          quoteRow(budgetStart: 20000, budgetEnd: 20000, createdAt: createdAt),
          djTier: 'B',
        );
        final aTier = CalendarEventModel.fromDjQuoteJson(
          quoteRow(budgetStart: 20000, budgetEnd: 20000, createdAt: createdAt),
          djTier: 'A',
        );

        // B-tier is 500 lower inside the 24h window: 18.750 vs 19.250.
        expect(bTier.budgetDisplay, '18.750 kr.');
        expect(aTier.budgetDisplay, '19.250 kr.');
      });

      test('no budget on the job yields no budget label', () {
        final event = CalendarEventModel.fromDjQuoteJson(
          quoteRow(budgetStart: null, budgetEnd: null),
        );
        expect(event.budgetDisplay, isNull);
      });
    },
  );

  group('musician offers show the offer payout, never the customer budget', () {
    // A ServiceOffer has a customer price and a musician payout. The job's
    // budget is unrelated to it and must never appear against an offer.
    Map<String, dynamic> offerRow({
      required num priceDkk,
      num? musicianPayoutDkk,
    }) => {
      'id': 7,
      'price_dkk': priceDkk,
      'musician_payout_dkk': musicianPayoutDkk,
      'job': {
        'id': 42,
        'event_type': 'Bryllup',
        'date': '2026-09-01',
        'time_start': '20:00:00',
        'time_end': '02:00:00',
        'city': 'København',
        'region': 'Hovedstaden',
        'guests_amount': 100,
      },
    };

    test('uses musician_payout_dkk when present', () {
      final event = CalendarEventModel.fromMusicianJobOfferJson(
        offerRow(priceDkk: 6000, musicianPayoutDkk: 4200),
      );
      expect(event.budgetDisplay, '4.200 kr.');
    });

    test('falls back to price_dkk when there is no explicit payout', () {
      final event = CalendarEventModel.fromMusicianJobOfferJson(
        offerRow(priceDkk: 6000),
      );
      expect(event.budgetDisplay, '6.000 kr.');
    });

    test('ext-job offers use the payout too, not budget_target', () {
      final event = CalendarEventModel.fromMusicianExtJobOfferJson({
        'id': 8,
        'price_dkk': 7000,
        'musician_payout_dkk': 5000,
        'ext_job': {
          'id': 99,
          'event_type': 'Firmafest',
          'date': '2026-09-02',
          'start_time': '19:00:00',
          'end_time': '23:00:00',
          'location': 'Aarhus',
          'region': 'Østjylland',
          'guests_amount': 50,
          // budget_target is no longer selected; even if a row carried one it
          // must never be shown against an offer.
          'budget_target': '20.000 kr.',
        },
      });
      expect(event.budgetDisplay, '5.000 kr.');
      expect(event.budgetDisplay, isNot(contains('20.000')));
    });
  });
}
