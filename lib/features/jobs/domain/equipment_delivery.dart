/// WKNDS gear delivery on a non-equipped DJ's won internal job: the logistics the DJ collects
/// from the customer (contract §5.2 + §6.3) plus the fixed delivery facts.
///
/// Resolved SERVER-side by `GET/PUT /api/deliveries/job/{job_id}` (web
/// `api/_services/equipmentDeliveries/deliveries.ts` `toDjView`, rules in
/// `helpers/equipmentDelivery.ts`). Mobile never computes the missing fields, deadlines or gear
/// text itself: the `EquipmentDeliveries` table is service-role/admin only under RLS, and the
/// web-app is the source of truth. Plan: `web-app/documentation/non-equipped-djs-plan.md`,
/// "Opgave 4 og 5, v1".
library;

enum DeliveryStatus { booked, canceled }

/// `access`: how the gear gets in.
enum DeliveryAccess {
  ground('ground'),
  elevator('elevator'),
  stairs('stairs'),

  /// "Ved ikke": the DJ could not find out. Counts as answered; the stairs surcharge stays unknown.
  unknown('unknown');

  const DeliveryAccess(this.wire);
  final String wire;

  static DeliveryAccess? fromWire(Object? v) =>
      values.where((e) => e.wire == v).firstOrNull;
}

/// `setup_day`: when WKNDS sets up.
enum DeliverySetupDay {
  dayBefore('day_before'),
  sameDay('same_day');

  const DeliverySetupDay(this.wire);
  final String wire;

  static DeliverySetupDay? fromWire(Object? v) =>
      values.where((e) => e.wire == v).firstOrNull;
}

/// `teardown_day`: when WKNDS takes the gear down (contract: next day by default).
enum DeliveryTeardownDay {
  nextDay('next_day'),
  sameNight('same_night');

  const DeliveryTeardownDay(this.wire);
  final String wire;

  static DeliveryTeardownDay? fromWire(Object? v) =>
      values.where((e) => e.wire == v).firstOrNull;
}

/// Wire keys of the logistics, in the web's `DELIVERY_LOGISTICS_FIELDS` order.
const deliveryLogisticsKeys = <String>[
  'venue_address',
  'guests_amount',
  'access',
  'setup_day',
  'setup_window',
  'teardown_day',
  'teardown_window',
  'hard_deadline',
  'parking',
  'placement',
  'onsite_contact_name',
  'onsite_contact_phone',
  'notes',
  'collect_on',
];

/// Server-side max lengths (web route `LogisticsSchema`). The form caps the inputs with these.
const deliveryTextMaxLength = <String, int>{
  'venue_address': 300,
  'setup_window': 100,
  'teardown_window': 100,
  'hard_deadline': 100,
  'parking': 300,
  'placement': 300,
  'onsite_contact_name': 120,
  'onsite_contact_phone': 40,
  'notes': 1000,
};

/// Web route bound for `guests_amount`.
const deliveryMaxGuests = 5000;

