/// Pricing helpers for musician service offers.
/// Ported 1-to-1 from web-app/src/helpers/calculateMusicianOfferPrice.ts
/// and calculateCustomerMusicianPrice.ts.

/// What the musician earns (musician_payout_dkk).
/// Time-based: the price increases after a threshold derived from when the job
/// was created.
///
/// Tiers (base price):
///   ≤ 1.0 h  → 3 150 DKK
///   ≤ 1.5 h  → 3 500 DKK
///   > 1.5 h  → 3 500 + ceil((hours − 1.5) / 0.5) × 1 000
///
/// Increase bonus (applied after the threshold time):
///   ≤ 0.5 h  → +150
///   ≤ 1.0 h  → +350
///   > 1.0 h  → +500
///
/// Threshold time (based on job creation time):
///   before 08:00       → 15:00 same day
///   08:00 – 20:00      → 08:00 next day
///   after  20:00       → 15:00 next day
int calculateMusicianOfferPrice(double? requestedHours, DateTime createdAt) {
  final hours = (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;

  // Base price
  final int basePrice;
  if (hours <= 1.0) {
    basePrice = 3150;
  } else if (hours <= 1.5) {
    basePrice = 3500;
  } else {
    final increments = ((hours - 1.5) / 0.5).ceil();
    basePrice = 3500 + increments * 1000;
  }

  // Check if we've passed the first price-increase threshold
  final threshold = _firstIncreaseTime(createdAt);
  if (DateTime.now().isBefore(threshold)) return basePrice;

  // Apply bonus
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

DateTime _firstIncreaseTime(DateTime sentAt) {
  final hour = sentAt.hour;
  if (hour < 8) {
    return DateTime(sentAt.year, sentAt.month, sentAt.day, 15);
  } else if (hour < 20) {
    final next = sentAt.add(const Duration(days: 1));
    return DateTime(next.year, next.month, next.day, 8);
  } else {
    final next = sentAt.add(const Duration(days: 1));
    return DateTime(next.year, next.month, next.day, 15);
  }
}

/// What the customer pays (price_dkk) — fixed, does not change with time.
///
/// Tiers:
///   ≤ 0.5 h  → 3 500 DKK
///   ≤ 1.0 h  → 4 000 DKK
///   > 1.0 h  → 4 000 + ceil((hours − 1.0) / 0.5) × 1 000
int calculateCustomerMusicianPrice(double? requestedHours) {
  final hours = (requestedHours == null || requestedHours <= 0) ? 0.0 : requestedHours;
  if (hours <= 0.5) return 3500;
  if (hours <= 1.0) return 4000;
  final increments = ((hours - 1.0) / 0.5).ceil();
  return 4000 + increments * 1000;
}
