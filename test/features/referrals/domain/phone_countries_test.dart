import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/referrals/domain/phone_countries.dart';

/// Ports the same cases as web-app's `phoneCountries.test.ts`. Both are hand-kept mirrors of
/// dj-form/src/App.tsx's `PHONE_COUNTRIES` + `normalizePhoneLocal` — a drift here means a DJ or
/// musician's referral gets a different (possibly wrong) phone number than the customer would
/// have typed on the booking form itself.
void main() {
  group('normalizePhoneLocal (ported from dj-form)', () {
    test('keeps a plain local number untouched', () {
      expect(normalizePhoneLocal('12345678', '45'), '12345678');
    });

    test('strips non-digit characters as the user types', () {
      expect(normalizePhoneLocal('12 34 56 78', '45'), '12345678');
    });

    test('strips a typed international + prefix and the dial code', () {
      expect(normalizePhoneLocal('+4512345678', '45'), '12345678');
    });

    test('strips a typed 00 international prefix and the dial code', () {
      expect(normalizePhoneLocal('0045 12 34 56 78', '45'), '12345678');
    });

    test(
      'strips a pasted full number with no + when it is clearly dial code + local',
      () {
        expect(normalizePhoneLocal('4512345678', '45'), '12345678');
      },
    );

    test(
      'does NOT strip a short local number that merely starts with the dial code digits',
      () {
        expect(normalizePhoneLocal('451234', '45'), '451234');
      },
    );

    test('works for a longer dial code (Finland, 358)', () {
      expect(normalizePhoneLocal('+358 40 123 4567', '358'), '401234567');
    });
  });

  group('findPhoneCountry / formatE164Phone', () {
    test('defaults to the first country (Denmark) for an unknown code', () {
      expect(findPhoneCountry('XX'), phoneCountries.first);
      expect(findPhoneCountry('XX').code, 'DK');
    });

    test(
      'formats exactly like dj-form\'s submit payload: +<dial><local>, no separator',
      () {
        expect(formatE164Phone('DK', '12345678'), '+4512345678');
        expect(formatE164Phone('US', '5551234567'), '+15551234567');
      },
    );
  });
}
