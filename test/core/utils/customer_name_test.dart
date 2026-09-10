import 'package:dj_tilbud_app/core/utils/customer_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('customerFirstName', () {
    test('takes the first token of a full name', () {
      expect(customerFirstName('Anna Hansen'), 'Anna');
      expect(customerFirstName('Jens Peter Nørgaard'), 'Jens');
    });

    test('returns a bare first name unchanged', () {
      expect(customerFirstName('Anna'), 'Anna');
    });

    test('trims and collapses whitespace', () {
      expect(customerFirstName('  Anna   Hansen '), 'Anna');
      expect(customerFirstName('\nAnna\tHansen'), 'Anna');
    });

    // lead_name is text NOT NULL with no format constraint — the WordPress forms put junk in it.
    test('returns null for junk the forms actually produce', () {
      expect(customerFirstName(null), isNull);
      expect(customerFirstName(''), isNull);
      expect(customerFirstName('   '), isNull);
      expect(customerFirstName('-'), isNull);
      expect(customerFirstName('- '), isNull);
    });

    test('skips a leading punctuation token instead of rendering it', () {
      expect(customerFirstName('- Anna'), 'Anna');
    });

    test('keeps non-ASCII letters', () {
      expect(customerFirstName('Øystein Åberg'), 'Øystein');
    });
  });
}
