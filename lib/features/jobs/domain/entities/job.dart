import 'package:dj_tilbud_app/features/jobs/domain/job_duration.dart';

class Job {
  const Job({
    required this.id,
    required this.eventType,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    required this.city,
    required this.region,
    required this.guestsAmount,
    required this.status,
    required this.createdAt,
    this.budgetStart,
    this.budgetEnd,
    this.genres,
    this.leadRequest,
    this.additionalInformation,
    this.requestedSaxophonist = false,
    this.requestedMusicianHours,
    this.birthdayPersonAge,
    this.leadName,
    this.leadEmail,
    this.leadPhoneNumber,
    this.customerNote,
    this.isExtJob = false,
    this.extJobId,
    this.quoteSendMode,
    this.isPaused = false,
    this.assignedDjName,
    this.sentAt,
    this.deadlineExtendedUntil,
    this.customerContactPlannedFor,
    this.musicianStartTime,
    this.roleType,
    this.hasActiveOffer = false,
    this.hasDateConflict = false,
    this.saxType,
    this.musicianSpecialRequest,
    this.songRequestToken,
    this.postalCode,
    this.guestAge,
    this.addressAs,
    this.firstDanceSong,
    this.spotifyPlaylistUrl,
    this.specialConditions,
    this.earlySetup = false,
  });

  final int id;
  final String eventType;
  final DateTime date;
  final String timeStart;
  final String timeEnd;
  final String city;
  final String region;
  final int guestsAmount;
  final JobStatus status;
  final DateTime createdAt;
  final double? budgetStart;
  final double? budgetEnd;
  final List<String>? genres;
  final String? leadRequest;
  final String? additionalInformation;
  final bool requestedSaxophonist;
  final double? requestedMusicianHours;
  final String? birthdayPersonAge;
  final String? leadName;
  final String? leadEmail;
  final String? leadPhoneNumber;
  final String? customerNote;
  final bool isExtJob;
  final int? extJobId;

  /// 'first_quote_only' → high-season priority (Højsæson-prioritet)
  final String? quoteSendMode;

  /// True when an admin has paused the job — no one can bid while paused.
  final bool isPaused;
  final String? assignedDjName;

  /// When the job was sent to the customer for selection. Null for unsent jobs
  /// and for ExtJobs (which don't have this column). Drives the customer
  /// response deadline countdown.
  final DateTime? sentAt;
  final DateTime? deadlineExtendedUntil;
  final DateTime? customerContactPlannedFor;

  /// HH:MM string for the musician's start time (separate from event start).
  final String? musicianStartTime;

  /// 'musician_only' | 'dj_and_musician' | 'dj_only' — only set for ext jobs.
  final String? roleType;

  /// True when another musician of the same instrument already has a non-lost offer on this job.
  final bool hasActiveOffer;

  /// True when the current musician already has a sent/won service offer on the same date.
  final bool hasDateConflict;

  /// 'lounge' | 'party' — type of saxophone performance requested.
  final String? saxType;

  /// Free-text special request from the customer directed at the musician.
  final String? musicianSpecialRequest;

  /// UUID token used to generate the public song-request link for guests.
  final String? songRequestToken;

  // Partner "Til festen" couple-facing event details (ext jobs booked via the partner portal). All
  // nullable; earlySetup is a non-null bool (defaults false).
  final String? guestAge;
  final String? addressAs;
  final String? firstDanceSong;
  final String? spotifyPlaylistUrl;
  final String? specialConditions;
  final bool earlySetup;

  /// Postal code of the event location. Present on both Jobs and ExtJobs.
  final String? postalCode;

  Job withDateConflict() => Job(
    id: id,
    eventType: eventType,
    date: date,
    timeStart: timeStart,
    timeEnd: timeEnd,
    city: city,
    region: region,
    guestsAmount: guestsAmount,
    status: status,
    createdAt: createdAt,
    budgetStart: budgetStart,
    budgetEnd: budgetEnd,
    genres: genres,
    leadRequest: leadRequest,
    additionalInformation: additionalInformation,
    requestedSaxophonist: requestedSaxophonist,
    requestedMusicianHours: requestedMusicianHours,
    birthdayPersonAge: birthdayPersonAge,
    leadName: leadName,
    leadEmail: leadEmail,
    leadPhoneNumber: leadPhoneNumber,
    customerNote: customerNote,
    isExtJob: isExtJob,
    extJobId: extJobId,
    quoteSendMode: quoteSendMode,
    isPaused: isPaused,
    assignedDjName: assignedDjName,
    sentAt: sentAt,
    deadlineExtendedUntil: deadlineExtendedUntil,
    customerContactPlannedFor: customerContactPlannedFor,
    musicianStartTime: musicianStartTime,
    roleType: roleType,
    hasActiveOffer: hasActiveOffer,
    hasDateConflict: true,
    saxType: saxType,
    musicianSpecialRequest: musicianSpecialRequest,
    songRequestToken: songRequestToken,
    postalCode: postalCode,
  );

