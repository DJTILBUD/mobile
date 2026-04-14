import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';

class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.date,
    required this.label,
    required this.type,
    this.startTime,
    this.endTime,
    this.location,
    this.region,
    this.guestsAmount,
    this.jobId,
    this.extJobId,
  });

  final int id;
  final String date;
  final String label;
  final String type; // 'internal' | 'external'
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? region;
  final int? guestsAmount;
  final int? jobId;
  final int? extJobId;

  /// Parses a Quote row with nested `job:Jobs(...)` data.
  factory CalendarEventModel.fromDjQuoteJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>;
    return CalendarEventModel(
      id: (json['id'] as num).toInt(),
      date: job['date'] as String,
      label: job['event_type'] as String,
      type: 'internal',
      startTime: _fmt(job['time_start']),
      endTime: _fmt(job['time_end']),
      location: job['city'] as String?,
      region: job['region'] as String?,
      guestsAmount: (job['guests_amount'] as num?)?.toInt(),
      jobId: (job['id'] as num).toInt(),
    );
  }

  /// Parses an ExtJob row directly (assigned to DJ).
  factory CalendarEventModel.fromDjExtJobJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      label: json['event_type'] as String? ?? 'Arrangement',
      type: 'external',
      startTime: _fmt(json['start_time']),
      endTime: _fmt(json['end_time']),
      location: json['location'] as String?,
      region: json['region'] as String?,
      guestsAmount: (json['guests_amount'] as num?)?.toInt(),
      extJobId: (json['id'] as num).toInt(),
    );
  }

  /// Parses a ServiceOffer row with nested `job:Jobs(...)` data.
  factory CalendarEventModel.fromMusicianJobOfferJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>;
    return CalendarEventModel(
      id: (json['id'] as num).toInt(),
      date: job['date'] as String,
      label: job['event_type'] as String,
      type: 'internal',
      startTime: _fmt(job['time_start']),
      endTime: _fmt(job['time_end']),
      location: job['city'] as String?,
      region: job['region'] as String?,
      guestsAmount: (job['guests_amount'] as num?)?.toInt(),
      jobId: (job['id'] as num).toInt(),
    );
  }

  /// Parses a ServiceOffer row with nested `ext_job:ExtJobs(...)` data.
  factory CalendarEventModel.fromMusicianExtJobOfferJson(
      Map<String, dynamic> json) {
    final extJob = json['ext_job'] as Map<String, dynamic>;
    return CalendarEventModel(
      id: (json['id'] as num).toInt(),
      date: extJob['date'] as String,
      label: extJob['event_type'] as String? ?? 'Arrangement',
      type: 'external',
      startTime: _fmt(extJob['start_time']),
      endTime: _fmt(extJob['end_time']),
      location: extJob['location'] as String?,
      region: extJob['region'] as String?,
      guestsAmount: (extJob['guests_amount'] as num?)?.toInt(),
      extJobId: (extJob['id'] as num).toInt(),
    );
  }

  CalendarEvent toEntity({CalendarEventKind kind = CalendarEventKind.won}) {
    return CalendarEvent(
      id: id,
      date: DateTime.parse(date),
      label: label,
      type: type == 'internal'
          ? CalendarEventType.internal
          : CalendarEventType.external,
      kind: kind,
      startTime: startTime,
      endTime: endTime,
      location: location,
      region: region,
      guestsAmount: guestsAmount,
      jobId: jobId,
      extJobId: extJobId,
    );
  }

  /// Formats a Postgres time string "HH:MM:SS" → "HH:MM".
  static String? _fmt(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}
