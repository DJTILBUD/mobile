import 'package:dj_tilbud_app/app.dart';
import 'package:dj_tilbud_app/core/notifications/in_app_notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the global keyboard-dismiss bar reservation.
///
/// ⚠️ THE BUG THIS GUARDS. `_KeyboardDismissBar` is painted in the app-level Stack (above the
/// routed screen) at `bottom: viewInsets.bottom`. A Scaffold with the default
/// `resizeToAvoidBottomInset: true` shrinks to exactly `screen - keyboard` and scrolls the focused
/// field to the bottom of that area — precisely where the opaque bar sits. So every screen with a
/// text input had the bottom of its focused field hidden behind the bar (the last lines of a
/// sales pitch, the character counter, the buttons under it).
///
/// [ReserveKeyboardDismissBar] fixes it by inflating `viewInsets.bottom` for everything below, so
/// the Scaffold stops ABOVE the bar. These tests pin the two halves of that contract:
///   1. it reserves EXACTLY the bar's height when the bar is drawn, and
///   2. it reserves NOTHING when the bar is not drawn (a dead gap above the keyboard otherwise).
void main() {
  /// Pumps the reservation widget and returns (inset seen by the child, the bar's own height).
  Future<({double childInset, double barHeight})> pumpAndRead(
    WidgetTester tester, {
    required double keyboardHeight,
    required bool suppressed,
  }) async {
    late double childInset;
    late double barHeight;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          suppressKeyboardDismissBarProvider.overrideWith((ref) => suppressed),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: keyboardHeight),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ReserveKeyboardDismissBar(
              child: Builder(
                builder: (context) {
                  childInset = MediaQuery.of(context).viewInsets.bottom;
                  barHeight = keyboardDismissBarHeight(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );

    return (childInset: childInset, barHeight: barHeight);
  }

  testWidgets('reserves exactly the bar height while the keyboard is open', (
    tester,
  ) async {
    final r = await pumpAndRead(tester, keyboardHeight: 300, suppressed: false);

    // The child must believe the obstruction is keyboard + bar, so its Scaffold stops above the bar
    // instead of being overlapped by it.
    expect(r.childInset, 300 + r.barHeight);
    expect(r.barHeight, greaterThan(0));
  });

  testWidgets('reserves NOTHING when the keyboard is closed', (tester) async {
    final r = await pumpAndRead(tester, keyboardHeight: 0, suppressed: false);
    expect(r.childInset, 0);
  });

  // The chat screen suppresses the bar so its composer can sit directly on the keyboard. Reserving
  // for a bar that is never drawn would leave a dead strip above the keyboard on exactly that
  // screen, which is why the visibility condition is duplicated rather than assumed.
  testWidgets('reserves NOTHING when the bar is suppressed (chat screen)', (
    tester,
  ) async {
    final r = await pumpAndRead(tester, keyboardHeight: 300, suppressed: true);
    expect(r.childInset, 300);
  });

  testWidgets('a Scaffold below it lays its body out above the bar, not under it', (
    tester,
  ) async {
    const keyboard = 300.0;
    late double barHeight;
    final key = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          suppressKeyboardDismissBarProvider.overrideWith((ref) => false),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ReserveKeyboardDismissBar(
              child: Builder(
                builder: (context) {
                  barHeight = keyboardDismissBarHeight(context);
                  return MaterialApp(
                    home: Scaffold(
                      // The default (true) is the documented rule for Scaffold screens.
                      body: SizedBox.expand(
                        child: ColoredBox(color: Colors.red, key: key),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final bodyBottom = tester.getBottomLeft(find.byKey(key)).dy;

    // The bar occupies [800 - keyboard - barHeight, 800 - keyboard]. The body must end at or above
    // the TOP of that strip. Before the fix it ran to 800 - keyboard and the bar covered it.
    expect(bodyBottom, lessThanOrEqualTo(800 - keyboard - barHeight + 0.5));
  });
}
