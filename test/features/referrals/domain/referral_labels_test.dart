import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/referral_labels.dart';

/// Pins the state/reward copy to the web `ReferralsPage.tsx` (`jobState` / `rewardState`),
/// which is the source of truth. A drift here shows a DJ a different story on the phone than
/// on the web for the same referral.
Referral _ref({
  ReferralStatus status = ReferralStatus.open,
  String? jobStatus = 'open',
  String? payout,
  int reward = 500,
}) {
  return Referral(
    id: 1,
    type: ReferralType.djReferral,
    status: status,
    rewardDkk: reward,
    createdAt: DateTime(2026, 9, 14),
    payoutStatus: payout,
    job:
        jobStatus == null
            ? null
            : ReferralJob(
              id: 9,
              leadName: 'Mette',
              date: DateTime(2026, 11, 21),
              status: jobStatus,
              eventType: 'Bryllup',
              location: 'Aarhus',
            ),
  );
}

void main() {
  group('referralJobState', () {
    test('open referral describes where the job is', () {
      expect(referralJobState(_ref()).label, 'Vi kontakter kunden');
      expect(
        referralJobState(_ref(jobStatus: 'sent')).label,
        'Tilbud sendt til kunden',
      );
      expect(
        referralJobState(_ref(jobStatus: 'closed')).label,
        'Performer booket',
      );
      expect(
        referralJobState(_ref(jobStatus: 'customer_contacted')).label,
        'Performer booket',
      );
    });

    test('closed and canceled referrals win over the job status', () {
      expect(
        referralJobState(
          _ref(status: ReferralStatus.closed, jobStatus: 'ready_for_billing'),
        ).label,
        'Gennemført',
      );
      expect(
        referralJobState(
          _ref(status: ReferralStatus.canceled, jobStatus: 'canceled'),
        ).label,
        'Ikke gennemført',
      );
      expect(
        referralJobState(_ref(status: ReferralStatus.canceled)).tone,
        ReferralJobTone.neutral,
      );
    });
  });

  group('referralRewardState', () {
    test('is null until the referral is closed', () {
      expect(referralRewardState(_ref()), isNull);
      expect(
        referralRewardState(_ref(status: ReferralStatus.canceled)),
        isNull,
      );
    });

    test('follows the payout status', () {
      expect(
        referralRewardState(_ref(status: ReferralStatus.closed)),
        'Send en faktura på 500 kr. til regnskab@djtilbud.dk, så udbetaler vi beløbet',
      );
      expect(
        referralRewardState(
          _ref(status: ReferralStatus.closed, payout: 'pending'),
        ),
        'Send en faktura på 500 kr. til regnskab@djtilbud.dk, så udbetaler vi beløbet',
      );
      expect(
        referralRewardState(
          _ref(status: ReferralStatus.closed, payout: 'in_batch'),
        ),
        '500 kr. er på vej til din konto',
      );
      expect(
        referralRewardState(
          _ref(status: ReferralStatus.closed, payout: 'paid'),
        ),
        '500 kr. er udbetalt',
      );
    });
  });

  test('formatting and summary', () {
    expect(formatReferralDate(DateTime(2026, 11, 21)), '21. november 2026');
    expect(
      referralJobSummary(_ref().job),
      'Bryllup · 21. november 2026 · Aarhus',
    );
    expect(referralJobSummary(null), '');
  });

  test('referralInputIsComplete mirrors the web canSubmit rule', () {
    bool ok({
      String name = 'Mette',
      String phone = '12345678',
      String? type = 'Bryllup',
      String? region = 'Fyn',
    }) => referralInputIsComplete(
      leadName: name,
      phoneLocal: phone,
      date: DateTime(2026, 1, 1),
      eventType: type,
      region: region,
    );
    expect(ok(), isTrue);
    expect(ok(name: ' '), isFalse);
    expect(ok(phone: '12345'), isFalse);
    expect(ok(type: null), isFalse);
    expect(ok(region: null), isFalse);
    expect(
      referralInputIsComplete(
        leadName: 'Mette',
        phoneLocal: '12345678',
        date: null,
        eventType: 'Bryllup',
        region: 'Fyn',
      ),
      isFalse,
    );
  });

  test('dropdown lists mirror the customer DJ booking form', () {
    expect(referralEventTypes, [
      'Bryllup',
      'Firmafest',
      'Fødselsdagsfest',
      'Julefrokost',
      'Privatfest',
      'Ungdomsfest',
      'Klub/Bar',
      'Lounge',
      'Andet',
    ]);
    expect(referralRegions.length, 10);
    expect(referralRegions.first, 'Hovedstaden');
  });

  test('role type maps to the API enum', () {
    expect(roleTypeApiValue(ReferralRoleType.djOnly), 'dj_only');
    expect(roleTypeApiValue(ReferralRoleType.musicianOnly), 'musician_only');
    expect(roleTypeApiValue(ReferralRoleType.djAndMusician), 'dj_and_musician');
  });
}
