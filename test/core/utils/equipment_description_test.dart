import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/core/utils/equipment_description.dart';

/// Mirrors the sub-range cases in web-app `wkndsDelivery.test.ts`.
void main() {
  group('bund_min (WKNDS delivery: 1-2 x bund)', () {
    test('round-trips and renders as a range', () {
      final raw = serializeEquipmentDescription(
        const ['Pult', 'Højtalere', 'Festlys'],
        2,
        2,
        1,
      );
      final parsed = parseEquipmentDescription(raw);
      expect(parsed.bottomSpeakerMin, 1);
      expect(parsed.bottomSpeakerLabel, '1-2');
      expect(getEquipmentDisplayItems(raw), [
        'Pult',
        'Højtalere (Top x2, Bund x1-2)',
        'Festlys',
      ]);
    });

    test('reads the exact string the web quote route stores', () {
      // web WKNDS_EQUIPMENT_DESCRIPTION
      const raw =
          '{"v":1,"gear":[{"key":"pult","qty":1},{"key":"hoejtalere","top":2,"bund":2,"bund_min":1},{"key":"festlys","qty":1}]}';
      expect(parseEquipmentDescription(raw).bottomSpeakerLabel, '1-2');
    });

    test('an ordinary quote keeps a single number', () {
      final raw = serializeEquipmentDescription(const ['Højtalere'], 2, 2);
      expect(raw.contains('bund_min'), isFalse);
      expect(parseEquipmentDescription(raw).bottomSpeakerLabel, '2');
    });
  });
}
