import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/core/utils/birthday_person_age.dart';

// Mirror of web `useFormatBirthdayPersonAge` — keep the cases in step.
void main() {
  test('digits get the " år" suffix', () {
    expect(formatBirthdayPersonAge('50'), ', 50 år');
    expect(formatBirthdayPersonAge(' 18 '), ', 18 år');
  });

  test('free text is printed verbatim, never suffixed', () {
    // lead forms are free text — "halvtreds år" would read wrong.
    expect(formatBirthdayPersonAge('halvtreds'), ', halvtreds');
    expect(formatBirthdayPersonAge('50-års'), ', 50-års');
  });

  test(
    'nothing to show yields an empty suffix so call sites can concatenate',
    () {
      expect(formatBirthdayPersonAge(null), '');
      expect(formatBirthdayPersonAge(''), '');
      expect(formatBirthdayPersonAge('   '), '');
    },
  );
}
