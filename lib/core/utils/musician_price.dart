// Mirrors calculateMusicianOfferPrice and calculateCustomerMusicianPrice
// from the web app (web-app/src/helpers/).
//
// calculateMusicianOfferPrice — what the musician is paid (payout):
//   0.5h–1.0h → 3150, 1.5h → 3500, >1.5h → 3500 + 1000/0.5h
//   After first price increase (3 days post-creation):
//     ≤0.5h +150, ≤1.0h +350, >1.0h +500
//
// calculateCustomerMusicianPrice — what the customer pays (fixed, no time bonus):
//   ≤0.5h → 3500, ≤1.0h → 4000, >1.0h → 4000 + 1000/0.5h

DateTime _calculateFirstPriceIncreaseTime(DateTime createdAt) {
  final hour = createdAt.hour;
  final threeDaysLater = createdAt.add(const Duration(days: 3));
  return DateTime(
    threeDaysLater.year,
    threeDaysLater.month,
    threeDaysLater.day,
    (hour < 8 || hour >= 20) ? 15 : 8,
    0,
    0,
  );
}

int calculateMusicianOfferPrice(double? requestedHours, [DateTime? createdAt]) {
  final hours = (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;

  int basePrice;
  if (hours <= 1.0) {
    basePrice = 3150;
  } else if (hours <= 1.5) {
    basePrice = 3500;
  } else {
    final increments = ((hours - 1.5) / 0.5).ceil();
    basePrice = 3500 + increments * 1000;
  }

  if (createdAt == null) return basePrice;

  final firstIncreaseTime = _calculateFirstPriceIncreaseTime(createdAt);
  if (DateTime.now().isBefore(firstIncreaseTime)) return basePrice;

  final int bonus;
  if (hours <= 0.5) {
    bonus = 150;
  } else if (hours <= 1.0) {
    bonus = 350;
  } else {
    bonus = 500;
  }
  return basePrice + bonus;
}

int calculateCustomerMusicianPrice(double? requestedHours) {
  final hours = (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;
  if (hours <= 0.5) return 3500;
  if (hours <= 1.0) return 4000;
  final increments = ((hours - 1.0) / 0.5).ceil();
  return 4000 + increments * 1000;
}
