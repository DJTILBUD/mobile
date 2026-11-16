import 'package:dj_tilbud_app/features/jobs/domain/job_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the Dart mirror of web-app `src/helpers/jobFeedback.ts`. Change both together.
void main() {
  test('reasons match the web list exactly and in order', () {
    expect(jobFeedbackReasons, [
      'For lavt budget',
      'For langt væk',
      'Optaget den dag',
      'Ikke min type event',
      'Jobbet var fyldt op',
      'Andet',
    ]);
    expect(jobFeedbackReasons.last, jobFeedbackOtherReason);
  });

  test('cooldown is 7 days and the note cap is 300', () {
    expect(jobFeedbackCooldownDays, 7);
    expect(jobFeedbackNoteMaxLength, 300);
  });

  group('JobFeedbackPrompt.fromJson', () {
    test('uses the server reasons when present', () {
      final p = JobFeedbackPrompt.fromJson({
        'can_ask': true,
        'reasons': ['A', 'Andet'],
      });
      expect(p.canAsk, isTrue);
      expect(p.reasons, ['A', 'Andet']);
    });

    test('falls back to the mirror list and fails closed', () {
      final p = JobFeedbackPrompt.fromJson({'reasons': 'nope'});
      expect(p.canAsk, isFalse);
      expect(p.reasons, jobFeedbackReasons);
      expect(JobFeedbackPrompt.fromJson({'can_ask': 'true'}).canAsk, isFalse);
    });
  });

  group('JobFeedbackAnswer.toJson', () {
    test('drops an empty note and trims a real one', () {
      expect(const JobFeedbackAnswer(reasons: ['Andet'], note: '  ').toJson(), {
        'reasons': ['Andet'],
      });
      expect(
        const JobFeedbackAnswer(reasons: ['Andet'], note: ' for sent ').toJson(),
        {
          'reasons': ['Andet'],
          'note': 'for sent',
        },
      );
    });
  });
}
