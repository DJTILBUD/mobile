import 'dart:convert';

// Exact port of web-app/src/helpers/equipmentDescription.ts

const equipmentOptions = [
  'Pult',
  'Højtalere',
  'Festlys',
  'Røgmaskine',
  'Uplight',
  'Mikrofon',
  'Diskokugle',
];

const _labelToKey = {
  'Pult': 'pult',
  'Højtalere': 'hoejtalere',
  'Festlys': 'festlys',
  'Røgmaskine': 'roegmaskine',
  'Uplight': 'uplight',
  'Mikrofon': 'mikrofon',
  'Diskokugle': 'diskokugle',
};

const _keyToLabel = {
  'pult': 'Pult',
  'hoejtalere': 'Højtalere',
  'festlys': 'Festlys',
  'roegmaskine': 'Røgmaskine',
  'uplight': 'Uplight',
  'mikrofon': 'Mikrofon',
  'diskokugle': 'Diskokugle',
};

const _legacyAliasToLabel = {
  'pult': 'Pult',
  'dj pult': 'Pult',
  'højtalere': 'Højtalere',
  'hoejtalere': 'Højtalere',
  'speakers': 'Højtalere',
  'speaker': 'Højtalere',
  'festlys': 'Festlys',
  'røgmaskine': 'Røgmaskine',
  'roegmaskine': 'Røgmaskine',
  'uplight': 'Uplight',
  'mikrofon': 'Mikrofon',
  'microphone': 'Mikrofon',
  'diskokugle': 'Diskokugle',
};

class ParsedEquipmentState {
  const ParsedEquipmentState({
    required this.selectedEquipment,
    required this.topSpeakerCount,
    required this.bottomSpeakerCount,
  });

  final List<String> selectedEquipment;
  final int topSpeakerCount;
  final int bottomSpeakerCount;

  static const empty = ParsedEquipmentState(
    selectedEquipment: [],
    topSpeakerCount: 2,
    bottomSpeakerCount: 2,
  );
}

int _nonNeg(dynamic value, int fallback) {
  if (value is num && value.isFinite) return value.round().clamp(0, 999);
  return fallback;
}

bool _isStructured(dynamic value) {
  if (value is! Map) return false;
  if (value['v'] != 1) return false;
  final gear = value['gear'];
  if (gear is! List) return false;
  return gear.every((item) => item is Map && _keyToLabel.containsKey(item['key']));
}

ParsedEquipmentState? _parseStructured(String raw) {
  try {
    final parsed = jsonDecode(raw);
    if (!_isStructured(parsed)) return null;

    final gear = parsed['gear'] as List<dynamic>;

    bool includesGear(String label) {
      final key = _labelToKey[label]!;
      final item = gear.cast<Map?>().firstWhere(
            (g) => g?['key'] == key,
            orElse: () => null,
          );
      if (item == null) return false;
      if (key == 'hoejtalere') {
        if (item['top'] == null && item['bund'] == null) {
          return _nonNeg(item['qty'], 1) > 0;
        }
        return _nonNeg(item['top'], 0) + _nonNeg(item['bund'], 0) > 0;
      }
      return _nonNeg(item['qty'], 1) > 0;
    }

    final selected = equipmentOptions.where(includesGear).toList();
    final speakers = gear.cast<Map?>().firstWhere(
          (g) => g?['key'] == 'hoejtalere',
          orElse: () => null,
        );
    final top = _nonNeg(speakers?['top'], 2);
    final bund = _nonNeg(speakers?['bund'], 2);

    return ParsedEquipmentState(
      selectedEquipment: selected,
      topSpeakerCount: top,
      bottomSpeakerCount: bund,
    );
  } catch (_) {
    return null;
  }
}

ParsedEquipmentState _parseLegacy(String raw) {
  final lowered = raw.toLowerCase();
  final selected = <String>{};
  _legacyAliasToLabel.forEach((alias, label) {
    if (lowered.contains(alias)) selected.add(label);
  });
  return ParsedEquipmentState(
    selectedEquipment: equipmentOptions.where(selected.contains).toList(),
    topSpeakerCount: 2,
    bottomSpeakerCount: 2,
  );
}

/// Returns null if the string is empty/null.
ParsedEquipmentState? parseStructuredEquipmentDescription(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return _parseStructured(raw);
}

/// Always returns a state — falls back to legacy parsing for old free-text quotes.
ParsedEquipmentState parseEquipmentDescription(String? raw) {
  if (raw == null || raw.trim().isEmpty) return ParsedEquipmentState.empty;
  final structured = _parseStructured(raw);
  if (structured != null) return structured;
  return _parseLegacy(raw);
}

/// Serializes to the v1 JSON format the web app expects.
String serializeEquipmentDescription(
  List<String> selectedEquipment,
  int topSpeakerCount,
  int bottomSpeakerCount,
) {
  final gear = selectedEquipment.map((label) {
    final key = _labelToKey[label]!;
    if (key == 'hoejtalere') {
      return {'key': key, 'top': topSpeakerCount.clamp(0, 99), 'bund': bottomSpeakerCount.clamp(0, 99)};
    }
    return {'key': key, 'qty': 1};
  }).toList();

  return jsonEncode({'v': 1, 'gear': gear});
}

/// Returns a human-readable list of equipment items for display.
List<String> getEquipmentDisplayItems(String? raw) {
  final parsed = parseStructuredEquipmentDescription(raw);

  if (parsed != null && parsed.selectedEquipment.isEmpty) return ['Intet udstyr'];

  if (parsed == null) {
    if (raw == null || raw.trim().isEmpty) return [];
    return [raw.trim()];
  }

  return parsed.selectedEquipment.map((label) {
    if (label == 'Højtalere') {
      final parts = [
        if (parsed.topSpeakerCount > 0) 'Top x${parsed.topSpeakerCount}',
        if (parsed.bottomSpeakerCount > 0) 'Bund x${parsed.bottomSpeakerCount}',
      ];
      return parts.isNotEmpty ? 'Højtalere (${parts.join(', ')})' : 'Højtalere';
    }
    return label;
  }).toList();
}
