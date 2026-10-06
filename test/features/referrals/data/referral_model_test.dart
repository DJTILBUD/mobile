import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/referrals/data/models/referral_model.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';

/// Guards the JSON contract with `GET/POST /api/referrals` (web `ReferralListItem` and the
/// create response). `reward_dkk` arrives as a numeric string from Postgres, so parsing must
/// tolerate both a number and a string.
void main() {
  test('fromJson + toEntity map a list item', () {
    final model = ReferralModel.fromJson({
      'id': 7,
      'type': 'saxophonist_referral',
      'status': 'closed',
      'reward_dkk': '500',
      'created_at': '2026-09-14T08:00:00+00:00',
      'closed_at': '2026-09-20T08:00:00+00:00',
      'canceled_at': null,
      'canceled_reason': null,
      'job': {
        'id': 99,
        'lead_name': 'Mette',
        'date': '2026-11-21',
        'event_type': 'Bryllup',
        'location': 'Aarhus',
        'status': 'ready_for_billing',
      },
      'payout_status': 'pending',
    });
    final r = model.toEntity();
    expect(r.id, 7);
    expect(r.type, ReferralType.saxophonistReferral);
    expect(r.status, ReferralStatus.closed);
    expect(r.rewardDkk, 500);
    expect(r.job?.leadName, 'Mette');
    expect(r.job?.date, DateTime(2026, 11, 21));
    expect(r.job?.status, 'ready_for_billing');
    expect(r.payoutStatus, 'pending');
  });

  test('a missing job leaves job null instead of throwing', () {
    final r =
        ReferralModel.fromJson({
          'id': 1,
          'type': 'dj_referral',
          'status': 'open',
          'reward_dkk': 500,
          'created_at': '2026-09-14T08:00:00Z',
          'job': null,
        }).toEntity();
    expect(r.job, isNull);
    expect(r.payoutStatus, isNull);
  });

  test('fromCreateResponse folds the created ExtJob into the item shape', () {
    final r =
        ReferralModel.fromCreateResponse(
          {
            'id': 3,
            'type': 'dj_referral',
            'status': 'open',
            'reward_dkk': 500,
            'created_at': '2026-09-14T08:00:00Z',
          },
          {
            'id': 55,
            'lead_name': 'Ole',
            'date': '2026-10-10',
            'event_type': null,
            'location': 'Odense',
            'status': 'open',
          },
        ).toEntity();
    expect(r.job?.id, 55);
    expect(r.job?.location, 'Odense');
    expect(r.status, ReferralStatus.open);
  });

  test('inputToJson matches the POST body schema', () {
    final json = ReferralModel.inputToJson(
      ReferralInput(
        leadName: ' Mette ',
        phoneNumber: '12345678',
        date: DateTime(2026, 11, 21),
        eventType: 'Bryllup',
        region: 'Østjylland',
        email: '',
        roleType: ReferralRoleType.djAndMusician,
        notes: '  ',
      ),
    );
    expect(json, {
      'lead_name': 'Mette',
      'phone_number': '12345678',
      'email': null,
      'date': '2026-11-21',
      'event_type': 'Bryllup',
      'region': 'Østjylland',
      'location': null,
      'guests_amount': null,
      'role_type': 'dj_and_musician',
      'notes': null,
    });
  });
}
