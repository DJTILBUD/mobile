import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';

/// Generates an RFC 5545-compliant iCal (.ics) string from a list of calendar events.
/// Mirrors the logic in web-app/src/components/ICalExportModal.tsx
String generateIcal(List<CalendarEvent> events) {
  final now = DateTime.now().toUtc();
  final stamp = _formatUtcStamp(now);

  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//DJ Tilbud//Kalender//DA',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'X-WR-CALNAME:Mine jobs – DJ Tilbud',
    'X-WR-TIMEZONE:Europe/Copenhagen',
    'REFRESH-INTERVAL;VALUE=DURATION:PT12H',
    'X-PUBLISHED-TTL:PT12H',
  ];

  for (final event in events) {
    final uid =
        '${_dateStr(event.date)}-${event.type.name}-${event.id}@djtilbud.dk';
    final dateBase = _dateStr(event.date).replaceAll('-', '');

    final String dtStart;
    final String dtEnd;

    if (event.startTime != null) {
      final sh = event.startTime!.replaceAll(':', '');
      final eh = (event.endTime ?? event.startTime!).replaceAll(':', '');
      dtStart = 'DTSTART;TZID=Europe/Copenhagen:${dateBase}T${sh}00';
      dtEnd = 'DTEND;TZID=Europe/Copenhagen:${dateBase}T${eh}00';
    } else {
      // All-day event — end is exclusive (next day)
      final nextDay = event.date.add(const Duration(days: 1));
      final nextBase = _dateStr(nextDay).replaceAll('-', '');
      dtStart = 'DTSTART;VALUE=DATE:$dateBase';
      dtEnd = 'DTEND;VALUE=DATE:$nextBase';
    }

    final summary = _escapeIcal(
      '${event.label}${event.type == CalendarEventType.external ? ' (Udvalgt job)' : ''}',
    );

    final descParts = <String>[
      if (event.guestsAmount != null) 'Antal gæster: ${event.guestsAmount}',
      if (event.region != null) 'Region: ${event.region}',
      if (event.type == CalendarEventType.external) 'Type: Udvalgt job',
    ];

    lines.add('BEGIN:VEVENT');
    lines.add('UID:$uid');
    lines.add(dtStart);
    lines.add(dtEnd);
    lines.add('SUMMARY:$summary');
    if (event.location != null) {
      lines.add('LOCATION:${_escapeIcal(event.location!)}');
    }
    if (descParts.isNotEmpty) {
      lines.add('DESCRIPTION:${_escapeIcal(descParts.join('\\n'))}');
    }
    lines.add('DTSTAMP:$stamp');
    lines.add('END:VEVENT');
  }

  lines.add('END:VCALENDAR');
  return lines.join('\r\n');
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _formatUtcStamp(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final mo = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final h = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  final s = d.second.toString().padLeft(2, '0');
  return '${y}${mo}${day}T${h}${mi}${s}Z';
}

String _escapeIcal(String s) => s
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll('\n', '\\n');
