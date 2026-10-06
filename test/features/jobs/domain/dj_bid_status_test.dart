import 'package:dj_tilbud_app/features/jobs/domain/dj_bid_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DjBidStatus.fromJson', () {
    test('parses a blocked answer with reason + message', () {
      final s = DjBidStatus.fromJson({
        'can_bid': false,
        'reason': 'full',
        'message':
            'Dette job har allerede modtaget det maksimale antal tilbud.',
      });
      expect(s.canBid, isFalse);
      expect(s.reason, 'full');
      expect(s.message, contains('maksimale'));
      expect(s.title, 'Jobbet kan ikke modtage flere tilbud');
    });

    test('parses an open answer', () {
      final s = DjBidStatus.fromJson({
        'can_bid': true,
        'reason': null,
        'message': null,
      });
      expect(s.canBid, isTrue);
      expect(s.reason, isNull);
    });

    test(
      'fails OPEN on a malformed body — never blocks on absence of evidence',
      () {
        expect(DjBidStatus.fromJson({}).canBid, isTrue);
        expect(DjBidStatus.fromJson({'can_bid': 'no'}).canBid, isTrue);
      },
    );

    test('title per reason', () {
      expect(
        const DjBidStatus(canBid: false, reason: 'already_bid').title,
        'Du har allerede budt på jobbet',
      );
      expect(
        const DjBidStatus(canBid: false, reason: 'tier_quota').title,
        'Jobbet kan ikke modtage flere tilbud',
      );
      expect(
        const DjBidStatus(canBid: false, reason: 'not_biddable_status').title,
        'Jobbet er ikke længere åbent for bud',
      );
      expect(
        const DjBidStatus(canBid: false, reason: 'not_found').title,
        'Jobbet er ikke længere åbent for bud',
      );
    });
  });
}
