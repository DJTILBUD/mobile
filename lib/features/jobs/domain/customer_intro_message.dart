/// Canonical "intro message to the customer" a DJ/saxophonist can copy after winning a job, to make it
/// effortless to reach out within 24h (a recurring problem is performers not contacting the customer
/// fast enough). MUST stay byte-identical to the web-app helper
/// `web-app/src/helpers/customerIntroMessage.ts` — change both together.
library;

/// [role] is the Danish role label ("DJ" or "saxofonist"). [performerName] is the performer's own
/// name (DJ: company/DJ name; sax: full name). [leadName] is the customer's name.
String buildCustomerIntroMessage({
  required String leadName,
  required String role,
  required String performerName,
}) {
  return 'Hej $leadName!\n'
      '\n'
      'Du er gået videre med mig som $role til arrangementet.\n'
      '\n'
      'Har du tid til et kald her en af dagene?😊\n'
      'Dermed kan vi snakke om alt det praktiske.\n'
      '\n'
      'Jeg glæder mig til at høre fra dig!🙌🏻\n'
      '\n'
      'Venlig hilsen\n'
      '$performerName // DJTilbud';
}
