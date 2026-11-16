import 'package:flutter_test/flutter_test.dart';

import 'package:dj_tilbud_app/features/profile/domain/venues.dart';

// Same cases as web-app src/helpers/venues.test.ts.
void main() {
  group('parseVenueInput', () {
    test('splits on comma, semicolon and line breaks and trims', () {
      expect(parseVenueInput(" Vega,Tivoli ; Hotel d'Angleterre\nDistortion "), [
        'Vega',
        'Tivoli',
        "Hotel d'Angleterre",
        'Distortion',
      ]);
    });

    test('drops empty parts and collapses spaces', () {
      expect(parseVenueInput(' , ,  Royal   Arena ,'), ['Royal Arena']);
      expect(parseVenueInput('   '), isEmpty);
    });

    test('cuts a name to the max length', () {
      expect(
        parseVenueInput('a' * (maxVenueLength + 10)).first,
        hasLength(maxVenueLength),
      );
    });
  });

  group('addVenues', () {
    test('appends new names in order', () {
      expect(addVenues(['Vega'], 'Tivoli, Distortion'), [
        'Vega',
        'Tivoli',
        'Distortion',
      ]);
    });

    test('skips duplicates ignoring case, also within the same input', () {
      expect(addVenues(['Vega'], 'vega, VEGA, Tivoli, tivoli'), [
        'Vega',
        'Tivoli',
      ]);
      expect(addVenues(['Ærø Festival'], 'ærø festival'), ['Ærø Festival']);
    });

    test('returns the same names for empty input', () {
      expect(addVenues(['Vega'], '  '), ['Vega']);
    });
  });
}
