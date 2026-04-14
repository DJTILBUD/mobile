import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/job_model.dart';

class DjQuoteModel {
  const DjQuoteModel({
    required this.id,
    required this.jobId,
    required this.priceDkk,
    required this.salesPitch,
    required this.equipmentDescription,
    required this.status,
    required this.createdAt,
    required this.job,
    this.earlySetupStatus,
    this.earlySetupPrice,
    this.djReadyConfirmedAt,
    this.extraHours,
    this.extraHoursPricePerHour,
    this.djNotes,
  });

  final int id;
  final int jobId;
  final int priceDkk;
  final String salesPitch;
  final String equipmentDescription;
  final String status;
  final String createdAt;
  final JobModel job;
  final String? earlySetupStatus;
  final int? earlySetupPrice;
  final DateTime? djReadyConfirmedAt;
  final double? extraHours;
  final int? extraHoursPricePerHour;
  final String? djNotes;

  factory DjQuoteModel.fromJson(Map<String, dynamic> json) {
    return DjQuoteModel(
      id: (json['id'] as num).toInt(),
      jobId: (json['job_id'] as num).toInt(),
      priceDkk: (json['price_dkk'] as num).toInt(),
      salesPitch: json['sales_pitch'] as String? ?? '',
      equipmentDescription: json['equipment_description'] as String? ?? '',
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      job: JobModel.fromJson(json['job'] as Map<String, dynamic>),
      earlySetupStatus: json['early_setup_status'] as String?,
      earlySetupPrice: (json['early_setup_price'] as num?)?.toInt(),
      djReadyConfirmedAt: json['dj_ready_confirmed_at'] != null
          ? DateTime.parse(json['dj_ready_confirmed_at'] as String)
          : null,
      extraHours: (json['extra_hours'] as num?)?.toDouble(),
      extraHoursPricePerHour: (json['extra_hours_price_per_hour'] as num?)?.toInt(),
      djNotes: json['dj_notes'] as String?,
    );
  }

  DjQuote toEntity() {
    return DjQuote(
      id: id,
      jobId: jobId,
      priceDkk: priceDkk,
      salesPitch: salesPitch,
      equipmentDescription: equipmentDescription,
      status: QuoteStatus.fromString(status),
      createdAt: DateTime.parse(createdAt),
      job: job.toEntity(),
      earlySetupStatus: earlySetupStatus,
      earlySetupPrice: earlySetupPrice,
      djReadyConfirmedAt: djReadyConfirmedAt,
      extraHours: extraHours,
      extraHoursPricePerHour: extraHoursPricePerHour,
      djNotes: djNotes,
    );
  }
}
