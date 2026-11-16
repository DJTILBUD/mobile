import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/jobs/domain/bid_withdrawal.dart';

// Mirrors web-app/src/helpers/bidWithdrawal.test.ts (isWithinBidWithdrawWindow).
void main() {
  group('isWithinBidWithdrawWindow', () {
    final created = DateTime.parse('2026-10-27T10:00:00.000Z');

    test('open until exactly 10 minutes after the bid', () {
      expect(
        isWithinBidWithdrawWindow(
          created,
          DateTime.parse('2026-10-27T10:09:59.000Z'),
        ),
        isTrue,
      );
      expect(
        isWithinBidWithdrawWindow(
          created,
          DateTime.parse('2026-10-27T10:10:00.000Z'),
        ),
        isTrue,
      );
    });

    test('closed after 10 minutes', () {
      expect(
        isWithinBidWithdrawWindow(
          created,
          DateTime.parse('2026-10-27T10:10:01.000Z'),
        ),
        isFalse,
      );
    });

    test('a missing timestamp is never withdrawable', () {
      expect(isWithinBidWithdrawWindow(null, DateTime.now()), isFalse);
    });

    test('compares instants, not wall clocks (offset timestamps)', () {
      final withOffset = DateTime.parse('2026-10-27T12:00:00+02:00');
      expect(
        isWithinBidWithdrawWindow(
          withOffset,
          DateTime.parse('2026-10-27T10:05:00.000Z'),
        ),
        isTrue,
      );
    });
  });

  group('bidWithdrawDeadline / countdown', () {
    final created = DateTime.parse('2026-10-27T10:00:00.000Z');

    test('deadline is 10 minutes after the bid', () {
      expect(
        bidWithdrawDeadline(created),
        DateTime.parse('2026-10-27T10:10:00.000Z'),
      );
    });

    test('seconds left never go negative', () {
      expect(
        bidWithdrawSecondsLeft(
          created,
          DateTime.parse('2026-10-27T10:08:30.000Z'),
        ),
        90,
      );
      expect(
        bidWithdrawSecondsLeft(
          created,
          DateTime.parse('2026-10-27T10:20:00.000Z'),
        ),
        0,
      );
    });

    test('formats mm:ss', () {
      expect(formatBidWithdrawCountdown(600), '10:00');
      expect(formatBidWithdrawCountdown(65), '01:05');
      expect(formatBidWithdrawCountdown(-3), '00:00');
    });
  });

  group('pinBidsInWithdrawWindow', () {
    final now = DateTime.utc(2026, 10, 27, 10, 20);
    final bids = <(int, DateTime)>[
      (1, DateTime.utc(2026, 10, 27, 9)),
      (2, DateTime.utc(2026, 10, 27, 10, 15)),
      (3, DateTime.utc(2026, 10, 27, 8)),
      (4, DateTime.utc(2026, 10, 27, 10, 12)),
    ];

    test('bids inside the window go first, order kept in both groups', () {
      final pinned = pinBidsInWithdrawWindow(bids, (b) => b.$2, now);
      expect(pinned.map((b) => b.$1), [2, 4, 1, 3]);
    });

    test('no bid inside the window leaves the order untouched', () {
      final later = DateTime.utc(2026, 10, 27, 11);
      final pinned = pinBidsInWithdrawWindow(bids, (b) => b.$2, later);
      expect(pinned.map((b) => b.$1), [1, 2, 3, 4]);
    });

    test('time until the first window ends', () {
      expect(
        timeUntilNextBidWindowEnd(bids.map((b) => b.$2), now),
        const Duration(minutes: 2),
      );
      expect(timeUntilNextBidWindowEnd([bids[0].$2, null], now), isNull);
    });
  });
}
