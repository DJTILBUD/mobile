/// Matches the web app's event category labels.
enum CalendarEventKind { newJob, sent, won }

/// Internal = regular Job, External = ExtJob.
enum CalendarEventType { internal, external }

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.date,
    required this.label,
    required this.type,
    this.kind = CalendarEventKind.won,
    this.startTime,
    this.endTime,
    this.location,
    this.region,
    this.guestsAmount,
    this.jobId,
    this.extJobId,
  });

  final int id;
  final DateTime date;
  final String label;
  final CalendarEventType type;
  final CalendarEventKind kind;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? region;
  final int? guestsAmount;
  final int? jobId;
  final int? extJobId;

  String get timeDisplay {
    if (startTime != null && endTime != null) return '$startTime - $endTime';
    if (startTime != null) return startTime!;
    return 'Ikke angivet';
  }

  String get locationDisplay => location ?? region ?? 'Ikke angivet';
}
