import 'package:dj_tilbud_app/core/utils/sax_high_season.dart';

// Mirrors calculateMusicianOfferPrice and calculateCustomerMusicianPrice
// from the web app (web-app/src/helpers/).
//
// calculateMusicianOfferPrice — what the musician is paid (payout):
//   standard:    ≤0.5h → 3150, ≤1.0h → 3350, ≤1.5h → 4000, >1.5h → 4000 + 800/0.5h
//   high season: ≤0.5h → 3900, ≤1.0h → 4150, ≤1.5h → 5000, >1.5h → 5000 + 800/0.5h
//
// calculateCustomerMusicianPrice — what the customer pays. Three tables:
//   season: event date in high season AND job created on/after saxSeasonPricingStart
//           ≤0.5h 5090, ≤1.0h 5400, ≤1.5h 6490, >1.5h 6490 + 1040/0.5h
//   new:    jobs created on/after 2026-07-06 (23% margin, customer = round(payout / 0.77))
//           ≤0.5h 4090, ≤1.0h 4350, ≤1.5h 5190, >1.5h 5190 + 1040/0.5h
//   old:    everything older
//           ≤0.5h 3900, ≤1.0h 4200, ≤1.5h 5000, >1.5h 5000 + 1000/0.5h
//
// The two dates do different jobs: jobCreatedAt is a rollout cutoff, eventDate is what makes the
// price seasonal. The half-hour increment above 1.5h is deliberately unchanged in the season table —
// 800/1040 is the same 77% split as the tables themselves, so the margin holds.

final _saxPricingChangeDate = DateTime.utc(2026, 7, 6);

int calculateMusicianOfferPrice(
  double? requestedHours, [
  DateTime? jobCreatedAt,
  DateTime? eventDate,
]) {
  final hours =
      (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;

  if (isSaxSeasonPricingActive(jobCreatedAt, eventDate)) {
    if (hours <= 0.5) return 3900;
    if (hours <= 1.0) return 4150;
    if (hours <= 1.5) return 5000;
    return 5000 + ((hours - 1.5) / 0.5).ceil() * 800;
  }

  if (hours <= 0.5) return 3150;
  if (hours <= 1.0) return 3350;
  if (hours <= 1.5) return 4000;
  final increments = ((hours - 1.5) / 0.5).ceil();
  return 4000 + increments * 800;
}

int calculateCustomerMusicianPrice(
  double? requestedHours, [
  DateTime? jobCreatedAt,
  DateTime? eventDate,
]) {
  final hours =
      (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;

  if (isSaxSeasonPricingActive(jobCreatedAt, eventDate)) {
    if (hours <= 0.5) return 5090;
    if (hours <= 1.0) return 5400;
    if (hours <= 1.5) return 6490;
    return 6490 + ((hours - 1.5) / 0.5).ceil() * 1040;
  }

  final isNewPricing =
      jobCreatedAt == null ||
      !jobCreatedAt.toUtc().isBefore(_saxPricingChangeDate);
  if (isNewPricing) {
    if (hours <= 0.5) return 4090;
    if (hours <= 1.0) return 4350;
    if (hours <= 1.5) return 5190;
    return 5190 + ((hours - 1.5) / 0.5).ceil() * 1040;
  }
  if (hours <= 0.5) return 3900;
  if (hours <= 1.0) return 4200;
  if (hours <= 1.5) return 5000;
  return 5000 + ((hours - 1.5) / 0.5).ceil() * 1000;
}
