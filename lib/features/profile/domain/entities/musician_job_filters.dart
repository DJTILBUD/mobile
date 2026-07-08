/// A saxophonist's job filter preferences. Mirrors the web app's
/// MusicianJobFilters (regions + sax type only — 'lounge' vs 'party').
/// Empty lists = "everything on" (nothing excluded).
class MusicianJobFilters {
  const MusicianJobFilters({
    required this.musicianId,
    this.excludedSaxTypes = const [],
    this.excludedRegions = const [],
  });

  final String musicianId;

  /// Sax types ('lounge' / 'party') excluded from the feed and notifications.
  final List<String> excludedSaxTypes;

  /// Region strings excluded from the feed and notifications.
  final List<String> excludedRegions;

  bool get hasActiveFilters =>
      excludedSaxTypes.isNotEmpty || excludedRegions.isNotEmpty;

  MusicianJobFilters copyWith({
    List<String>? excludedSaxTypes,
    List<String>? excludedRegions,
  }) {
    return MusicianJobFilters(
      musicianId: musicianId,
      excludedSaxTypes: excludedSaxTypes ?? this.excludedSaxTypes,
      excludedRegions: excludedRegions ?? this.excludedRegions,
    );
  }
}
