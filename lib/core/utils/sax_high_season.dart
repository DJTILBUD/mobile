// Mirrors web-app/src/helpers/saxHighSeason.ts. Change both together.
//
// High season for saxophone pricing. Two windows, picked by when the JOB was created (see
// [isSaxSeasonPricingActive]): Saturdays in August for jobs created on/after
// [saxAugustSaturdaysStart] ([isSaxHighSeason]), and the older wide window for jobs created before it
// ([isLegacySaxHighSeason]), so a job whose customer was already quoted a season price never reprices.
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

/// Jobs created on/after this instant use Saturdays in August only. Jobs created between
/// [saxSeasonPricingStart] and this keep the wide window. Keep byte-identical to
/// `SAX_AUGUST_SATURDAYS_START` in the web helper.
final saxAugustSaturdaysStart = DateTime.utc(2026, 10, 28);

/// One-off high-demand dates for the LEGACY window ([isLegacySaxHighSeason]) that fall outside its
/// recurring weekend rule. Empty since the
/// 2026-09-28 rule change: every date that used to be listed here is now covered by the rule itself.
/// Keep the mechanism for a genuine one-off. Keep in sync with the web helper and
/// `EXTRA_SPECIAL_QUOTE_DATES` in dj-form.
const saxHighSeasonExtraDates = <String>{};

String _isoDate(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-'
    '${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}';

/// Is this event date in saxophone high season? Current rule (jobs created on/after
/// [saxAugustSaturdaysStart]), every year: Saturdays in August only.
bool isSaxHighSeason(DateTime? eventDate) {
  if (eventDate == null) return false;
  return eventDate.month == 8 && eventDate.weekday == DateTime.saturday;
}

/// The older, wide window (rule from 2026-09-28). Applies only to jobs created before
/// [saxAugustSaturdaysStart].
///
/// Fridays and Saturdays only, within: April through September, the FIRST weekend of October (the
/// first Saturday of October and the Friday before it), and all of November and December, plus any
/// one-off date in [saxHighSeasonExtraDates].
///
/// The date is read as the calendar day it names. `Jobs.date` / `ExtJobs.date` are plain date
/// columns, and a UTC-parsed value would land on the previous day west of UTC, shifting weekends out
/// of the window.
bool isLegacySaxHighSeason(DateTime? eventDate) {
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

/// The full gate for season sax pricing: the job must have been created on/after the rollout date,
/// and the event date must be in the window that applies to the job's creation date.
///
/// A missing [jobCreatedAt] counts as a brand-new job (current window), matching how the price
/// helpers already treat a missing creation date (steady state, not legacy).
bool isSaxSeasonPricingActive(DateTime? jobCreatedAt, DateTime? eventDate) {
  if (jobCreatedAt == null) return isSaxHighSeason(eventDate);
  final createdAt = jobCreatedAt.toUtc();
  if (createdAt.isBefore(saxSeasonPricingStart)) return false;
  if (createdAt.isBefore(saxAugustSaturdaysStart)) {
    return isLegacySaxHighSeason(eventDate);
  }
  return isSaxHighSeason(eventDate);
}
