// Mirrors calculateMusicianOfferPrice and calculateCustomerMusicianPrice
// from the web app (web-app/src/helpers/).
//
// calculateMusicianOfferPrice — what the musician is paid (payout):
//   ≤0.5h → 3150, ≤1.0h → 3350, ≤1.5h → 4000, >1.5h → 4000 + 800/0.5h
//
// calculateCustomerMusicianPrice — what the customer pays:
//   ≤0.5h → 3900, ≤1.0h → 4200, ≤1.5h → 5000, >1.5h → 5000 + 1000/0.5h

int calculateMusicianOfferPrice(double? requestedHours, [DateTime? createdAt]) {
  final hours = (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;
  if (hours <= 0.5) return 3150;
  if (hours <= 1.0) return 3350;
  if (hours <= 1.5) return 4000;
  final increments = ((hours - 1.5) / 0.5).ceil();
  return 4000 + increments * 800;
}

int calculateCustomerMusicianPrice(double? requestedHours) {
  final hours = (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;
  if (hours <= 0.5) return 3900;
  if (hours <= 1.0) return 4200;
  if (hours <= 1.5) return 5000;
  final increments = ((hours - 1.5) / 0.5).ceil();
  return 5000 + increments * 1000;
}
