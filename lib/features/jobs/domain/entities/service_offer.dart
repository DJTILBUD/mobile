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
    this.extraHoursDeclinedAt,
    this.musicianNotes,
    this.musicianFullName,
    this.musicianPhone,
    this.musicianEmail,
    this.customerContactPlannedFor,
    this.specialRequestExtraFeeDkk = 0,
    this.specialRequestExtraFeeConfirmed = false,
    this.specialRequestExtraFeeReason,
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

  /// When the performer answered "Jeg spillede ikke ekstra timer". Non-null
  /// hides the extra-hours card and suppresses the extra_hours_reminder push
  /// (see `setExtraHoursDeclined` in the web app). Null = unanswered.
  final DateTime? extraHoursDeclinedAt;
  final String? musicianNotes;
  // Populated when fetched from the DJ's perspective (fetchServiceOffersForJob)
  final String? musicianFullName;
  final String? musicianPhone;
  final String? musicianEmail;
  final DateTime? customerContactPlannedFor;
  final int specialRequestExtraFeeDkk;
  final bool specialRequestExtraFeeConfirmed;

  /// Why the musician asked for the fee. Required on new requests (the web route
  /// rejects a blank one); null only on rows predating migration 20260810000002.
  final String? specialRequestExtraFeeReason;

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
