import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';

Job _job({
  String region = 'Østjylland',
  String? postalCode,
  String city = '',
}) => Job(
  id: 1,
  eventType: 'Bryllup',
  date: DateTime(2026, 9, 26),
  timeStart: '20:00',
  timeEnd: '01:00',
  city: city,
  region: region,
  guestsAmount: 100,
  status: JobStatus.closed,
  createdAt: DateTime(2026, 8, 1),
  postalCode: postalCode,
);

/// The one location line shared by the new-job, quote and service-offer cards.
/// The won cards used to show the region only, so the postal code vanished once
/// a job was won.
void main() {
  group('Job.cardLocationLabel', () {
    test('region, postal code and place', () {
      expect(
        _job(postalCode: '8600', city: 'Silkeborg').cardLocationLabel,
        'Østjylland, 8600, Silkeborg',
      );
    });

    test('keeps the postal code when there is no place', () {
      expect(_job(postalCode: ' 8600 ').cardLocationLabel, 'Østjylland, 8600');
    });

    test('drops a blank postal code', () {
      expect(
        _job(postalCode: '  ', city: 'Silkeborg').cardLocationLabel,
        'Østjylland, Silkeborg',
      );
    });

    test('falls back when nothing is known', () {
      expect(_job(region: '').cardLocationLabel, 'Lokation ikke angivet');
    });
  });
}