String? _ymd(DateTime? d) {
  if (d == null) return null;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

DateTime? _parseDate(Object? v) =>
    v is String && v.length >= 10
        ? DateTime.tryParse(v.substring(0, 10))
        : null;

String? _text(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

class DeliveryLogistics {
  const DeliveryLogistics({
    this.venueAddress,
    this.guestsAmount,
    this.access,
    this.setupDay,
    this.setupWindow,
    this.teardownDay,
    this.teardownWindow,
    this.hardDeadline,
    this.parking,
    this.placement,
    this.onsiteContactName,
    this.onsiteContactPhone,
    this.notes,
    this.collectOn,
  });

  final String? venueAddress;
  final int? guestsAmount;
  final DeliveryAccess? access;
  final DeliverySetupDay? setupDay;
  final String? setupWindow;
  final DeliveryTeardownDay? teardownDay;
  final String? teardownWindow;
  final String? hardDeadline;
  final String? parking;
  final String? placement;
  final String? onsiteContactName;
  final String? onsiteContactPhone;
  final String? notes;

  /// "Jeg indhenter oplysningerne d. ...": the date the DJ will collect the info (date only).
  final DateTime? collectOn;

  factory DeliveryLogistics.fromJson(Map<String, dynamic> json) {
    return DeliveryLogistics(
      venueAddress: _text(json['venue_address']),
      guestsAmount: (json['guests_amount'] as num?)?.toInt(),
      access: DeliveryAccess.fromWire(json['access']),
      setupDay: DeliverySetupDay.fromWire(json['setup_day']),
      setupWindow: _text(json['setup_window']),
      teardownDay: DeliveryTeardownDay.fromWire(json['teardown_day']),
      teardownWindow: _text(json['teardown_window']),
      hardDeadline: _text(json['hard_deadline']),
      parking: _text(json['parking']),
      placement: _text(json['placement']),
      onsiteContactName: _text(json['onsite_contact_name']),
      onsiteContactPhone: _text(json['onsite_contact_phone']),
      notes: _text(json['notes']),
      collectOn: _parseDate(json['collect_on']),
    );
  }

  /// The PUT body shape. Blank text is sent as null (the route clears it either way).
  Map<String, dynamic> toJson() => {
    'venue_address': _text(venueAddress),
    'guests_amount': guestsAmount,
    'access': access?.wire,
    'setup_day': setupDay?.wire,
    'setup_window': _text(setupWindow),
    'teardown_day': teardownDay?.wire,
    'teardown_window': _text(teardownWindow),
    'hard_deadline': _text(hardDeadline),
    'parking': _text(parking),
    'placement': _text(placement),
    'onsite_contact_name': _text(onsiteContactName),
    'onsite_contact_phone': _text(onsiteContactPhone),
    'notes': _text(notes),
    'collect_on': _ymd(collectOn),
  };

  /// Only the keys whose value differs from [saved]. The route writes only sent keys, so sending
  /// the diff never overwrites a field someone else changed meanwhile (e.g. on the web).
  Map<String, dynamic> changesSince(DeliveryLogistics saved) {
    final mine = toJson();
    final theirs = saved.toJson();
    return {
      for (final key in deliveryLogisticsKeys)
        if (mine[key] != theirs[key]) key: mine[key],
    };
  }
}

/// Checks the typed guest count before a save (the route rejects a non-integer or out-of-range
/// value with a generic 400). Returns the Danish problem, or null when it is fine. Values, not
/// `Form.validate()`: the form sits in a lazy ListView (see mobile/CLAUDE.md).
String? validateDeliveryGuests(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final n = int.tryParse(t);
  if (n == null || n < 0 || n > deliveryMaxGuests) {
    return 'Antal gæster skal være et helt tal mellem 0 og $deliveryMaxGuests.';
  }
  return null;
}

class EquipmentDelivery {
  const EquipmentDelivery({
    required this.id,
    required this.status,
    required this.jobId,
    required this.logistics,
    this.eventDate,
    this.missing = const [],
    this.dueDate,
    this.gear = const [],
    this.subText = '',
    this.djBrings = '',
    this.checklist = const [],
  });

  final int id;
  final DeliveryStatus status;
  final int jobId;
  final DateTime? eventDate;
  final DeliveryLogistics logistics;

  /// Danish labels of the required info still missing. All of it is due by [dueDate]
  /// (4 working days before the event): one set, one deadline.
  final List<String> missing;
  final DateTime? dueDate;

  /// Everything required is filled in (or there is nothing left to deliver).
  bool get isInfoComplete => isCanceled || missing.isEmpty;

  /// What WKNDS delivers, e.g. "Pioneer XDJ-RX3".
  final List<String> gear;

  /// The speaker line, depends on the guest count.
  final String subText;

  /// What the DJ brings themselves.
  final String djBrings;

  /// Fixed DJ checklist (pult settings, FAT32 USB, arrive 30 min before).
  final List<String> checklist;

  bool get isCanceled => status == DeliveryStatus.canceled;

  static List<String> _strings(Object? v) =>
      v is List ? v.whereType<String>().toList() : const [];

  /// Null for `{delivery: null}` or an unknown status (renders nothing rather than guessing).
  static EquipmentDelivery? fromResponse(Map<String, dynamic> body) {
    final json = body['delivery'];
    if (json is! Map<String, dynamic>) return null;
    final status =
        DeliveryStatus.values
            .where((s) => s.name == json['status'])
            .firstOrNull;
    final id = (json['id'] as num?)?.toInt();
    final jobId = (json['jobId'] as num?)?.toInt();
    if (status == null || id == null || jobId == null) return null;
    final logistics = json['logistics'];
    return EquipmentDelivery(
      id: id,
      status: status,
      jobId: jobId,
      eventDate: _parseDate(json['eventDate']),
      logistics:
          logistics is Map<String, dynamic>
              ? DeliveryLogistics.fromJson(logistics)
              : const DeliveryLogistics(),
      missing: _strings(json['missing']),
      dueDate: _parseDate(json['dueDate']),
      gear: _strings(json['gear']),
      subText: json['subText'] as String? ?? '',
      djBrings: json['djBrings'] as String? ?? '',
      checklist: _strings(json['checklist']),
    );
  }
}

/// How urgent the DJ's delivery to-do is. Computed SERVER-side by `GET /api/deliveries/mine`
/// (web `helpers/equipmentDelivery.ts` `deliveryActionLevel`): urgent from 3 days before the
/// deadline (and after it) while info is missing, pending when the deadline is not close yet.
enum DeliveryActionLevel { urgent, pending }

/// One of the DJ's deliveries as the job list needs it (card action line, Jobs badge, red dot on
/// the job's Levering tab). Plan: `web-app/documentation/delivery-action-mobile-plan.md`.
class DeliveryActionSummary {
  const DeliveryActionSummary({
    required this.jobId,
    required this.level,
    required this.missing,
  });

  final int jobId;

  /// Null when nothing is needed from the DJ.
  final DeliveryActionLevel? level;
  final List<String> missing;

  bool get needsInfo => level != null;

  /// `{ deliveries: [...] }` -> jobId -> summary. Unknown/garbled rows are skipped.
  static Map<int, DeliveryActionSummary> mapFromResponse(
    Map<String, dynamic> body,
  ) {
    final list = body['deliveries'];
    if (list is! List) return const {};
    final out = <int, DeliveryActionSummary>{};
    for (final raw in list) {
      if (raw is! Map<String, dynamic>) continue;
      final jobId = (raw['jobId'] as num?)?.toInt();
      if (jobId == null) continue;
      List<String> strings(Object? v) =>
          v is List ? v.whereType<String>().toList() : const [];
      out[jobId] = DeliveryActionSummary(
        jobId: jobId,
        level:
            DeliveryActionLevel.values
                .where((l) => l.name == raw['actionLevel'])
                .firstOrNull,
        missing: strings(raw['missing']),
      );
    }
    return out;
  }
}
