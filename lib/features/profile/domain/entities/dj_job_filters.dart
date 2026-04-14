class DjJobFilters {
  const DjJobFilters({
    required this.djId,
    this.excludedEventTypes = const [],
    this.excludedRegions = const [],
    this.excludedGenres = const [],
    this.allowedWeekdays, // null = all weekdays allowed
    this.minBudget,
    this.maxBudget,
    this.minGuests,
    this.maxGuests,
  });

  final String djId;

  /// Event type keys (English, e.g. 'wedding') that are excluded from the feed.
  final List<String> excludedEventTypes;

  /// Region strings excluded from the feed.
  final List<String> excludedRegions;

  /// Genre strings excluded from the feed.
  final List<String> excludedGenres;

  /// Weekdays the DJ accepts (0=Sunday…6=Saturday, matching JS/Supabase convention).
  /// null means all weekdays are accepted.
  final List<int>? allowedWeekdays;

  final int? minBudget;
  final int? maxBudget;
  final int? minGuests;
  final int? maxGuests;

  bool get hasActiveFilters =>
      excludedEventTypes.isNotEmpty ||
      excludedRegions.isNotEmpty ||
      excludedGenres.isNotEmpty ||
      allowedWeekdays != null ||
      minBudget != null ||
      maxBudget != null ||
      minGuests != null ||
      maxGuests != null;

  DjJobFilters copyWith({
    List<String>? excludedEventTypes,
    List<String>? excludedRegions,
    List<String>? excludedGenres,
    List<int>? Function()? allowedWeekdays,
    int? Function()? minBudget,
    int? Function()? maxBudget,
    int? Function()? minGuests,
    int? Function()? maxGuests,
  }) {
    return DjJobFilters(
      djId: djId,
      excludedEventTypes: excludedEventTypes ?? this.excludedEventTypes,
      excludedRegions: excludedRegions ?? this.excludedRegions,
      excludedGenres: excludedGenres ?? this.excludedGenres,
      allowedWeekdays: allowedWeekdays != null ? allowedWeekdays() : this.allowedWeekdays,
      minBudget: minBudget != null ? minBudget() : this.minBudget,
      maxBudget: maxBudget != null ? maxBudget() : this.maxBudget,
      minGuests: minGuests != null ? minGuests() : this.minGuests,
      maxGuests: maxGuests != null ? maxGuests() : this.maxGuests,
    );
  }
}
