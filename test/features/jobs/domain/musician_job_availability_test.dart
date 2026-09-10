import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/jobs/domain/musician_job_availability.dart';

const me = 'musician-me';
const other = 'musician-other';

MusicianJobAvailability resolve({
  String? status = 'open',
  bool isExtJob = true,
  String? assignedMusicianId,
  List<({String? musicianId, String? status})> offers = const [],
}) => resolveMusicianJobAvailability(
  status: status,
  isExtJob: isExtJob,
  assignedMusicianId: assignedMusicianId,
  currentMusicianId: me,
  offers: offers,
);

void main() {
  group('resolveMusicianJobAvailability', () {
    test('an open ext job with no offers is biddable', () {
      expect(resolve(), MusicianJobAvailability.biddable);
    });

    test('another musician having merely SENT an offer does not block', () {
      // Multiple sax offers on one job are allowed — the slot is still winnable.
      expect(
        resolve(offers: [(musicianId: other, status: 'sent')]),
        MusicianJobAvailability.biddable,
      );
    });

    test('another musician having WON blocks', () {
      expect(
        resolve(offers: [(musicianId: other, status: 'won')]),
        MusicianJobAvailability.wonByAnother,
      );
    });

    // An admin-assigned musician wins with NO offer row at all, so the won-offer check alone
    // misses it. This is the same "won offer OR assigned_musician_id" pair the invoicing and
    // iCal paths resolve.
    test('an admin-assigned musician blocks even with no offers', () {
      expect(
        resolve(assignedMusicianId: other),
        MusicianJobAvailability.wonByAnother,
      );
    });

    test('being the assigned musician yourself does not block', () {
      expect(resolve(assignedMusicianId: me), MusicianJobAvailability.biddable);
    });

    test('my own existing offer reports alreadyBid', () {
      expect(
        resolve(offers: [(musicianId: me, status: 'sent')]),
        MusicianJobAvailability.alreadyBid,
      );
    });

    // Order matters: if someone else won, that is the useful message, not "you already bid".
    test('wonByAnother wins over alreadyBid when I hold a losing offer', () {
      expect(
        resolve(
          offers: [
            (musicianId: me, status: 'lost'),
            (musicianId: other, status: 'won'),
          ],
        ),
        MusicianJobAvailability.wonByAnother,
      );
    });

    test(
      'the reported bug: a ready_for_billing ext job is closed for offers',
      () {
        expect(
          resolve(status: 'ready_for_billing'),
          MusicianJobAvailability.closedForOffers,
        );
      },
    );

    test('canceled and expired ext jobs are closed for offers', () {
      expect(
        resolve(status: 'canceled'),
        MusicianJobAvailability.closedForOffers,
      );
      expect(
        resolve(status: 'expired'),
        MusicianJobAvailability.closedForOffers,
      );
    });

    // A booked DJ does not mean the sax slot is filled, so these stay biddable.
    test('closed / customer_contacted ext jobs still accept sax offers', () {
      expect(resolve(status: 'closed'), MusicianJobAvailability.biddable);
      expect(
        resolve(status: 'customer_contacted'),
        MusicianJobAvailability.biddable,
      );
    });

    test('internal jobs use their own status set', () {
      expect(
        resolve(status: 'another_round', isExtJob: false),
        MusicianJobAvailability.biddable,
      );
      // ready_for_billing is only biddable via the separate sax-campaign path, which the feed
      // query handles (it also requires sax_round_active) — not this rule.
      expect(
        resolve(status: 'ready_for_billing', isExtJob: false),
        MusicianJobAvailability.closedForOffers,
      );
    });

    // Opposite polarity to the feed's fail-open filters, and deliberate: this only guards the
    // deep-link path, where the alternative is an offer the server will reject anyway.
    test('an unknown or null status is treated as closed', () {
      expect(resolve(status: null), MusicianJobAvailability.closedForOffers);
      expect(
        resolve(status: 'nonsense'),
        MusicianJobAvailability.closedForOffers,
      );
    });
  });
}
