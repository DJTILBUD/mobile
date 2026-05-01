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
    this.assignedDjName,
    this.deadlineExtendedUntil,
    this.customerContactPlannedFor,
    this.musicianStartTime,
    this.roleType,
    this.hasActiveOffer = false,
    this.hasDateConflict = false,
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
  final String? assignedDjName;
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
        assignedDjName: assignedDjName,
        deadlineExtendedUntil: deadlineExtendedUntil,
        customerContactPlannedFor: customerContactPlannedFor,
        musicianStartTime: musicianStartTime,
        roleType: roleType,
        hasActiveOffer: hasActiveOffer,
        hasDateConflict: true,
      );

  String get budgetDisplay {
    if (budgetStart == null || budgetEnd == null) return 'Ikke angivet';
    if (budgetStart == budgetEnd) return '${budgetStart!.toInt()} kr.';
    return '${budgetStart!.toInt()} - ${budgetEnd!.toInt()} kr.';
  }

  String get timeDisplay => '$timeStart - $timeEnd';
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
}
