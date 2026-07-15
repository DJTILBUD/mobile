/// Normalises a free-text phone number into something the OS can actually dial.
///
/// `Jobs.lead_phone_number` is `text NOT NULL` with no format constraint, and it is
/// filled from the WordPress customer forms, so it holds whatever the customer typed:
/// "+45 42 36 06 66", "42360666", but also placeholders like "ikke oplyst" or "-".
///
/// Naively stripping non-digits turns those placeholders into an EMPTY string, which
/// yields `sms:?body=...` — a composer with no recipient, which iOS renders as a
/// recipient chip that spins forever. Returning null instead lets callers hide the
/// action rather than open a broken composer.
///
/// Returns digits with an optional single leading `+` (Apple's SMS Links grammar),
/// or null when [raw] cannot be a real number.
String? dialablePhoneNumber(String? raw) {
  if (raw == null) return null;

  // A '+' anywhere before the first digit is an international prefix — customers write
  // "(+45) 42360666" as well as "+45 42360666". A '+' after digits is noise and dropped.
  final firstDigit = raw.indexOf(RegExp(r'\d'));
  final hasPlusPrefix =
      firstDigit != -1 && raw.substring(0, firstDigit).contains('+');
  final digits = raw.replaceAll(RegExp(r'\D'), '');

  // Danish numbers are 8 digits; with a country code they are longer. Anything
  // shorter is a placeholder, an extension, or junk — not something to dial.
  if (digits.length < 8) return null;

  return hasPlusPrefix ? '+$digits' : digits;
}
