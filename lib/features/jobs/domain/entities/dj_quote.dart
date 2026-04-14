import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';

class DjQuote {
  const DjQuote({
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
  final QuoteStatus status;
  final DateTime createdAt;
  final Job job;
  // null = not offered, 'offered' = pending customer decision,
  // 'accepted' = customer accepted, 'rejected' = customer declined
  final String? earlySetupStatus;
  final int? earlySetupPrice;
  final DateTime? djReadyConfirmedAt;
  final double? extraHours;
  final int? extraHoursPricePerHour;
  final String? djNotes;
}

enum QuoteStatus {
  pending,
  won,
  lost,
  overwritten;

  static QuoteStatus fromString(String value) {
    return switch (value) {
      'pending' => QuoteStatus.pending,
      'won' => QuoteStatus.won,
      'lost' => QuoteStatus.lost,
      'overwritten' => QuoteStatus.overwritten,
      _ => QuoteStatus.pending,
    };
  }
}
