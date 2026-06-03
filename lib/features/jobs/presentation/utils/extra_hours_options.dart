import 'package:dj_tilbud_app/core/design_system/components.dart';

/// Selectable extra-hours values, mirroring the web app's `timeOptions`
/// (`AddExtraHours.tsx` / `AddExtExtraHours.tsx`): 0.25-hour steps from
/// 1 kvarter up to 10 timer. Multiples of 0.25 are exactly representable as
/// doubles, so they match dropdown values without precision drift.
final List<DSDropdownItem<double>> extraHoursOptions = List.generate(
  40,
  (i) {
    final value = (i + 1) * 0.25;
    return DSDropdownItem<double>(value: value, label: extraHoursLabel(value));
  },
);

/// Danish label for an extra-hours value, matching the web wording exactly
/// (e.g. 0.25 → "1 kvarter", 1.5 → "1 time 1 halv time", 2 → "2 timer").
String extraHoursLabel(double value) {
  final whole = value.floor();
  final frac = value - whole;

  String fractionLabel(double f) {
    if (f == 0.25) return '1 kvarter';
    if (f == 0.5) return '1 halv time';
    if (f == 0.75) return '3 kvarter';
    return '';
  }

  if (whole == 0) return fractionLabel(frac);

  final wholeLabel = '$whole ${whole == 1 ? 'time' : 'timer'}';
  if (frac == 0) return wholeLabel;
  return '$wholeLabel ${fractionLabel(frac)}';
}

/// The selected value to pre-fill a dropdown with: the stored value only when
/// it's one of [extraHoursOptions] (legacy free-text entries that aren't a
/// 0.25 multiple fall back to null so the dropdown doesn't assert).
double? extraHoursSelectedValue(double? stored) {
  if (stored == null) return null;
  for (final item in extraHoursOptions) {
    if (item.value == stored) return stored;
  }
  return null;
}
