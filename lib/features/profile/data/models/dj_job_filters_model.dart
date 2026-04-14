import 'package:dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart';

class DjJobFiltersModel {
  const DjJobFiltersModel({
    required this.djId,
    this.excludedEventTypes = const [],
    this.excludedRegions = const [],
    this.excludedGenres = const [],
    this.allowedWeekdays,
    this.minBudget,
    this.maxBudget,
    this.minGuests,
    this.maxGuests,
  });

  final String djId;
  final List<String> excludedEventTypes;
  final List<String> excludedRegions;
  final List<String> excludedGenres;
  final List<int>? allowedWeekdays;
  final int? minBudget;
  final int? maxBudget;
  final int? minGuests;
  final int? maxGuests;

  factory DjJobFiltersModel.fromJson(Map<String, dynamic> json) {
    List<String> _strList(String key) =>
        (json[key] as List<dynamic>?)?.cast<String>() ?? [];
    List<int> _intList(String key) =>
        (json[key] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [];

    final weekdays = json['allowed_weekdays'] as List<dynamic>?;

    return DjJobFiltersModel(
      djId: json['dj_id'] as String,
      excludedEventTypes: _strList('excluded_event_types'),
      excludedRegions: _strList('excluded_regions'),
      excludedGenres: _strList('excluded_genres'),
      allowedWeekdays: weekdays == null ? null : _intList('allowed_weekdays'),
      minBudget: (json['min_budget'] as num?)?.toInt(),
      maxBudget: (json['max_budget'] as num?)?.toInt(),
      minGuests: (json['min_guests'] as num?)?.toInt(),
      maxGuests: (json['max_guests'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dj_id': djId,
        'excluded_event_types': excludedEventTypes,
        'excluded_regions': excludedRegions,
        'excluded_genres': excludedGenres,
        'allowed_weekdays': allowedWeekdays,
        'min_budget': minBudget,
        'max_budget': maxBudget,
        'min_guests': minGuests,
        'max_guests': maxGuests,
      };

  DjJobFilters toEntity() => DjJobFilters(
        djId: djId,
        excludedEventTypes: excludedEventTypes,
        excludedRegions: excludedRegions,
        excludedGenres: excludedGenres,
        allowedWeekdays: allowedWeekdays,
        minBudget: minBudget,
        maxBudget: maxBudget,
        minGuests: minGuests,
        maxGuests: maxGuests,
      );

  static DjJobFiltersModel fromEntity(DjJobFilters e) => DjJobFiltersModel(
        djId: e.djId,
        excludedEventTypes: e.excludedEventTypes,
        excludedRegions: e.excludedRegions,
        excludedGenres: e.excludedGenres,
        allowedWeekdays: e.allowedWeekdays,
        minBudget: e.minBudget,
        maxBudget: e.maxBudget,
        minGuests: e.minGuests,
        maxGuests: e.maxGuests,
      );
}
