import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/job_model.dart';

class ExtJobModel {
  const ExtJobModel({
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
  final String date;
  final String status;
  final String createdAt;
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
  final String? customerContactPlannedFor;

  factory ExtJobModel.fromJson(Map<String, dynamic> json) {
    // PostgreSQL time fields come as "HH:MM:SS", display as "HH:MM"
    String? formatTime(dynamic raw) {
      if (raw == null) return null;
      final s = raw.toString();
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    return ExtJobModel(
      id: (json['id'] as num).toInt(),
      leadName: json['lead_name'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      startTime: formatTime(json['start_time']),
      endTime: formatTime(json['end_time']),
      location: json['location'] as String?,
      guestsAmount: (json['guests_amount'] as num?)?.toInt(),
      eventType: json['event_type'] as String?,
      budgetTarget: json['budget_target'] as String?,
      fullAmount: (json['full_amount'] as num?)?.toDouble(),
      honorar: (json['honorar'] as num?)?.toDouble(),
      assignedDjId: json['assigned_dj_id'] as String?,
      assignedDjName: json['assigned_dj_name'] as String?,
      assignedMusicianId: json['assigned_musician_id'] as String?,
      assignedMusicianName: json['assigned_musician_name'] as String?,
      roleType: json['role_type'] as String?,
      requestedMusicianHours:
          (json['requested_musician_hours'] as num?)?.toDouble(),
      region: json['region'] as String?,
      notes: json['notes'] as String?,
      birthdayPersonAge: json['birthday_person_age'] as String?,
      company: json['company'] as String?,
      djReadyConfirmedAt: json['dj_ready_confirmed_at'] != null
          ? DateTime.parse(json['dj_ready_confirmed_at'] as String)
          : null,
      customerContactPlannedFor: json['customer_contact_planned_for'] as String?,
    );
  }

  ExtJob toEntity() {
    return ExtJob(
      id: id,
      leadName: leadName,
      date: DateTime.parse(date),
      status: ExtJobStatus.fromString(status),
      createdAt: DateTime.parse(createdAt),
      phoneNumber: phoneNumber,
      email: email,
      startTime: startTime,
      endTime: endTime,
      location: location,
      guestsAmount: guestsAmount,
      eventType: eventType,
      budgetTarget: budgetTarget,
      fullAmount: fullAmount,
      honorar: honorar,
      assignedDjId: assignedDjId,
      assignedDjName: assignedDjName,
      assignedMusicianId: assignedMusicianId,
      assignedMusicianName: assignedMusicianName,
      roleType: roleType,
      requestedMusicianHours: requestedMusicianHours,
      region: region,
      notes: notes,
      birthdayPersonAge: birthdayPersonAge,
      company: company,
      djReadyConfirmedAt: djReadyConfirmedAt,
      customerContactPlannedFor: customerContactPlannedFor != null
          ? DateTime.parse(customerContactPlannedFor!)
          : null,
    );
  }

  /// Maps this ext job to a Job entity so it can be shown in the
  /// instrumentalist jobs feed without any visible difference.
  Job toJobEntity() {
    return toJobModel().toEntity();
  }

  /// Maps this ext job to a JobModel for use inside ServiceOfferModel.
  JobModel toJobModel() {
    return JobModel(
      id: id,
      extJobId: id,
      isExtJob: true,
      eventType: eventType ?? 'Arrangement',
      date: date,
      timeStart: startTime ?? '00:00',
      timeEnd: endTime ?? '00:00',
      city: location ?? '',
      region: region ?? '',
      guestsAmount: guestsAmount ?? 0,
      status: 'open',
      createdAt: createdAt,
      requestedMusicianHours: requestedMusicianHours,
      birthdayPersonAge: birthdayPersonAge,
      leadName: leadName,
      leadEmail: email,
      leadPhoneNumber: phoneNumber,
      requestedSaxophonist: true,
      leadRequest: notes,
      assignedDjName: assignedDjName,
    );
  }
}
