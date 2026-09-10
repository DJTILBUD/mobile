import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/domain/ready_for_billing_gate.dart';
import 'package:flutter_test/flutter_test.dart';

/// The DJ closes the deal only after every WINNING musician has contacted the
/// customer. Enforced server-side by both ready-for-billing routes; this pins the
/// client-side gate that keeps the DJ from tapping into that rejection.

ServiceOffer _offer({
  required int id,
  required ServiceOfferStatus status,
  required bool customerContacted,
  String instrument = 'saxofon',
}) => ServiceOffer(
  id: id,
  musicianId: 'm$id',
  priceDkk: 5000,
  instrument: instrument,
  status: status,
  createdAt: DateTime(2026, 1, 1),
  customerContacted: customerContacted,
  job: Job(
    id: 0,
    eventType: '',
    date: DateTime(2026, 1, 1),
    timeStart: '20:00',
    timeEnd: '02:00',
    city: '',
    region: '',
    guestsAmount: 0,
    status: JobStatus.open,
    createdAt: DateTime(2026, 1, 1),
  ),
);

void main() {
  group('isBlockedByMusicianContact', () {
    test('a job with no musician at all is never blocked', () {
      expect(isBlockedByMusicianContact(const []), isFalse);
    });

    test('a job whose only offers are sent/lost is not blocked', () {
      // A losing or still-pending musician has no obligation to contact anyone —
      // blocking on them would freeze every DJ-only job that ever took a bid.
      expect(
        isBlockedByMusicianContact([
          _offer(id: 1, status: ServiceOfferStatus.sent, customerContacted: false),
          _offer(id: 2, status: ServiceOfferStatus.lost, customerContacted: false),
        ]),
        isFalse,
      );
    });

    test('blocked while a WON musician has not contacted the customer', () {
      expect(
        isBlockedByMusicianContact([
          _offer(id: 1, status: ServiceOfferStatus.won, customerContacted: false),
        ]),
        isTrue,
      );
    });

    test('not blocked once every won musician has contacted the customer', () {
      expect(
        isBlockedByMusicianContact([
          _offer(id: 1, status: ServiceOfferStatus.won, customerContacted: true),
          _offer(id: 2, status: ServiceOfferStatus.lost, customerContacted: false),
        ]),
        isFalse,
      );
    });

    test('one un-contacted winner blocks even when another winner is done', () {
      expect(
        isBlockedByMusicianContact([
          _offer(id: 1, status: ServiceOfferStatus.won, customerContacted: true),
          _offer(id: 2, status: ServiceOfferStatus.won, customerContacted: false),
        ]),
        isTrue,
      );
    });
  });

  group('musicianContactBlockedMessage', () {
    test('names the instrument when every blocker shares one', () {
      expect(
        musicianContactBlockedMessage([
          _offer(
            id: 1,
            status: ServiceOfferStatus.won,
            customerContacted: false,
            instrument: 'Saxofon',
          ),
        ]),
        startsWith('Saxofonisten skal også kontakte kunden'),
      );
    });

    test('falls back to neutral wording for a mixed line-up', () {
      expect(
        musicianContactBlockedMessage([
          _offer(
            id: 1,
            status: ServiceOfferStatus.won,
            customerContacted: false,
            instrument: 'saxofon',
          ),
          _offer(
            id: 2,
            status: ServiceOfferStatus.won,
            customerContacted: false,
            instrument: 'violin',
          ),
        ]),
        startsWith('Musikeren skal også kontakte kunden'),
      );
    });

    test('ignores winners who have already contacted the customer', () {
      // The message must describe who we are still waiting for, not the whole band.
      expect(
        musicianContactBlockedMessage([
          _offer(
            id: 1,
            status: ServiceOfferStatus.won,
            customerContacted: true,
            instrument: 'saxofon',
          ),
          _offer(
            id: 2,
            status: ServiceOfferStatus.won,
            customerContacted: false,
            instrument: 'violin',
          ),
        ]),
        startsWith('Violinisten skal også kontakte kunden'),
      );
    });
  });

  group('readyForBillingErrorMessage', () {
    test('maps the Danish server reason to a DJ-actionable message', () {
      // The exact string /api/jobs/[job_id]/ready-for-billing returns.
      final msg = readyForBillingErrorMessage(
        const DatabaseException(
          'Alle vindende musikere skal have kontaktet kunden, før jobbet kan sættes til klar til fakturering.',
        ),
      );
      expect(msg, contains('instrumentalist'));
      expect(msg, isNot('Noget gik galt. Prøv igen.'));
    });

    test('maps the legacy English reason too', () {
      final msg = readyForBillingErrorMessage(
        const DatabaseException(
          'All winning musicians must contact the customer before marking the job ready for billing.',
        ),
      );
      expect(msg, contains('instrumentalist'));
    });

    test('maps the customer-not-contacted reason', () {
      expect(
        readyForBillingErrorMessage(
          const DatabaseException(
            'Kunden skal markeres som kontaktet, før jobbet kan sættes til klar til fakturering.',
          ),
        ),
        contains('markere kunden som kontaktet'),
      );
    });

    test('falls back to the generic message when there is no exception', () {
      expect(readyForBillingErrorMessage(null), 'Noget gik galt. Prøv igen.');
    });
  });
}
