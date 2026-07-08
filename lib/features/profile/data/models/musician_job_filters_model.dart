import 'package:dj_tilbud_app/features/profile/domain/entities/musician_job_filters.dart';

class MusicianJobFiltersModel {
  const MusicianJobFiltersModel({
    required this.musicianId,
    this.excludedSaxTypes = const [],
    this.excludedRegions = const [],
  });

  final String musicianId;
  final List<String> excludedSaxTypes;
  final List<String> excludedRegions;

  factory MusicianJobFiltersModel.fromJson(Map<String, dynamic> json) {
    List<String> strList(String key) =>
        (json[key] as List<dynamic>?)?.cast<String>() ?? [];

    return MusicianJobFiltersModel(
      musicianId: json['musician_id'] as String,
      excludedSaxTypes: strList('excluded_sax_types'),
      excludedRegions: strList('excluded_regions'),
    );
  }

  Map<String, dynamic> toJson() => {
    'musician_id': musicianId,
    'excluded_sax_types': excludedSaxTypes,
    'excluded_regions': excludedRegions,
  };

  MusicianJobFilters toEntity() => MusicianJobFilters(
    musicianId: musicianId,
    excludedSaxTypes: excludedSaxTypes,
    excludedRegions: excludedRegions,
  );

  static MusicianJobFiltersModel fromEntity(MusicianJobFilters e) =>
      MusicianJobFiltersModel(
        musicianId: e.musicianId,
        excludedSaxTypes: e.excludedSaxTypes,
        excludedRegions: e.excludedRegions,
      );
}
