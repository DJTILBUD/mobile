import 'package:dj_tilbud_app/core/utils/planned_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 7, 11, 7);

  group('isPlannedContactDue', () {
    test('null planned date is never due', () {
      expect(isPlannedContactDue(null, now: now), isFalse);
    });

    test('a future day is not due', () {
      expect(isPlannedContactDue(DateTime(2026, 9, 8), now: now), isFalse);
      expect(
        isPlannedContactDue(
          DateTime(2026, 8, 26).add(const Duration(days: 365)),
          now: now,
        ),
        isFalse,
      );
    });

    test('today is due even when the stored time is later than now', () {
      expect(
        isPlannedContactDue(DateTime(2026, 9, 7, 23, 59), now: now),
        isTrue,
      );
      expect(isPlannedContactDue(DateTime(2026, 9, 7), now: now), isTrue);
    });

    test('a past day is due', () {
      expect(isPlannedContactDue(DateTime(2026, 8, 26), now: now), isTrue);
    });
  });
}
