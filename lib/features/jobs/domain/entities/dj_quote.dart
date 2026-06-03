import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/dj_fee.dart';

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

  /// The DJ's share of the customer price (1 - platform fee). Date-based,
  /// keyed off the JOB's created_at — 0.80 before 2025-10-15, 0.75 on/after —
  /// exactly like web QuoteInfo's `getFeeForJob(job.created_at)`. A fixed 0.75
  /// here would under-pay pre-2025-10-15 jobs vs what the web shows.
  double get _payoutShare => djPayoutShareForJob(job.createdAt);

  /// What the DJ is paid. Mirrors web QuoteInfo exactly:
  ///   dj_payout_override ?? round(price_dkk * (1 - fee))
  /// price_dkk already includes any accepted add-ons, and the override (when
  /// set) is the final agreed amount — never add add-ons on top of either.
  int get djPayout => djPayoutOverride ?? (priceDkk * _payoutShare).round();

  // ── Price breakdown — mirrors web QuoteInfo.tsx line-for-line ──────────────

  /// Customer accepted the early-setup add-on.
  bool get isEarlySetupAccepted => earlySetupStatus == 'accepted';

  /// Customer-facing extra-hours total (count × rate); 0 unless both are set.
  /// Rates are whole DKK and hours are 0.25 steps, so this is integer in
  /// practice (matches web's `extra_hours * rate`).
  int get extraHoursTotal {
    final count = extraHours ?? 0;
    final rate = extraHoursPricePerHour ?? 0;
    return (count > 0 && rate > 0) ? (count * rate).round() : 0;
  }

  bool get hasExtraHours => extraHoursTotal > 0;

  /// Base offer before accepted add-ons (early setup + extra hours).
  /// Web: `price_dkk - (isEarlySetupAccepted ? earlySetupPrice : 0) - extraHoursTotal`.
  int get originalOffer =>
      priceDkk - (isEarlySetupAccepted ? (earlySetupPrice ?? 0) : 0) - extraHoursTotal;

  /// Show the price breakdown when there are extra hours or accepted early setup.
  bool get showPriceBreakdown => hasExtraHours || isEarlySetupAccepted;

  /// DJ's share of each add-on, for the "Du bliver betalt" inclusions.
  int get extraHoursPayoutAddon => (extraHoursTotal * _payoutShare).round();
  int get earlySetupPayoutAddon => ((earlySetupPrice ?? 0) * _payoutShare).round();
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
