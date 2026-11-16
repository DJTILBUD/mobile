import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/jobs/domain/equipment_delivery.dart';

/// Shape of web `toDjView` (api/_services/equipmentDeliveries/deliveries.ts).
Map<String, dynamic> _body({
  String status = 'booked',
  Map<String, dynamic>? logistics,
}) => {
  'delivery': {
    'id': 12,
    'status': status,
    'jobId': 3400,
    'eventDate': '2026-11-14',
    'logistics':
        logistics ??
        {
          'venue_address': 'Festvej 1, 2100 København Ø',
          'guests_amount': 90,
          'access': 'stairs',
          'setup_day': 'day_before',
          'setup_window': '14.00-16.00',
          'teardown_day': 'next_day',
          'teardown_window': null,
          'hard_deadline': '',
          'parking': 'Gården',
          'placement': null,
          'onsite_contact_name': null,
          'onsite_contact_phone': null,
          'notes': null,
          'collect_on': '2026-11-01',
        },
    'missing': ['kontaktperson', 'kontaktpersonens telefon', 'placering'],
    'dueDate': '2026-11-10',
    'gear': ['Pioneer XDJ-RX3', 'Festlys'],
    'subText': '2 x top, 1-2 x bund (under 120 gæster)',
    'djBrings': 'USB-stik og hovedtelefoner',
    'checklist': ['Mød op 30 min før'],
  },
};

void main() {
  group('EquipmentDelivery.fromResponse', () {
    test('null delivery renders nothing', () {
      expect(EquipmentDelivery.fromResponse({'delivery': null}), isNull);
      expect(EquipmentDelivery.fromResponse({}), isNull);
    });

    test('unknown status renders nothing rather than guessing', () {
      expect(EquipmentDelivery.fromResponse(_body(status: 'weird')), isNull);
    });

    test('parses the full DJ view', () {
      final d = EquipmentDelivery.fromResponse(_body())!;
      expect(d.id, 12);
      expect(d.jobId, 3400);
      expect(d.status, DeliveryStatus.booked);
      expect(d.isCanceled, isFalse);
      expect(d.eventDate, DateTime(2026, 11, 14));
      expect(d.dueDate, DateTime(2026, 11, 10));
      expect(d.missing, hasLength(3));
      expect(d.isInfoComplete, isFalse);
      expect(d.gear, ['Pioneer XDJ-RX3', 'Festlys']);
      expect(d.subText, contains('under 120'));
      expect(d.djBrings, 'USB-stik og hovedtelefoner');
      expect(d.checklist, ['Mød op 30 min før']);

      final l = d.logistics;
      expect(l.venueAddress, 'Festvej 1, 2100 København Ø');
      expect(l.guestsAmount, 90);
      expect(l.access, DeliveryAccess.stairs);
      expect(l.setupDay, DeliverySetupDay.dayBefore);
      expect(l.teardownDay, DeliveryTeardownDay.nextDay);
      expect(l.hardDeadline, isNull, reason: 'blank text reads as unset');
      expect(l.collectOn, DateTime(2026, 11, 1));
    });

    test('canceled status', () {
      final d = EquipmentDelivery.fromResponse(_body(status: 'canceled'))!;
      expect(d.isCanceled, isTrue);
    });

    test('missing logistics map yields empty logistics', () {
      final body = _body();
      (body['delivery'] as Map<String, dynamic>).remove('logistics');
      final d = EquipmentDelivery.fromResponse(body)!;
      expect(d.logistics.toJson().values.every((v) => v == null), isTrue);
    });
  });

  group('DeliveryLogistics', () {
    test('toJson uses wire keys and values', () {
      final json = EquipmentDelivery.fromResponse(_body())!.logistics.toJson();
      expect(json.keys.toList(), deliveryLogisticsKeys);
      expect(json['access'], 'stairs');
      expect(json['setup_day'], 'day_before');
      expect(json['teardown_day'], 'next_day');
      expect(json['collect_on'], '2026-11-01');
      expect(json['guests_amount'], 90);
    });

    test('changesSince sends only changed keys, blank as null', () {
      final saved = EquipmentDelivery.fromResponse(_body())!.logistics;
      final edited = DeliveryLogistics(
        venueAddress: 'Festvej 1, 2100 København Ø',
        guestsAmount: 130,
        access: DeliveryAccess.elevator,
        setupDay: DeliverySetupDay.dayBefore,
        setupWindow: '14.00-16.00',
        teardownDay: DeliveryTeardownDay.nextDay,
        hardDeadline: '   ',
        parking: '',
        placement: 'Ved scenen',
        collectOn: DateTime(2026, 11, 1),
      );
      expect(edited.changesSince(saved), {
        'guests_amount': 130,
        'access': 'elevator',
        'parking': null,
        'placement': 'Ved scenen',
      });
    });

    test('no edits means no changes', () {
      final saved = EquipmentDelivery.fromResponse(_body())!.logistics;
      expect(saved.changesSince(saved), isEmpty);
    });
  });

  group('validateDeliveryGuests', () {
    test('empty and in-range are fine', () {
      expect(validateDeliveryGuests(''), isNull);
      expect(validateDeliveryGuests(' 120 '), isNull);
      expect(validateDeliveryGuests('0'), isNull);
      expect(validateDeliveryGuests('5000'), isNull);
    });

    test('non-integer or out of range is rejected', () {
      expect(validateDeliveryGuests('abc'), isNotNull);
      expect(validateDeliveryGuests('12.5'), isNotNull);
      expect(validateDeliveryGuests('5001'), isNotNull);
    });
  });
}
