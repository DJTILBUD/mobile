import 'package:flutter_test/flutter_test.dart';

import 'package:dj_tilbud_app/features/jobs/domain/my_payout.dart';

// Pins the parsing of GET /api/payouts/mine (web helpers/payoutView.ts shapes the body).
void main() {
  test('null payout renders nothing', () {
    expect(MyPayout.fromResponse({'payout': null}), isNull);
    expect(MyPayout.fromResponse({}), isNull);
  });

  test('an unknown state renders nothing rather than guessing', () {
    expect(
      MyPayout.fromResponse({
        'payout': {'state': 'something_new'},
      }),
      isNull,
    );
  });

  test('parses a scheduled payout with the afregning link', () {
    final p =
        MyPayout.fromResponse({
          'payout': {
            'state': 'scheduled',
            'executionDate': '2026-09-25',
            'latestOnAccountDate': '2026-09-28',
            'isForecast': false,
            'amountDkk': 5625,
            'waitingFor': null,
            'document': {
              'sbNumber': 'SB-2026-0012',
              'url':
                  'https://app.djtilbud.dk/api/self-billing/document?token=x',
            },
          },
        })!;
    expect(p.state, MyPayoutState.scheduled);
    expect(p.executionDate, DateTime(2026, 9, 25));
    expect(p.latestOnAccountDate, DateTime(2026, 9, 28));
    expect(p.amountDkk, 5625.0);
    expect(p.documentSbNumber, 'SB-2026-0012');
    expect(p.documentUrl, contains('/api/self-billing/document'));
  });

  test('parses a waiting payout without a date or document', () {
    final p =
        MyPayout.fromResponse({
          'payout': {
            'state': 'waiting',
            'executionDate': null,
            'waitingFor': 'missing_bank',
            'document': null,
          },
        })!;
    expect(p.state, MyPayoutState.waiting);
    expect(p.executionDate, isNull);
    expect(p.waitingFor, 'missing_bank');
    expect(p.documentUrl, isNull);
  });
}
