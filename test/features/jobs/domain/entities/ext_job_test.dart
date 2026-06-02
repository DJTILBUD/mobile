import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';

void main() {
  group('ExtJob.budgetDisplay — must mirror web app (honorar only)', () {
    ExtJob extJob({double? honorar, double? fullAmount, String? budgetTarget}) => ExtJob(
          id: 1,
          leadName: 'Test',
          date: DateTime(2026, 6, 1),
          status: ExtJobStatus.closed,
          createdAt: DateTime(2026, 5, 1),
          honorar: honorar,
          fullAmount: fullAmount,
          budgetTarget: budgetTarget,
        );

    test('shows the honorar when present', () {
      expect(extJob(honorar: 5000).budgetDisplay, '5.000 kr.');
    });

    test('NEVER falls back to full_amount (the customer total exposes the cut)', () {
      // honorar missing but full_amount/budget present → must NOT leak them.
      final display = extJob(fullAmount: 20000, budgetTarget: '15000-20000').budgetDisplay;
      expect(display, 'Ikke angivet');
      expect(display.contains('20'), false);
      expect(display.contains('15'), false);
    });

    test('honorar wins even when full_amount is also set', () {
      expect(extJob(honorar: 5000, fullAmount: 20000).budgetDisplay, '5.000 kr.');
    });
  });
}
