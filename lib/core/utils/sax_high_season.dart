// Mirrors web-app/src/helpers/saxHighSeason.ts. Change both together.
//
// High season for saxophone pricing. This is the SAME window dj-form uses to decide a booking gets
// one hand-picked DJ instead of three quotes (`isDateInSpecialQuoteWindow`).
//
// Keyed on the EVENT date, never on createdAt: a June wedding booked in January is still a
// high-season event. Season pricing needs BOTH that and the rollout cutoff — see
// [isSaxSeasonPricingActive].

/// Jobs created on/after this instant get season prices when their event date is in season. Jobs
/// created before it keep the standard table no matter when the event falls, so nothing already in
/// flight reprices under a musician who has an offer out.
///
/// Monday 2026-08-24, the date this build ships. The web-app deploys ahead of it, which is safe: the
/// offer endpoint recomputes price and payout server-side, so an older binary can only display stale
/// figures, never store them. Keep byte-identical to `SAX_SEASON_PRICING_START` in the web helper.
final saxSeasonPricingStart = DateTime.utc(2026, 8, 24);

/// One-off high-demand dates that don't fit the recurring Saturday rule below.
///
/// Each year follows the same shape: the last two Fridays of August, the third and fourth Saturdays
/// of September (the recurring rule stops at 14 September), and the julefrokost Fridays — last Friday
/// of November plus the first two Fridays of December.
///
/// These run out after 2027-12-10. Without new entries the 2028 season silently narrows to the
/// Saturday rule alone — add next year's dates before the season starts. Keep in sync with the web
/// helper and `EXTRA_SPECIAL_QUOTE_DATES` in dj-form.
const saxHighSeasonExtraDates = <String>{
  '2026-08-21',
  '2026-08-28',
  '2026-09-19',
  '2026-09-26',
  '2026-11-27',
  '2026-12-04',
  '2026-12-11',
  '2027-08-20',
  '2027-08-27',
  '2027-09-18',
  '2027-09-25',
  '2027-11-26',
  '2027-12-03',
  '2027-12-10',
};

String _isoDate(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-'
    '${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}';

/// Is this event date in saxophone high season?
///
/// Saturdays only, within: 18-31 May, all of June, 4 July only, all of August, 1-14 September — plus
/// the explicit one-off dates in [saxHighSeasonExtraDates].
///
/// The date is read as the calendar day it names. `Jobs.date` / `ExtJobs.date` are plain date
/// columns, and a UTC-parsed value would land on the previous day west of UTC, shifting Saturdays out
/// of the window.
bool isSaxHighSeason(DateTime? eventDate) {
  if (eventDate == null) return false;

  final year = eventDate.year;
  final month = eventDate.month;
  final day = eventDate.day;

  if (saxHighSeasonExtraDates.contains(_isoDate(year, month, day))) return true;

  // DateTime.weekday is 1=Mon..7=Sun, so Saturday is 6.
  if (eventDate.weekday != DateTime.saturday) return false;

  final isLastTwoWeeksMay = month == 5 && day >= 18;
  final isAllJune = month == 6;
  final isOnlyFourthJuly = month == 7 && day == 4;
  final isAllAugust = month == 8;
  final isFirstTwoWeeksSeptember = month == 9 && day <= 14;

  return isLastTwoWeeksMay ||
      isAllJune ||
      isOnlyFourthJuly ||
      isAllAugust ||
      isFirstTwoWeeksSeptember;
}

/// The full gate for season sax pricing: the event must be in season AND the job must have been
/// created on/after the rollout date.
///
/// A missing [jobCreatedAt] counts as post-launch, matching how the price helpers already treat a
/// missing creation date (steady state, not legacy).
bool isSaxSeasonPricingActive(DateTime? jobCreatedAt, DateTime? eventDate) {
  if (!isSaxHighSeason(eventDate)) return false;
  if (jobCreatedAt == null) return true;
  return !jobCreatedAt.toUtc().isBefore(saxSeasonPricingStart);
}
