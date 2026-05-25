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

    test('parses a bare quote with no `job` key, falling back to a placeholder',
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
    });

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
}
