import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';

class JobModel {
  const JobModel({
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
    this.requestedSaxophonist,
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
  final String date;
  final String timeStart;
  final String timeEnd;
  final String city;
  final String region;
  final int guestsAmount;
  final String status;
  final String createdAt;
  final double? budgetStart;
  final double? budgetEnd;
  final List<String>? genres;
  final String? leadRequest;
  final String? additionalInformation;
  final bool? requestedSaxophonist;
  final double? requestedMusicianHours;
  final String? birthdayPersonAge;
  final String? leadName;
  final String? leadEmail;
  final String? leadPhoneNumber;
  final String? customerNote;
  final bool isExtJob;
  final int? extJobId;
  final String? quoteSendMode;
  final String? assignedDjName;
  final String? deadlineExtendedUntil;
  final String? customerContactPlannedFor;

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: (json['id'] as num).toInt(),
      eventType: json['event_type'] as String,
      date: json['date'] as String,
      timeStart: json['time_start'] as String,
      timeEnd: json['time_end'] as String,
      city: json['city'] as String,
      region: json['region'] as String,
      guestsAmount: (json['guests_amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      budgetStart: (json['budget_start'] as num?)?.toDouble(),
      budgetEnd: (json['budget_end'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>?)?.cast<String>(),
      leadRequest: json['lead_request'] as String?,
      additionalInformation: json['additional_information'] as String?,
      requestedSaxophonist: json['requested_saxophonist'] as bool?,
      requestedMusicianHours:
          (json['requested_musician_hours'] as num?)?.toDouble(),
      birthdayPersonAge: json['birthday_person_age'] as String?,
      leadName: json['lead_name'] as String?,
      leadEmail: json['lead_email'] as String?,
      leadPhoneNumber: json['lead_phone_number'] as String?,
      customerNote: json['customer_note'] as String?,
      quoteSendMode: json['quote_send_mode'] as String?,
      deadlineExtendedUntil: json['deadline_extended_until'] as String?,
      customerContactPlannedFor: json['customer_contact_planned_for'] as String?,
    );
  }

  Job toEntity() {
    return Job(
      id: id,
      eventType: eventType,
      date: DateTime.parse(date),
      timeStart: timeStart,
      timeEnd: timeEnd,
      city: city,
      region: region,
      guestsAmount: guestsAmount,
      status: JobStatus.fromString(status),
      createdAt: DateTime.parse(createdAt),
      budgetStart: budgetStart,
      budgetEnd: budgetEnd,
      genres: genres,
      leadRequest: leadRequest,
      additionalInformation: additionalInformation,
      requestedSaxophonist: requestedSaxophonist ?? false,
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
      deadlineExtendedUntil: deadlineExtendedUntil != null
          ? DateTime.parse(deadlineExtendedUntil!)
          : null,
      customerContactPlannedFor: customerContactPlannedFor != null
          ? DateTime.parse(customerContactPlannedFor!)
          : null,
    );
  }
}
