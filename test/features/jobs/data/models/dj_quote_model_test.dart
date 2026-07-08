import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/dj_quote_model.dart';

void main() {
  group('DjQuoteModel.fromJson', () {
    // The bare quote row returned by POST /api/jobs/{id}/quotes (no `job` join).
    final bareQuote = <String, dynamic>{
      'id': 4878,
      'job_id': 2331,
      'price_dkk': 12000,
      'sales_pitch': 'Tillykke med jeres bryllup',
      'equipment_description': '{"v":1,"gear":[]}',
      'status': 'pending',
      'created_at': '2026-05-25T09:31:15.901612+00:00',
      'early_setup_status': null,
      'early_setup_price': null,
      'dj_ready_confirmed_at': null,
      'extra_hours': null,
      'extra_hours_price_per_hour': null,
      'dj_notes': null,
    };

    test(
      'parses a bare quote with no `job` key, falling back to a placeholder',
      () {
        final model = DjQuoteModel.fromJson(bareQuote);

        expect(model.id, 4878);
        expect(model.jobId, 2331);
        expect(model.priceDkk, 12000);
        expect(model.status, 'pending');
        // Placeholder job — never read by the UI, but must not crash parsing.
        expect(model.job.id, 0);

        // toEntity() must also succeed end-to-end.
        final entity = model.toEntity();
        expect(entity.id, 4878);
        expect(entity.jobId, 2331);
      },
    );

    test('parses the joined `job` when present (quotes-list query)', () {
      final withJob = <String, dynamic>{
        ...bareQuote,
        'job': <String, dynamic>{
          'id': 2331,
          'event_type': 'Bryllup',
          'date': '2027-06-26',
          'time_start': '21:00:00',
          'time_end': '02:30:00',
          'city': 'Egeskov Hotel',
          'region': 'Vestjylland',
          'guests_amount': 55,
          'status': 'open',
          'created_at': '2026-05-24T20:38:50.296994+00:00',
        },
      };

      final model = DjQuoteModel.fromJson(withJob);

      expect(model.job.id, 2331);
      expect(model.job.eventType, 'Bryllup');
      expect(model.job.city, 'Egeskov Hotel');
    });
  });

  group('DjQuote payout — must mirror web app QuoteInfo exactly', () {
    // Base row with a 12.000 kr job price (standard payout would be 9.000 kr).
    Map<String, dynamic> row(Map<String, dynamic> extra) => <String, dynamic>{
      'id': 1,
      'job_id': 1,
      'price_dkk': 12000,
      'sales_pitch': '',
      'equipment_description': '',
      'status': 'won',
      'created_at': '2026-05-25T09:31:15.901612+00:00',
      ...extra,
    };

    test('parses dj_payout_override', () {
      expect(
        DjQuoteModel.fromJson(
          row({'dj_payout_override': 6000}),
        ).djPayoutOverride,
        6000,
      );
      expect(DjQuoteModel.fromJson(row({})).djPayoutOverride, isNull);
    });

    test('uses dj_payout_override when set — NEVER the standard 71.5%', () {
      // Admin negotiated a worse deal for the DJ (6.000 < the 8.580 standard).
      // The DJ must only ever see 6.000 — leaking 8.580 would reveal the change.
      final q =
          DjQuoteModel.fromJson(row({'dj_payout_override': 6000})).toEntity();
      expect(q.hasPayoutOverride, true);
      expect(q.djPayout, 6000);
    });

    test('falls back to round(price_dkk * 0.715) when no override', () {
      final q = DjQuoteModel.fromJson(row({})).toEntity();
      expect(q.hasPayoutOverride, false);
      // Bare quote => placeholder job with unknown created_at => default (new) 0.715 rate, mirroring
      // web QuoteInfo's default-to-new. (Commission 28.5% on/after 2026-07-06.)
      expect(q.djPayout, 8580); // 12000 * 0.715
    });

    test('rounds the 71.5% payout like Math.round (half up)', () {
      final q = DjQuoteModel.fromJson(row({'price_dkk': 5001})).toEntity();
      expect(q.djPayout, 3576); // 5001 * 0.715 = 3575.715 -> 3576
    });
  });
}
