/// Job length in hours, derived from `Jobs.time_start` / `Jobs.time_end`.
///
/// **Byte-for-byte mirror of `web-app/src/helpers/jobDurationHours.ts` — change both together.**
/// The web app is the source of truth; this exists only so the mobile feed's instant
/// "Filtre til/fra" toggle can re-apply the same rule client-side without a round trip.
///
/// THE TRAP: DJ gigs routinely run past midnight. A real job is `21:00:00 -> 02:00:00`, which is
/// 5 hours, not -19. Any consumer that subtracts naively gets a negative number and silently
/// mis-filters every late job — which is most of them. `timeEnd <= timeStart` therefore means the
/// end is on the NEXT day and gets +24h.
library;

final RegExp _timeRegExp = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');

/// Parse "HH:MM" or "HH:MM:SS" into minutes since midnight. Null when unparseable.
double? _toMinutes(String? time) {
  if (time == null) return null;

  final match = _timeRegExp.firstMatch(time.trim());
  if (match == null) return null;

  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  final seconds = match.group(3) == null ? 0 : int.parse(match.group(3)!);

  if (hours > 23 || minutes > 59 || seconds > 59) return null;

  return hours * 60 + minutes + seconds / 60;
}

/// Job length in hours, or null when either time is missing/unparseable.
///
/// Returns a decimal — 21:00 -> 02:30 is 5.5, not 5 or 6 — so a 5.5h job is correctly excluded by
/// a "max 5 hours" filter.
double? jobDurationHours(String? timeStart, String? timeEnd) {
  final start = _toMinutes(timeStart);
  final end = _toMinutes(timeEnd);

  if (start == null || end == null) return null;

  // end <= start means the job runs past midnight. Equal times are treated as a full 24h rather
  // than 0: a zero-length booking does not exist, so 24 is the only reading that isn't nonsense.
  final spanMinutes = end > start ? end - start : end + 24 * 60 - start;

  return spanMinutes / 60;
}

/// Human label for the job cards, e.g. "5 timer" / "5,5 timer" / "1 time".
String? formatJobDuration(double? hours) {
  if (hours == null || !hours.isFinite || hours <= 0) return null;

  // Danish decimal comma, and no trailing ",0" on whole hours.
  final rounded = (hours * 10).round() / 10;
  final label =
      rounded == rounded.roundToDouble()
          ? rounded.toStringAsFixed(0)
          : rounded.toString().replaceAll('.', ',');

  return '$label ${rounded == 1 ? 'time' : 'timer'}';
}
