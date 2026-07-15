import 'package:dj_tilbud_app/core/utils/budget_utils.dart';
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
    this.budgetDisplay,
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
  final String? budgetDisplay;
  final int? jobId;
  final int? extJobId;

  /// Parses a Quote row with nested `job:Jobs(...)` data.
  ///
  /// [djTier] drives the tier part of the DJ-facing budget. The label goes
  /// through `djBudgetLabelFromParts` — the same builder the job list and job
  /// detail use — so a won job shows the identical figure on every surface.
  /// Never format `budget_start`/`budget_end` raw here: that is the customer's
  /// full budget, which a DJ must never see.
  factory CalendarEventModel.fromDjQuoteJson(
    Map<String, dynamic> json, {
    String? djTier,
  }) {
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
      budgetDisplay: djBudgetLabelFromParts(
        budgetStart: (job['budget_start'] as num?)?.toDouble(),
        budgetEnd: (job['budget_end'] as num?)?.toDouble(),
        djTier: djTier,
        requestedSaxophonist: job['requested_saxophonist'] as bool? ?? false,
        requestedMusicianHours:
            (job['requested_musician_hours'] as num?)?.toDouble(),
        jobCreatedAt: DateTime.tryParse(job['created_at'] as String? ?? ''),
      ),
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
      budgetDisplay: json['budget_target'] as String?,
      extJobId: (json['id'] as num).toInt(),
    );
  }

  /// Parses a ServiceOffer row with nested `job:Jobs(...)` data.
  factory CalendarEventModel.fromMusicianJobOfferJson(
    Map<String, dynamic> json,
  ) {
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
      // The offer's own payout, NOT the job's budget — an offer has a customer
      // price and a musician payout; the customer's budget is unrelated to it.
      // Mirrors the "Din udbetaling" line on ServiceOfferCard.
      budgetDisplay: musicianOfferPayoutLabel(
        priceDkk: (json['price_dkk'] as num?)?.toInt() ?? 0,
        musicianPayoutDkk: (json['musician_payout_dkk'] as num?)?.toInt(),
      ),
      jobId: (job['id'] as num).toInt(),
    );
  }

  /// Parses a ServiceOffer row with nested `ext_job:ExtJobs(...)` data.
  factory CalendarEventModel.fromMusicianExtJobOfferJson(
    Map<String, dynamic> json,
  ) {
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
      // The offer's own payout, not the ext job's budget_target. Same rule as
      // the internal-job offer above.
      budgetDisplay: musicianOfferPayoutLabel(
        priceDkk: (json['price_dkk'] as num?)?.toInt() ?? 0,
        musicianPayoutDkk: (json['musician_payout_dkk'] as num?)?.toInt(),
      ),
      extJobId: (extJob['id'] as num).toInt(),
    );
  }

  CalendarEvent toEntity({CalendarEventKind kind = CalendarEventKind.won}) {
    return CalendarEvent(
      id: id,
      date: DateTime.tryParse(date) ?? DateTime.fromMillisecondsSinceEpoch(0),
      label: label,
      type:
          type == 'internal'
              ? CalendarEventType.internal
              : CalendarEventType.external,
      kind: kind,
      startTime: startTime,
      endTime: endTime,
      location: location,
      region: region,
      guestsAmount: guestsAmount,
      budgetDisplay: budgetDisplay,
      jobId: jobId,
      extJobId: extJobId,
    );
  }

  /// Formats a Postgres time string "HH:MM:SS" → "HH:MM".
  /// Returns null for null or zero-time values (00:00*) which indicate "not set".
  static String? _fmt(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.startsWith('00:00')) return null;
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  // No raw-budget formatter here on purpose. Every money label on a calendar
  // event comes from budget_utils: `djBudgetLabelFromParts` for a DJ's job
  // (sax/tier-adjusted) and `musicianOfferPayoutLabel` for a musician's offer.
  // Formatting `budget_start`/`budget_end` here is what made the calendar
  // disagree with the job list.
}
