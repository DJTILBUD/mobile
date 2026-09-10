import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The DJ's complaint after the 1.0.37 keyboard work: "the keyboard takes up the space where the
/// user is writing". A `minLines: 8` textarea ("Salgstale", 450 characters, minimum 100) came to
/// rest with ~50px of itself above the keyboard, so it was written through a one-line slot at the
/// bottom edge of the screen.
///
/// Cause: the framework scrolls a focused field only far enough to reveal the CARET plus
/// `scrollPadding` (default 20). On a tall field the caret is line 1, so the other seven lines
/// stay below the fold. [DSInput] now reserves roughly the field's own height below the caret.
void main() {
  const keyboard = 340.0;
  const screen = Size(400, 800);
  final visibleBottom = screen.height - keyboard; // 460

  Future<Rect> pumpAndTapField(
    WidgetTester tester, {
    required int minLines,
  }) async {
    // The surface, not just a MediaQuery, or the tree lays out at the default 800x600 and the
    // tap lands in dead space below the shrunken Scaffold.
    await tester.binding.setSurfaceSize(screen);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(() async {
      tester.view.reset();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Leaves the field peeking just above the keyboard, exactly like the reported
                // screenshot: the equipment pickers sit above the sales pitch on the quote form.
                const SizedBox(height: 420),
                DSInput(
                  hint: 'Fortæl kunden hvorfor du er det rette valg...',
                  minLines: minLines,
                  maxLines: 15,
                ),
                const SizedBox(height: 400),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ⚠️ Must be a TAP on the sliver of the field that is visible, not `requestFocus()`.
    // Programmatic focus goes through the traversal path, which reveals the WHOLE field and
    // hides the bug; a tap only runs EditableText's `_showCaretOnScreen`, which reveals the
    // caret plus `scrollPadding` and nothing more. That difference IS the bug.
    await tester.tapAt(const Offset(200, 440));
    await tester.pumpAndSettle();

    return tester.getRect(find.byType(TextFormField));
  }

  testWidgets('a tall field is scrolled clear of the keyboard when tapped', (
    tester,
  ) async {
    final rect = await pumpAndTapField(tester, minLines: 8);

    expect(
      rect.bottom,
      lessThanOrEqualTo(visibleBottom + 1),
      reason:
          'the textarea still runs under the keyboard — the DJ writes a 450-character sales '
          'pitch through a slot (${rect.height.toStringAsFixed(0)}px field, only '
          '${(visibleBottom - rect.top).toStringAsFixed(0)}px of it visible)',
    );
  });

  testWidgets('a single-line field is not hoisted up the screen', (
    tester,
  ) async {
    final rect = await pumpAndTapField(tester, minLines: 1);

    // Visible, but not yanked to the top: a short field already fits, so over-reserving would
    // only leave dead space above the keyboard.
    expect(rect.bottom, lessThanOrEqualTo(visibleBottom + 1));
    expect(rect.bottom, greaterThan(visibleBottom - 150));
  });
}
