import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';

/// Copy and state logic for the referral screen. MIRRORS `jobState()` / `rewardState()` in
/// web-app/src/components/referrals/ReferralsPage.tsx line for line; change both together.
/// Describes the job's state, never the performer's standing.

/// Mirror of web-app `REFERRAL_REWARD_DKK`. Display only: the real amount is frozen server-side
/// on `Referrals.reward_dkk` and comes back on every item.
const int referralRewardDkk = 500;

enum ReferralJobTone { neutral, progress, success }

class ReferralJobState {
  const ReferralJobState(this.label, this.tone);
  final String label;
  final ReferralJobTone tone;
}

ReferralJobState referralJobState(Referral item) {
  if (item.status == ReferralStatus.canceled) {
    return const ReferralJobState('Ikke gennemført', ReferralJobTone.neutral);
  }
  if (item.status == ReferralStatus.closed) {
    return const ReferralJobState('Gennemført', ReferralJobTone.success);
  }
  final status = item.job?.status;
  if (status == 'closed' || status == 'customer_contacted') {
    return const ReferralJobState('Performer booket', ReferralJobTone.success);
  }
  if (status == 'sent') {
    return const ReferralJobState(
      'Tilbud sendt til kunden',
      ReferralJobTone.progress,
    );
  }
  return const ReferralJobState(
    'Vi kontakter kunden',
    ReferralJobTone.progress,
  );
}

/// The reward line under a closed referral; null while the referral is not closed.
String? referralRewardState(Referral item) {
  if (item.status != ReferralStatus.closed) return null;
  final reward = '${item.rewardDkk} kr.';
  switch (item.payoutStatus) {
    case 'paid':
      return '$reward er udbetalt';
    case 'issued':
    case 'in_batch':
      return '$reward er på vej til din konto';
    // The reward is not self-billed (2026-09-23): the referrer invoices us and it is paid by hand.
    // Mirrors web ReferralsPage.tsx.
    default:
      return 'Send en faktura på $reward til regnskab@djtilbud.dk, så udbetaler vi beløbet';
  }
}

const List<String> _danishMonths = [
  'januar',
  'februar',
  'marts',
  'april',
  'maj',
  'juni',
  'juli',
  'august',
  'september',
  'oktober',
  'november',
  'december',
];

/// "21. november 2026", the same shape as the web page's `da-DK` long date.
String formatReferralDate(DateTime d) =>
    '${d.day}. ${_danishMonths[d.month - 1]} ${d.year}';

/// The one-line job summary on a card: "Bryllup · 21. november 2026 · Aarhus".
String referralJobSummary(ReferralJob? job) {
  if (job == null) return '';
  return [
    job.eventType,
    formatReferralDate(job.date),
    job.location,
  ].where((p) => p != null && p.isNotEmpty).join(' · ');
}

/// The event types the customer DJ booking form offers (dj-form EVENT_TYPES), stored as the
/// same Danish label. MIRROR of web `REFERRAL_EVENT_TYPES` (web-app/src/helpers/referrals.ts).
const List<String> referralEventTypes = [
  'Bryllup',
  'Firmafest',
  'Fødselsdagsfest',
  'Julefrokost',
  'Privatfest',
  'Ungdomsfest',
  'Klub/Bar',
  'Lounge',
  'Andet',
];

/// The `region` enum in the order the customer forms list them. Mirror of web `REFERRAL_REGIONS`.
const List<String> referralRegions = [
  'Hovedstaden',
  'Bornholm',
  'Fyn',
  'Nordjylland',
  'Nordsjælland',
  'Østjylland',
  'Sønderjylland',
  'Sydsjælland',
  'Vestjylland',
  'Vestsjælland',
];

/// Same rule as dj-form/web `canSubmit`: name, a LOCAL phone number of at least 6 digits (the
/// country code is separate and always valid, since it comes from the dropdown), a date, an
/// event type and a region.
bool referralInputIsComplete({
  required String leadName,
  required String phoneLocal,
  required DateTime? date,
  required String? eventType,
  required String? region,
}) {
  return leadName.trim().isNotEmpty &&
      phoneLocal.length >= 6 &&
      date != null &&
      eventType != null &&
      region != null;
}

String roleTypeApiValue(ReferralRoleType t) => switch (t) {
  ReferralRoleType.djOnly => 'dj_only',
  ReferralRoleType.musicianOnly => 'musician_only',
  ReferralRoleType.djAndMusician => 'dj_and_musician',
};

String roleTypeLabel(ReferralRoleType t) => switch (t) {
  ReferralRoleType.djOnly => 'En DJ',
  ReferralRoleType.musicianOnly => 'En saxofonist',
  ReferralRoleType.djAndMusician => 'Både DJ og saxofonist',
};
