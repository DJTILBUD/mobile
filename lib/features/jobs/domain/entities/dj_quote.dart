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
    this.djPayoutOverride,
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

  /// Admin-negotiated payout that REPLACES the standard 75% calculation.
  /// When set, the DJ must only ever see this number — never the full job price
  /// or the standard cut — otherwise we leak that the deal was changed.
  final int? djPayoutOverride;

  /// True when an admin has overridden this DJ's payout.
  /// Mirrors web app QuoteInfo: `dj_payout_override != null`.
  bool get hasPayoutOverride => djPayoutOverride != null;

  /// What the DJ is paid. MUST mirror web app QuoteInfo exactly:
  ///   dj_payout_override ?? round(price_dkk * 0.75)
  /// Do not add early-setup/extra-hours on top — price_dkk already includes any
  /// accepted add-ons, and the override is the final agreed amount.
  int get djPayout => djPayoutOverride ?? (priceDkk * 0.75).round();
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
