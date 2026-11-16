import 'package:dj_tilbud_app/features/jobs/domain/equipment_delivery.dart';
import 'package:flutter_test/flutter_test.dart';

// Parsing of GET /api/deliveries/mine (web route src/app/api/deliveries/mine/route.ts). The level
// is decided by the web-app; the app only maps it.
void main() {
  test('maps each delivery to its job id and level', () {
    final map = DeliveryActionSummary.mapFromResponse({
      'deliveries': [
        {
          'jobId': 10,
          'actionLevel': 'urgent',
          'missing': ['Adresse'],
        },
        {
          'jobId': 11,
          'actionLevel': 'pending',
          'missing': ['Kontaktperson'],
        },
        {
          'jobId': 12,
          'actionLevel': null,
          'missing': [],
        },
      ],
    });
    expect(map[10]!.level, DeliveryActionLevel.urgent);
    expect(map[10]!.missing, ['Adresse']);
    expect(map[11]!.level, DeliveryActionLevel.pending);
    expect(map[12]!.level, isNull);
    expect(map[12]!.needsInfo, isFalse);
  });

  test('skips garbled rows and survives a missing list', () {
    expect(DeliveryActionSummary.mapFromResponse({}), isEmpty);
    final map = DeliveryActionSummary.mapFromResponse({
      'deliveries': [
        'nonsense',
        {'actionLevel': 'urgent'},
        {'jobId': 5, 'actionLevel': 'something-new'},
      ],
    });
    expect(map.keys, [5]);
    expect(map[5]!.level, isNull);
  });
}
