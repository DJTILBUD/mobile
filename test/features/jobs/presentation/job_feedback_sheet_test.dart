import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/jobs/domain/job_feedback.dart';
import 'package:dj_tilbud_app/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/job_feedback_sheet.dart';

/// "Hvorfor bød du ikke?": a chip answers and closes, "Spring over" sends nothing, "Andet" opens
/// the optional note.
class _FakeRepo extends Fake implements JobsRepository {
  _FakeRepo({this.fail = false});
  final bool fail;
  final List<Map<String, dynamic>> posted = [];
  final List<int> jobIds = [];

  @override
  Future<void> submitJobFeedback(int jobId, JobFeedbackAnswer answer) async {
    jobIds.add(jobId);
    posted.add(answer.toJson());
    if (fail) throw Exception('409 not_allowed');
  }
}

Widget _harness(_FakeRepo repo) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder:
          (context) => Center(
            child: TextButton(
              onPressed:
                  () => showJobFeedbackSheet(
                    context,
                    repository: repo,
                    jobId: 42,
                  ),
              child: const Text('open'),
            ),
          ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, _FakeRepo repo) async {
  await tester.pumpWidget(_harness(repo));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.text('Hjælp os med at sende dig de rigtige jobs'), findsOneWidget);
  expect(find.text('Hvorfor bød du ikke på dette job?'), findsOneWidget);
}

void main() {
  testWidgets('a chip tap posts that reason and closes the sheet', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _open(tester, repo);

    await tester.tap(find.text('For langt væk'));
    await tester.pumpAndSettle();

    expect(repo.jobIds, [42]);
    expect(repo.posted.single, {
      'reasons': ['For langt væk'],
    });
    expect(find.text('Hjælp os med at sende dig de rigtige jobs'), findsNothing);
    expect(find.text('Tak, det hjælper os'), findsOneWidget);
  });

  testWidgets('Spring over posts nothing', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo);

    await tester.tap(find.text('Spring over'));
    await tester.pumpAndSettle();

    expect(repo.posted, isEmpty);
    expect(find.text('Hjælp os med at sende dig de rigtige jobs'), findsNothing);
    expect(find.text('Tak, det hjælper os'), findsNothing);
  });

  testWidgets('Andet shows the note field and sends it on Send', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    expect(find.byKey(const ValueKey('job-feedback-note')), findsNothing);

    await tester.tap(find.text('Andet'));
    await tester.pumpAndSettle();
    expect(repo.posted, isEmpty, reason: 'Andet must not send on its own');
    expect(find.byKey(const ValueKey('job-feedback-note')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Forkert genre');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(repo.jobIds, [42]);
    expect(repo.posted.single, {
      'reasons': ['Andet'],
      'note': 'Forkert genre',
    });
  });

  testWidgets('tapping outside the sheet skips and posts nothing', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(repo.posted, isEmpty);
    expect(find.text('Hjælp os med at sende dig de rigtige jobs'), findsNothing);
  });

  testWidgets('a failed POST closes quietly with no error', (tester) async {
    final repo = _FakeRepo(fail: true);
    await _open(tester, repo);
    await tester.tap(find.text('For lavt budget'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Hjælp os med at sende dig de rigtige jobs'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
