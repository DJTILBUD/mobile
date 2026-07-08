// Mirrors calculateMusicianOfferPrice and calculateCustomerMusicianPrice
// from the web app (web-app/src/helpers/).
//
// calculateMusicianOfferPrice — what the musician is paid (payout):
//   ≤0.5h → 3150, ≤1.0h → 3350, ≤1.5h → 4000, >1.5h → 4000 + 800/0.5h
//
// calculateCustomerMusicianPrice — what the customer pays. Jobs created on/after
// 2026-07-06 use the 23%-margin table (customer = round(payout / 0.77)); older jobs
// keep the legacy table. Payouts unchanged.
//   new: ≤0.5h 4090, ≤1.0h 4350, ≤1.5h 5190, >1.5h 5190 + 1040/0.5h
//   old: ≤0.5h 3900, ≤1.0h 4200, ≤1.5h 5000, >1.5h 5000 + 1000/0.5h

final _saxPricingChangeDate = DateTime.utc(2026, 7, 6);

int calculateMusicianOfferPrice(double? requestedHours, [DateTime? createdAt]) {
  final hours =
      (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;
  if (hours <= 0.5) return 3150;
  if (hours <= 1.0) return 3350;
  if (hours <= 1.5) return 4000;
  final increments = ((hours - 1.5) / 0.5).ceil();
  return 4000 + increments * 800;
}

int calculateCustomerMusicianPrice(
  double? requestedHours, [
  DateTime? jobCreatedAt,
]) {
  final hours =
      (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;
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
