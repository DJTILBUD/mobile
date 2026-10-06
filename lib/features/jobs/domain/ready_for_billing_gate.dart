import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';

/// The DJ may not close a deal ("Luk aftale og send faktura") until EVERY winning
/// musician on the job has ticked "Kunden er kontaktet".
///
/// This is a server rule, enforced by `PUT /api/jobs/[job_id]/ready-for-billing`
/// and `PUT /api/ext-jobs/[ext_job_id]/ready-for-billing` (both reject with
/// `code: "musician_not_contacted"`). The client copy here only decides whether the
/// button is tappable — it never grants the close, so a stale offer list can at worst
/// let the DJ tap into the server's rejection, never close a deal the server would block.
///
/// Mirrors web `dj/quotes/[id]/_components/LeadInfo.tsx` `isBlockedByMusicianContact`:
/// there must BE a won offer, and at least one won offer must be un-contacted. A job
/// with no musician at all is never blocked.
bool isBlockedByMusicianContact(List<ServiceOffer> offers) {
  final won = offers.where((o) => o.status == ServiceOfferStatus.won).toList();
  if (won.isEmpty) return false;
  return won.any((o) => !o.customerContacted);
}

/// What to tell the DJ while [isBlockedByMusicianContact] holds.
///
/// Names the instrument when every blocking offer shares one ("Saxofonisten skal
/// også…"), because that is how the DJ thinks about the job; falls back to the
/// neutral wording for a mixed or unknown line-up. Describes the JOB's state, never
/// the musician's standing.
String musicianContactBlockedMessage(List<ServiceOffer> offers) {
  final blocking =
      offers
          .where(
            (o) => o.status == ServiceOfferStatus.won && !o.customerContacted,
          )
          .toList();
  final instruments =
      blocking
          .map((o) => o.instrument.trim().toLowerCase())
          .where((i) => i.isNotEmpty)
          .toSet();
  final who =
      instruments.length == 1
          ? _performerLabel(instruments.first)
          : 'Musikeren';
  return '$who skal også kontakte kunden, før du kan lukke aftalen og sende faktura.';
}

String _performerLabel(String instrument) {
  if (instrument.contains('sax')) return 'Saxofonisten';
  if (instrument.contains('violin')) return 'Violinisten';
  if (instrument.contains('guitar')) return 'Guitaristen';
  if (instrument.contains('trompet') || instrument.contains('trumpet')) {
    return 'Trompetisten';
  }
  if (instrument.contains('percussion') || instrument.contains('tromme')) {
    return 'Perkussionisten';
  }
  if (instrument.contains('sang') || instrument.contains('vocal')) {
    return 'Sangeren';
  }
  return 'Musikeren';
}

/// Maps a failed ready-for-billing call to something the DJ can act on.
///
/// The web routes author their rejection reasons as user-facing Danish and tag them
/// with a stable `code`; [AppException.message] carries the message verbatim. Without
/// this, "en musiker mangler at kontakte kunden" surfaced as a bare
/// "Noget gik galt. Prøv igen." and the DJ had no way to know what was blocking them.
/// The English forms are kept as a fallback in case a route ever returns them.
String readyForBillingErrorMessage(AppException? err) {
  const fallback = 'Noget gik galt. Prøv igen.';
  if (err == null) return fallback;

  // Prefer the stable `code` over the Danish copy: the message is user-facing
  // text that will be reworded, the code will not. `DatabaseException.code` is
  // populated by JobsRemoteDatasource._errorFor from the route's JSON body.
  final code = err is DatabaseException ? err.code : null;
  if (code == 'musician_not_contacted') {
    return 'Din instrumentalist skal også kontakte kunden, inden du kan lukke aftalen. Koordinér med dem og prøv igen.';
  }
  if (code == 'customer_not_contacted') {
    return 'Du skal markere kunden som kontaktet, inden du kan lukke aftalen.';
  }

  final msg = err.message.toLowerCase();
  if (msg.contains('musikere') ||
      (msg.contains('musician') && msg.contains('contact'))) {
    return 'Din instrumentalist skal også kontakte kunden, inden du kan lukke aftalen. Koordinér med dem og prøv igen.';
  }
  if (msg.contains('markeres som kontaktet') ||
      msg.contains('customer_contacted') ||
      msg.contains('customer-contacted')) {
    return 'Du skal markere kunden som kontaktet, inden du kan lukke aftalen.';
  }
  return friendlyErrorMessage(err, fallback: fallback);
}
