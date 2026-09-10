import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/jobs/domain/offer_form_validation.dart';

const _validPitch =
    'Jeg har spillet til mere end hundrede bryllupper og sørger altid for at '
    'dansegulvet er fyldt hele aftenen igennem, uanset hvilken aldersgruppe.';

void main() {
  group('validateDjQuoteInput', () {
    test('rejects a missing price — the 0 kr. bid bug', () {
      // Regression: the price field is unmounted by the lazy ListView when the
      // DJ has scrolled to the submit button, so Form.validate() skipped it.
      expect(
        validateDjQuoteInput(
          price: 0,
          salesPitch: _validPitch,
          equipmentSelected: true,
        ),
        'Indtast en gyldig pris',
      );
    });

    test('rejects a negative price', () {
      expect(
        validateDjQuoteInput(
          price: -1,
          salesPitch: _validPitch,
          equipmentSelected: true,
        ),
        isNotNull,
      );
    });

    test('rejects missing equipment', () {
      expect(
        validateDjQuoteInput(
          price: 5000,
          salesPitch: _validPitch,
          equipmentSelected: false,
        ),
        'Vælg mindst ét stykke udstyr',
      );
    });

    test('rejects a too-short pitch, measured after trimming', () {
      expect(
        validateDjQuoteInput(
          price: 5000,
          salesPitch: '   ${'a' * (kSalesPitchMinLength - 1)}   ',
          equipmentSelected: true,
        ),
        contains('$kSalesPitchMinLength tegn'),
      );
    });

    test('accepts a complete quote', () {
      expect(
        validateDjQuoteInput(
          price: 5000,
          salesPitch: _validPitch,
          equipmentSelected: true,
        ),
        isNull,
      );
    });

    test('price is reported before the other problems', () {
      // The price is the one that silently reached the customer, so it wins.
      expect(
        validateDjQuoteInput(price: 0, salesPitch: '', equipmentSelected: false),
        'Indtast en gyldig pris',
      );
    });
  });

  group('validateMusicianOfferInput', () {
    test('rejects a too-short pitch', () {
      expect(validateMusicianOfferInput(salesPitch: 'kort'), isNotNull);
    });

    test('accepts a full pitch', () {
      expect(validateMusicianOfferInput(salesPitch: _validPitch), isNull);
    });
  });
}
