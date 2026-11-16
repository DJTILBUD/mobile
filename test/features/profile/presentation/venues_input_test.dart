import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/profile/presentation/widgets/venues_input.dart';

/// Hosts VenuesInput like the edit screen does: the parent owns the list + controller.
class _Host extends StatefulWidget {
  const _Host({required this.initial, required this.controller});
  final List<String> initial;
  final TextEditingController controller;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<String> venues = widget.initial;
  int saves = 0;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      VenuesInput(
        venues: venues,
        controller: widget.controller,
        onChanged:
            (v) => setState(() {
              venues = v;
              saves++;
            }),
      ),
      const TextField(key: Key('other')),
    ],
  );
}

Future<_HostState> _pump(
  WidgetTester tester, {
  List<String> initial = const [],
  TextEditingController? controller,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _Host(
          initial: initial,
          controller: controller ?? TextEditingController(),
        ),
      ),
    ),
  );
  return tester.state<_HostState>(find.byType(_Host));
}

void main() {
  testWidgets('Tilføj adds the typed name and clears the field', (
    tester,
  ) async {
    final host = await _pump(tester);
    await tester.enterText(find.byType(TextField).first, 'Vega');
    await tester.pump();
    await tester.tap(find.widgetWithText(DSButton, 'Tilføj'));
    await tester.pump();
    expect(host.venues, ['Vega']);
    expect(find.text('Vega'), findsOneWidget);
  });

  testWidgets('a comma adds every name before it and keeps the rest', (
    tester,
  ) async {
    final controller = TextEditingController();
    final host = await _pump(tester, controller: controller);
    await tester.enterText(find.byType(TextField).first, 'Vega, Tivoli, Dis');
    await tester.pump();
    expect(host.venues, ['Vega', 'Tivoli']);
    expect(controller.text, 'Dis');
  });

  testWidgets('the keyboard done action adds the name', (tester) async {
    final host = await _pump(tester);
    await tester.enterText(find.byType(TextField).first, 'Royal Arena');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(host.venues, ['Royal Arena']);
  });

  testWidgets('leaving the field adds what is typed (nothing is lost)', (
    tester,
  ) async {
    final host = await _pump(tester);
    await tester.enterText(find.byType(TextField).first, 'Tivoli');
    await tester.tap(find.byKey(const Key('other')));
    await tester.pump();
    expect(host.venues, ['Tivoli']);
  });

  testWidgets('a duplicate in another case is skipped', (tester) async {
    final host = await _pump(tester, initial: ['Vega']);
    await tester.enterText(find.byType(TextField).first, 'vega');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(host.venues, ['Vega']);
    expect(host.saves, 0);
  });

  testWidgets('deleting a chip removes only that venue', (tester) async {
    final host = await _pump(tester, initial: ['Vega', 'Tivoli']);
    final chip = find.widgetWithText(DSChip, 'Vega');
    await tester.tap(
      find.descendant(of: chip, matching: find.byType(GestureDetector)).last,
    );
    await tester.pump();
    expect(host.venues, ['Tivoli']);
  });
}