  static String _fmtNum(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String _stripSeconds(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }

  String get budgetDisplay {
    if (budgetStart == null || budgetEnd == null) return 'Ikke angivet';
    if (budgetStart == budgetEnd) return '${_fmtNum(budgetStart!)} kr.';
    return '${_fmtNum(budgetStart!)} – ${_fmtNum(budgetEnd!)} kr.';
  }

  /// The event place with its postal code, e.g. "2100 København".
  /// Mirrors the location shown on the job list card so the postal code is
  /// visible on detail screens too, not just in the list.
  String get placeLabel {
    final pc = postalCode?.trim();
    if (pc != null && pc.isNotEmpty && city.isNotEmpty) return '$pc $city';
    if (pc != null && pc.isNotEmpty) return pc;
    return city;
  }

  String get timeDisplay =>
      '${_stripSeconds(timeStart)} - ${_stripSeconds(timeEnd)}';

  /// Job length label, e.g. "5 timer". Null when the times are unparseable.
  /// Handles the past-midnight wrap via the shared `jobDurationHours` helper.
  String? get durationDisplay =>
      formatJobDuration(jobDurationHours(timeStart, timeEnd));

  /// Time range plus length, e.g. "21.00 - 02.00 (5 timer)". Used on the DJ job card so the
  /// hours filter is visible on the thing it filters: without it, jobs disappear from the feed
  /// with no on-screen reason.
  String get timeDisplayWithDuration {
    final duration = durationDisplay;
    return duration == null ? timeDisplay : '$timeDisplay ($duration)';
  }

  /// requested_musician_hours formatted for display: whole numbers without decimals, halves with
  /// one decimal (1, 0.5, 1.5). Single source so the card and the detail/offer screens never round
  /// it differently (a 0.5h job must not read "0.5" on the card and "1" inside).
  String get musicianHoursDisplay {
    final h = requestedMusicianHours;
    if (h == null) return '';
    return h.toStringAsFixed(h % 1 == 0 ? 0 : 1);
  }

  /// Customer response deadline. Mirrors web-app `getCountdownTargetDate`:
  ///   - admin-extended deadline wins if set,
  ///   - otherwise min(sentAt + 7d, jobDate − 2d).
  /// Returns null when the job hasn't been sent yet (no countdown should be shown). Ext jobs now
  /// also carry sent_at + deadline_extended_until (via ExtJobModel.toJobModel), so this works for
  /// the ext-job-as-Job the offer detail screen renders.
  DateTime? get customerDeadline {
    if (deadlineExtendedUntil != null) return deadlineExtendedUntil;
    if (sentAt == null) return null;
    final sevenDaysAfterSent = sentAt!.add(const Duration(days: 7));
    final twoDaysBeforeJob = date.subtract(const Duration(days: 2));
    return sevenDaysAfterSent.isBefore(twoDaysBeforeJob)
        ? sevenDaysAfterSent
        : twoDaysBeforeJob;
  }
}

enum JobStatus {
  open,
  sent,
  closed,
  expired,
  reopened,
  customerContacted,
  readyForBilling,
  canceled,
  anotherRound,
  reSent;

  static JobStatus fromString(String value) {
    return switch (value) {
      'open' => JobStatus.open,
      'sent' => JobStatus.sent,
      'closed' => JobStatus.closed,
      'expired' => JobStatus.expired,
      'reopened' => JobStatus.reopened,
      'customer_contacted' => JobStatus.customerContacted,
      'ready_for_billing' => JobStatus.readyForBilling,
      'canceled' => JobStatus.canceled,
      'another_round' => JobStatus.anotherRound,
      're_sent' => JobStatus.reSent,
      _ => JobStatus.open,
    };
  }

  /// The value as stored in Postgres. Inverse of [fromString].
  ///
  /// Use this, never `.name`, for anything that leaves the app (analytics, the
  /// API): `.name` yields the Dart camelCase (`customerContacted`) while the DB,
  /// the web-app and every other system use `customer_contacted`, so `.name`
  /// values cannot be joined without a translation table.
  String get dbValue => switch (this) {
    JobStatus.open => 'open',
    JobStatus.sent => 'sent',
    JobStatus.closed => 'closed',
    JobStatus.expired => 'expired',
    JobStatus.reopened => 'reopened',
    JobStatus.customerContacted => 'customer_contacted',
    JobStatus.readyForBilling => 'ready_for_billing',
    JobStatus.canceled => 'canceled',
    JobStatus.anotherRound => 'another_round',
    JobStatus.reSent => 're_sent',
  };
}
