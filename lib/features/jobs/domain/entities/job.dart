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
