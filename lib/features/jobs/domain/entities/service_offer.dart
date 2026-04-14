import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';

class ServiceOffer {
  const ServiceOffer({
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
  final ServiceOfferStatus status;
  final DateTime createdAt;
  final Job job;
  final int? musicianPayoutDkk;
  final String? salesPitch;
  final bool customerContacted;
  final DateTime? musicianReadyConfirmedAt;
  final double? extraHours;
  final String? musicianNotes;
  // Populated when fetched from the DJ's perspective (fetchServiceOffersForJob)
  final String? musicianFullName;
  final String? musicianPhone;
  final String? musicianEmail;
  final DateTime? customerContactPlannedFor;

  bool get isExtJob => extJobId != null;
}

enum ServiceOfferStatus {
  sent,
  won,
  lost;

  static ServiceOfferStatus fromString(String value) {
    return switch (value) {
      'sent' => ServiceOfferStatus.sent,
      'won' => ServiceOfferStatus.won,
      'lost' => ServiceOfferStatus.lost,
      _ => ServiceOfferStatus.sent,
    };
  }
}
