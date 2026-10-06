/// Country-code + local-number phone entry, mirroring the customer DJ booking form's own field
/// (dj-form/src/App.tsx: `PHONE_COUNTRIES` + `normalizePhoneLocal`), so a DJ/musician entering a
/// customer's phone number on a referral always ends up with the same country code and digits the
/// customer would have entered themselves. dj-form is a separate app/repo with no shared package
/// between them (also mirrored on web in web-app/src/helpers/phoneCountries.ts) — change all three
/// together.
class PhoneCountry {
  const PhoneCountry({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String code;
  final String name;
  final String dialCode;
  final String flag;
}

const List<PhoneCountry> phoneCountries = [
  PhoneCountry(code: 'DK', name: 'Danmark', dialCode: '45', flag: '🇩🇰'),
  PhoneCountry(code: 'NO', name: 'Norge', dialCode: '47', flag: '🇳🇴'),
  PhoneCountry(code: 'SE', name: 'Sverige', dialCode: '46', flag: '🇸🇪'),
  PhoneCountry(code: 'FI', name: 'Finland', dialCode: '358', flag: '🇫🇮'),
  PhoneCountry(code: 'DE', name: 'Deutschland', dialCode: '49', flag: '🇩🇪'),
  PhoneCountry(
    code: 'GB',
    name: 'United Kingdom',
    dialCode: '44',
    flag: '🇬🇧',
  ),
  PhoneCountry(code: 'NL', name: 'Netherlands', dialCode: '31', flag: '🇳🇱'),
  PhoneCountry(code: 'US', name: 'United States', dialCode: '1', flag: '🇺🇸'),
  PhoneCountry(code: 'ES', name: 'Spain', dialCode: '34', flag: '🇪🇸'),
  PhoneCountry(code: 'IT', name: 'Italy', dialCode: '39', flag: '🇮🇹'),
  PhoneCountry(code: 'FR', name: 'France', dialCode: '33', flag: '🇫🇷'),
];

const String defaultPhoneCountryCode = 'DK';

PhoneCountry findPhoneCountry(String code) {
  return phoneCountries.firstWhere(
    (c) => c.code == code,
    orElse: () => phoneCountries.first,
  );
}

/// Strips everything but digits, then strips a leading "00" and, when it looks like the dial
/// code was actually typed (an international "+"/"00" prefix, or the digits are long enough that
/// they can't just be a local number that happens to start with the same digits), strips the
/// dial code too. Exact port of dj-form's `normalizePhoneLocal` — pasting a full international
/// number into the local field still lands on the right digits, and a short local number that
/// happens to start with the dial code's digits (e.g. Denmark's "45") is left alone.
String normalizePhoneLocal(String raw, String dialCode) {
  final hasInternationalPrefix = RegExp(r'^\s*(\+|00)').hasMatch(raw);
  var digits = raw.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }

  if (hasInternationalPrefix && digits.startsWith(dialCode)) {
    digits = digits.substring(dialCode.length);
  }

  if (!hasInternationalPrefix &&
      digits.startsWith(dialCode) &&
      digits.length > dialCode.length + 4) {
    digits = digits.substring(dialCode.length);
  }

  return digits;
}

/// The exact string dj-form sends to the API: "+" + dial code + local digits, no separator.
String formatE164Phone(String countryCode, String local) {
  return '+${findPhoneCountry(countryCode).dialCode}$local';
}
