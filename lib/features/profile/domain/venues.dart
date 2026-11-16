/// "Erfaring og tidligere spillesteder" (`venues_and_events` on DjInfos and Musicians): the rules
/// for adding names from the text field. 1:1 MIRROR of web-app `src/helpers/venues.ts`; change
/// both together.
library;

const int maxVenueLength = 70;

final RegExp _separators = RegExp(r'[,;\n]');

/// Splits typed or pasted text into names: comma, semicolon or line break separate them, so
/// "Vega, Tivoli" is two venues. Trims, drops empties, cuts each to [maxVenueLength].
List<String> parseVenueInput(String text) {
  return text
      .split(_separators)
      .map((part) {
        final clean = part.replaceAll(RegExp(r'\s+'), ' ').trim();
        return (clean.length > maxVenueLength
                ? clean.substring(0, maxVenueLength)
                : clean)
            .trim();
      })
      .where((part) => part.isNotEmpty)
      .toList();
}

/// Adds the names from [text] to [venues], skipping ones already there (ignoring case).
List<String> addVenues(List<String> venues, String text) {
  final seen = venues.map((v) => v.toLowerCase()).toSet();
  final out = List<String>.of(venues);
  for (final name in parseVenueInput(text)) {
    if (seen.add(name.toLowerCase())) out.add(name);
  }
  return out;
}

/// Index of the last separator in [text], or -1.
int lastVenueSeparator(String text) => text.lastIndexOf(_separators);
