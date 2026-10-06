import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/notifications/domain/stale_bid_notifications.dart';

void main() {
  group('DJ "Nyt job" invitations', () {
    test('stays while the job still takes quotes', () {
      for (final status in kJobStatusesOpenToQuotes) {
        expect(
          isBidInvitationStale(
            type: 'new_job',
            role: 'dj',
            state: JobBidState(status: status),
          ),
          isFalse,
          reason: status,
        );
      }
    });

    test('clears once the job is booked or dead', () {
      for (final status in [
        'closed',
        'customer_contacted',
        'ready_for_billing',
        'expired',
        'canceled',
        'lost',
      ]) {
        expect(
          isBidInvitationStale(
            type: 'new_job',
            role: 'dj',
            state: JobBidState(status: status),
          ),
          isTrue,
          reason: status,
        );
      }
    });

    test('another_round is treated the same as new_job', () {
      expect(
        isBidInvitationStale(
          type: 'another_round',
          role: 'dj',
          state: const JobBidState(status: 'closed'),
        ),
        isTrue,
      );
    });

    test('an unreadable job (archived) clears', () {
      expect(
        isBidInvitationStale(type: 'new_job', role: 'dj', state: null),
        isTrue,
      );
    });
  });

  group('saxophonist invitations', () {
    test('a closed internal job still takes sax offers, so it stays', () {
      // A booked DJ does not fill the sax slot — this is the one place the DJ
      // and musician status sets differ on the same table.
      expect(
        isBidInvitationStale(
          type: 'new_job',
          role: 'musician',
          state: const JobBidState(status: 'closed'),
        ),
        isFalse,
      );
    });

    test('an unknown role uses the wider set, so it under-clears', () {
      expect(
        isBidInvitationStale(
          type: 'new_job',
          role: null,
          state: const JobBidState(status: 'closed'),
        ),
        isFalse,
      );
    });

    test('an ext job someone else won clears, both ways of winning', () {
      expect(
        isBidInvitationStale(
          type: 'new_ext_job',
          role: 'musician',
          state: const JobBidState(status: 'sent', hasWonOffer: true),
        ),
        isTrue,
      );
      expect(
        isBidInvitationStale(
          type: 'new_ext_job',
          role: 'musician',
          state: const JobBidState(status: 'sent', assignedMusicianId: 'a1b2'),
        ),
        isTrue,
      );
    });

    test('an open ext job with nobody on it stays', () {
      expect(
        isBidInvitationStale(
          type: 'new_ext_job',
          role: 'musician',
          state: const JobBidState(status: 'open'),
        ),
        isFalse,
      );
    });

    test('ready_for_billing clears an ext job invitation', () {
      expect(
        isBidInvitationStale(
          type: 'new_ext_job',
          role: 'musician',
          state: const JobBidState(status: 'ready_for_billing'),
        ),
        isTrue,
      );
    });
  });

  test('non-invitation types are never auto-cleared', () {
    // These are about a job the user is already on — clearing them would hide
    // something they still have to act on.
    for (final type in [
      'quote_won',
      'chat_message',
      'ready_reminder',
      'send_invoice_reminder',
      'admin_message',
      'custom_notification',
    ]) {
      expect(
        isBidInvitationStale(type: type, role: 'dj', state: null),
        isFalse,
        reason: type,
      );
    }
  });
}
