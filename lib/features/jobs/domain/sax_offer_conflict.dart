/// Canonical saxophonist/musician same-date conflict rule.
///
/// Mirrors EXACTLY the web helper `web-app/src/helpers/saxOfferConflict.ts` and the DB function
/// `public.sax_bookings_conflict` (migration `20260706000003_sax_time_aware_date_conflict.sql`).
/// Keep all three in sync.
///
/// Sax gigs are short, so two same-date bookings can BOTH be performed (both winnable) when the gap
/// between the earlier one's END and the later one's START is at least [saxMinGapMinutes]. Otherwise
/// they CONFLICT (winning one marks the other lost). Different dates never conflict; any unknown time
/// is treated as a conservative conflict.
library;

/// 3-hour buffer between the end of one gig and the start of the next. A gap of exactly 3h is
/// compatible; only a gap strictly below this is a conflict.
const int saxMinGapMinutes = 180;

/// Calendar-date key ("yyyy-MM-dd") for a [DateTime], using its local Y/M/D components.
String saxDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String? _dateKey(String? value) {
  if (value == null || value.isEmpty) return null;
  return value.length >= 10 ? value.substring(0, 10) : value;
}

int? _timeToMinutes(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  final h = int.tryParse(parts[0]);
  final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// The sax's END time = musician_start_time + requestedMusicianHours, as "HH:MM" (wraps within 24h to
/// match the SQL `time + interval`). Null when start or hours is missing/invalid => conservative
/// conflict. Mirrors web `saxEndTime`. The sax's window is [musicianStartTime, +requestedMusicianHours]
/// — NOT the DJ's time_start/time_end.
String? saxEndTime(String? musicianStartTime, num? requestedMusicianHours) {
  final startMin = _timeToMinutes(musicianStartTime);
  if (startMin == null || requestedMusicianHours == null) return null;
  final wrapped =
      ((startMin + (requestedMusicianHours * 60).round()) % 1440 + 1440) % 1440;
  final hh = (wrapped ~/ 60).toString().padLeft(2, '0');
  final mm = (wrapped % 60).toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// True when two same-date bookings collide (cannot both be performed):
///  - different (or unknown) calendar date => never a conflict;
///  - any missing/unparseable time => conservative conflict;
///  - otherwise conflict iff the gap between earlier end and later start is < [saxMinGapMinutes].
bool saxBookingsConflict({
  required String? dateA,
  required String? startA,
  required String? endA,
  required String? dateB,
  required String? startB,
  required String? endB,
}) {
  final da = _dateKey(dateA);
  final db = _dateKey(dateB);
  if (da == null || db == null || da != db) return false;

  final aStart = _timeToMinutes(startA);
  final aEnd = _timeToMinutes(endA);
  final bStart = _timeToMinutes(startB);
  final bEnd = _timeToMinutes(endB);
  if (aStart == null || aEnd == null || bStart == null || bEnd == null)
    return true;

  final earlierEnd = aStart <= bStart ? aEnd : bEnd;
  final laterStart = aStart <= bStart ? bStart : aStart;
  return (laterStart - earlierEnd) < saxMinGapMinutes;
}

/// Immutable key for the `dateConflictProvider` family: the booking a musician is about to offer on.
class SaxConflictQuery {
  const SaxConflictQuery({required this.date, this.startTime, this.endTime});

  final DateTime date;
  final String? startTime;
  final String? endTime;

  @override
  bool operator ==(Object other) =>
      other is SaxConflictQuery &&
      other.date == date &&
      other.startTime == startTime &&
      other.endTime == endTime;

  @override
  int get hashCode => Object.hash(date, startTime, endTime);
}
