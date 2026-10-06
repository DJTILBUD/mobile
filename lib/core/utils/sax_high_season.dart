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

/// One-off high-demand dates that fall OUTSIDE the recurring weekend rule below. Empty since the
/// 2026-09-28 rule change: every date that used to be listed here is now covered by the rule itself.
/// Keep the mechanism for a genuine one-off. Keep in sync with the web helper and
/// `EXTRA_SPECIAL_QUOTE_DATES` in dj-form.
const saxHighSeasonExtraDates = <String>{};

String _isoDate(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-'
    '${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}';

/// Is this event date in saxophone high season? (Rule from 2026-09-28, every year.)
///
/// Fridays and Saturdays only, within: April through September, the FIRST weekend of October (the
/// first Saturday of October and the Friday before it), and all of November and December, plus any
/// one-off date in [saxHighSeasonExtraDates].
///
/// The date is read as the calendar day it names. `Jobs.date` / `ExtJobs.date` are plain date
/// columns, and a UTC-parsed value would land on the previous day west of UTC, shifting weekends out
/// of the window.
bool isSaxHighSeason(DateTime? eventDate) {
  if (eventDate == null) return false;

  final year = eventDate.year;
  final month = eventDate.month;
  final day = eventDate.day;

  if (saxHighSeasonExtraDates.contains(_isoDate(year, month, day))) return true;

  // DateTime.weekday is 1=Mon..7=Sun.
  final isFriday = eventDate.weekday == DateTime.friday;
  final isSaturday = eventDate.weekday == DateTime.saturday;
  if (!isFriday && !isSaturday) return false;

  final isAprilToSeptember = month >= 4 && month <= 9;
  // First Saturday of October is day 1-7; its Friday is day 1-6 (a Friday on the 7th belongs to the
  // weekend of the 8th, the second weekend).
  final isFirstOctoberWeekend =
      month == 10 && (isSaturday ? day <= 7 : day <= 6);
  final isNovemberDecember = month == 11 || month == 12;

  return isAprilToSeptember || isFirstOctoberWeekend || isNovemberDecember;
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
