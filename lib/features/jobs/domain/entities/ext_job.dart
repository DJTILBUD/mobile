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

  String get timeDisplay {
    if (startTime != null && endTime != null) {
      return '${_stripSeconds(startTime!)} - ${_stripSeconds(endTime!)}';
    }
    if (startTime != null) return _stripSeconds(startTime!);
    return 'Ikke angivet';
  }

  String get budgetDisplay {
    if (fullAmount != null) return '${_fmtNum(fullAmount!)} kr.';
    if (honorar != null) return '${_fmtNum(honorar!)} kr. (honorar)';
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
