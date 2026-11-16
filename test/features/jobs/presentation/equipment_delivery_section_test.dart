import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/equipment_delivery.dart';
import 'package:dj_tilbud_app/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/equipment_delivery_section.dart';

/// Render tests for "Levering af udstyr": it must lay out inside a lazy ListView (like the quote
/// detail's won body), hide itself without a delivery, enable "Gem" only after an edit, and be
/// read-only once cancelled.
EquipmentDelivery _delivery({DeliveryStatus status = DeliveryStatus.booked}) =>
    EquipmentDelivery(
      id: 1,
      status: status,
      jobId: 77,
      eventDate: DateTime(2026, 11, 14),
      logistics: const DeliveryLogistics(guestsAmount: 80),
      missing: const ['adresse', 'parkering', 'kontaktperson'],
      dueDate: DateTime(2026, 11, 10),
      gear: const ['Pioneer XDJ-RX3'],
      subText: '2 x top, 1-2 x bund (under 120 gæster)',
      djBrings: 'USB-stik og hovedtelefoner',
      checklist: const ['Mød op 30 min før'],
    );

class _FakeRepo extends Fake implements JobsRepository {
  _FakeRepo(this.delivery);
  EquipmentDelivery? delivery;
  Map<String, dynamic>? saved;

  @override
  Future<EquipmentDelivery?> fetchEquipmentDelivery(int jobId) async =>
      delivery;

  @override
  Future<EquipmentDelivery?> saveEquipmentDeliveryLogistics(
    int jobId,
    Map<String, dynamic> changes,
  ) async {
    saved = changes;
    return delivery;
  }
}

Widget _harness(_FakeRepo repo) => ProviderScope(
  overrides: [jobsRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    home: Scaffold(
      body: ListView(children: const [EquipmentDeliverySection(jobId: 77)]),
    ),
  ),
);

DSButton? _saveButton(WidgetTester tester) {
  final finder = find.widgetWithText(DSButton, 'Gem');
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<DSButton>(finder);
}

void main() {
  setUpAll(() => initializeDateFormatting('da_DK'));

  testWidgets('renders nothing without a delivery', (tester) async {
    await tester.pumpWidget(_harness(_FakeRepo(null)));
    await tester.pumpAndSettle();
    expect(find.text('Leveringsdetaljer'), findsNothing);
  });

  testWidgets('booked: status, missing deadlines, Gem enables after edit', (
    tester,
  ) async {
    final repo = _FakeRepo(_delivery());
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    expect(find.text('Leveringsdetaljer'), findsOneWidget);
    expect(
      find.text('Udfyld senest tirsdag 10. november'),
      findsOneWidget,
    );
    expect(find.text('senest tirs. 10. nov.'), findsOneWidget);
    expect(find.text('På dagen'), findsNothing, reason: 'one set of details, one deadline');
    expect(find.textContaining('leveringspartneren'), findsNothing);
    expect(_saveButton(tester)!.onTap, isNull, reason: 'nothing changed yet');

    await tester.ensureVisible(find.text('Elevator'));
    await tester.pump();
    await tester.tap(find.text('Elevator'));
    await tester.pump();
    expect(_saveButton(tester)!.onTap, isNotNull);

    // Tapping the selected chip again clears it, back to the saved state.
    await tester.ensureVisible(find.text('Elevator'));
    await tester.pump();
    await tester.tap(find.text('Elevator'));
    await tester.pump();
    expect(_saveButton(tester)!.onTap, isNull);

    // Saving sends only the changed key.
    await tester.ensureVisible(find.text('Stueplan'));
    await tester.pump();
    await tester.tap(find.text('Stueplan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Gem'));
    await tester.pump();
    await tester.tap(find.text('Gem'));
    await tester.pumpAndSettle();
    expect(repo.saved, {'access': 'ground'});
  });

  testWidgets('canceled: read-only, no Gem button', (tester) async {
    await tester.pumpWidget(
      _harness(_FakeRepo(_delivery(status: DeliveryStatus.canceled))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leveringen er aflyst'), findsOneWidget);
    expect(find.textContaining('enest'), findsNothing);
    await tester.ensureVisible(find.text('Udstyr og tjekliste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Udstyr og tjekliste'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Mød op 30 min før'));
    await tester.pump();
    expect(find.textContaining('Mød op 30 min før'), findsOneWidget);
    expect(_saveButton(tester), isNull);
  });
}
