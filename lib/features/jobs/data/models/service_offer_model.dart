import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/job_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/ext_job_model.dart';

class ServiceOfferModel {
  const ServiceOfferModel({
    required this.id,
    required this.musicianId,
    required this.priceDkk,
    required this.instrument,
    required this.status,
    required this.createdAt,
    required this.job,
    this.jobId,
    this.extJobId,
    this.musicianPayoutDkk,
    this.salesPitch,
    this.customerContacted = false,
    this.musicianReadyConfirmedAt,
    this.extraHours,
    this.musicianNotes,
    this.musicianFullName,
    this.musicianPhone,
    this.musicianEmail,
    this.customerContactPlannedFor,
  });

  final int id;
  final int? jobId;
  final int? extJobId;
  final String musicianId;
  final int priceDkk;
  final String instrument;
  final String status;
  final String createdAt;
  final JobModel job;
  final int? musicianPayoutDkk;
  final String? salesPitch;
  final bool customerContacted;
  final DateTime? musicianReadyConfirmedAt;
  final double? extraHours;
  final String? musicianNotes;
  final String? musicianFullName;
  final String? musicianPhone;
  final String? musicianEmail;
  final String? customerContactPlannedFor;

  factory ServiceOfferModel.fromJson(Map<String, dynamic> json) {
    final jobJson = json['job'] as Map<String, dynamic>?;
    final extJobJson = json['ext_job'] as Map<String, dynamic>?;

    // Build a JobModel from whichever related record is present.
    final JobModel jobModel;
    if (jobJson != null) {
      jobModel = JobModel.fromJson(jobJson);
    } else if (extJobJson != null) {
      jobModel = ExtJobModel.fromJson(extJobJson).toJobModel();
    } else {
      // Fallback — should not happen with correct queries
      jobModel = _emptyJobModel();
    }

    final musicianJson = json['musician'] as Map<String, dynamic>?;

    return ServiceOfferModel(
      id: (json['id'] as num).toInt(),
      jobId: (json['job_id'] as num?)?.toInt(),
      extJobId: (json['ext_job_id'] as num?)?.toInt(),
      musicianId: json['musician_id'] as String,
      priceDkk: (json['price_dkk'] as num?)?.toInt() ?? 0,
      instrument: json['instrument'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      job: jobModel,
      musicianPayoutDkk: (json['musician_payout_dkk'] as num?)?.toInt(),
      salesPitch: json['sales_pitch'] as String?,
      customerContacted: json['customer_contacted'] as bool? ?? false,
      musicianReadyConfirmedAt: json['musician_ready_confirmed_at'] != null
          ? DateTime.parse(json['musician_ready_confirmed_at'] as String)
          : null,
      extraHours: (json['extra_hours'] as num?)?.toDouble(),
      musicianNotes: json['musician_notes'] as String?,
      musicianFullName: musicianJson?['full_name'] as String?,
      musicianPhone: musicianJson?['phone'] as String?,
      musicianEmail: musicianJson?['email'] as String?,
      customerContactPlannedFor: json['customer_contact_planned_for'] as String?,
    );
  }

  ServiceOffer toEntity() {
    return ServiceOffer(
      id: id,
      jobId: jobId,
      extJobId: extJobId,
      musicianId: musicianId,
      priceDkk: priceDkk,
      instrument: instrument,
      status: ServiceOfferStatus.fromString(status),
      createdAt: DateTime.parse(createdAt),
      job: job.toEntity(),
      musicianPayoutDkk: musicianPayoutDkk,
      salesPitch: salesPitch,
      customerContacted: customerContacted,
      musicianReadyConfirmedAt: musicianReadyConfirmedAt,
      extraHours: extraHours,
      musicianNotes: musicianNotes,
      musicianFullName: musicianFullName,
      musicianPhone: musicianPhone,
      musicianEmail: musicianEmail,
      customerContactPlannedFor: customerContactPlannedFor != null
          ? DateTime.parse(customerContactPlannedFor!)
          : null,
    );
  }

  static JobModel _emptyJobModel() {
    return JobModel(
      id: 0,
      eventType: 'Arrangement',
      date: DateTime.now().toIso8601String().substring(0, 10),
      timeStart: '00:00',
      timeEnd: '00:00',
      city: '',
      region: '',
      guestsAmount: 0,
      status: 'open',
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}
