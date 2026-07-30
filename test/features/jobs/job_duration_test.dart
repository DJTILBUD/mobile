import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/jobs/domain/job_duration.dart';

/// Mirror of `web-app/src/helpers/jobDurationHours.test.ts`. The two implementations must agree
/// exactly, or a job shows in the mobile feed but not the web feed (or vice versa) for the same DJ.
void main() {
  group('jobDurationHours', () {
    test('same-evening job', () {
      expect(jobDurationHours('18:00:00', '23:00:00'), 5);
    });

    test('job running past midnight is positive, not negative', () {
      // The real shape of a DJ booking (job 427: 21:00 -> 02:00).
      expect(jobDurationHours('21:00:00', '02:00:00'), 5);
    });

    test('past-midnight job with fractional end', () {
      expect(jobDurationHours('21:00:00', '02:30:00'), 5.5);
    });

    test('ending exactly at midnight', () {
      expect(jobDurationHours('20:00:00', '00:00:00'), 4);
    });

    test('starting at midnight', () {
      expect(jobDurationHours('00:00:00', '04:00:00'), 4);
    });

    test('equal times read as a full day rather than zero', () {
      expect(jobDurationHours('22:00:00', '22:00:00'), 24);
    });

    test('accepts HH:MM without seconds', () {
      expect(jobDurationHours('21:00', '01:00'), 4);
    });

    test('half-hour boundaries', () {
      expect(jobDurationHours('19:30:00', '23:45:00'), 4.25);
    });

    test(
      'null / empty / malformed input yields null, never a bogus number',
      () {
        expect(jobDurationHours(null, '02:00:00'), isNull);
        expect(jobDurationHours('21:00:00', null), isNull);
        expect(jobDurationHours(null, null), isNull);
        expect(jobDurationHours('', ''), isNull);
        expect(jobDurationHours('ikke oplyst', '02:00:00'), isNull);
        expect(jobDurationHours('25:00:00', '02:00:00'), isNull);
        expect(jobDurationHours('21:70:00', '02:00:00'), isNull);
      },
    );
  });

  group('formatJobDuration', () {
    test('whole hours have no decimal', () {
      expect(formatJobDuration(5), '5 timer');
    });

    test('singular', () {
      expect(formatJobDuration(1), '1 time');
    });

    test('fractional uses a Danish decimal comma', () {
      expect(formatJobDuration(5.5), '5,5 timer');
    });

    test('nothing to show for null or nonsense', () {
      expect(formatJobDuration(null), isNull);
      expect(formatJobDuration(0), isNull);
      expect(formatJobDuration(-3), isNull);
    });
  });
}
