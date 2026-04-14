class ExtJob {
  const ExtJob({
    required this.id,
    required this.leadName,
    required this.date,
    required this.status,
    required this.createdAt,
    this.phoneNumber,
    this.email,
    this.startTime,
    this.endTime,
    this.location,
    this.guestsAmount,
    this.eventType,
    this.budgetTarget,
    this.fullAmount,
    this.honorar,
    this.assignedDjId,
    this.assignedDjName,
    this.assignedMusicianId,
    this.assignedMusicianName,
    this.roleType,
    this.requestedMusicianHours,
    this.region,
    this.notes,
    this.birthdayPersonAge,
    this.company,
    this.djReadyConfirmedAt,
    this.customerContactPlannedFor,
  });

  final int id;
  final String leadName;
  final DateTime date;
  final ExtJobStatus status;
  final DateTime createdAt;
  final String? phoneNumber;
  final String? email;
  final String? startTime;
  final String? endTime;
  final String? location;
  final int? guestsAmount;
  final String? eventType;
  final String? budgetTarget;
  final double? fullAmount;
  final double? honorar;
  final String? assignedDjId;
  final String? assignedDjName;
  final String? assignedMusicianId;
  final String? assignedMusicianName;
  final String? roleType;
  final double? requestedMusicianHours;
  final String? region;
  final String? notes;
  final String? birthdayPersonAge;
  final String? company;
  final DateTime? djReadyConfirmedAt;
  final DateTime? customerContactPlannedFor;

  String get timeDisplay {
    if (startTime != null && endTime != null) return '$startTime - $endTime';
    if (startTime != null) return startTime!;
    return 'Ikke angivet';
  }

  String get budgetDisplay {
    if (fullAmount != null) return '${fullAmount!.toInt()} kr.';
    if (honorar != null) return '${honorar!.toInt()} kr. (honorar)';
    if (budgetTarget != null && budgetTarget!.isNotEmpty) return budgetTarget!;
    return 'Ikke angivet';
  }

  String get displayEventType => eventType ?? 'Arrangement';
  String get displayLocation => location ?? region ?? 'Ikke angivet';
}

enum ExtJobStatus {
  open,
  customerContacted,
  readyForBilling,
  closed,
  expired;

  static ExtJobStatus fromString(String value) {
    return switch (value) {
      'customer_contacted' => ExtJobStatus.customerContacted,
      'ready_for_billing' => ExtJobStatus.readyForBilling,
      'closed' => ExtJobStatus.closed,
      'expired' => ExtJobStatus.expired,
      _ => ExtJobStatus.open,
    };
  }
}
