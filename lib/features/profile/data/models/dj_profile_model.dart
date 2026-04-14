import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';

class DjProfileModel {
  const DjProfileModel({
    required this.id,
    required this.fullName,
    required this.companyOrDjName,
    required this.phone,
    required this.aboutYou,
    required this.pricePerExtraHour,
    required this.regions,
    required this.genres,
    required this.canPlayWithSax,
    required this.allowPublicDjProfile,
    this.isSuppressed = false,
    this.tier,
    this.soundcloudUrl,
    this.venuesAndEvents,
    this.excludedEventTypes = const [],
  });

  final String id;
  final String fullName;
  final String companyOrDjName;
  final String phone;
  final String aboutYou;
  final int pricePerExtraHour;
  final List<String> regions;
  final List<String> genres;
  final bool canPlayWithSax;
  final bool allowPublicDjProfile;
  final bool isSuppressed;
  final String? tier;
  final String? soundcloudUrl;
  final List<String>? venuesAndEvents;
  final List<String> excludedEventTypes;

  factory DjProfileModel.fromJson(Map<String, dynamic> json) {
    return DjProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      companyOrDjName: json['company_or_dj_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      aboutYou: json['about_you'] as String? ?? '',
      pricePerExtraHour: (json['price_per_extra_hour'] as num?)?.toInt() ?? 0,
      regions: (json['regions'] as List<dynamic>?)?.cast<String>() ?? [],
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      canPlayWithSax: json['can_play_with_sax'] as bool? ?? false,
      allowPublicDjProfile: json['allow_public_dj_profile'] as bool? ?? true,
      isSuppressed: json['is_suppressed'] as bool? ?? false,
      tier: json['tier'] as String?,
      soundcloudUrl: json['soundcloud_url'] as String?,
      venuesAndEvents: (json['venues_and_events'] as List<dynamic>?)?.cast<String>(),
      excludedEventTypes: (json['excluded_event_types'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'company_or_dj_name': companyOrDjName,
      'phone': phone,
      'about_you': aboutYou,
      'price_per_extra_hour': pricePerExtraHour,
      'regions': regions,
      'genres': genres,
      'can_play_with_sax': canPlayWithSax,
      'allow_public_dj_profile': allowPublicDjProfile,
      'soundcloud_url': soundcloudUrl,
      'venues_and_events': venuesAndEvents,
    };
  }

  DjProfile toEntity() {
    return DjProfile(
      id: id,
      fullName: fullName,
      companyOrDjName: companyOrDjName,
      phone: phone,
      aboutYou: aboutYou,
      pricePerExtraHour: pricePerExtraHour,
      regions: regions,
      genres: genres,
      canPlayWithSax: canPlayWithSax,
      allowPublicDjProfile: allowPublicDjProfile,
      isSuppressed: isSuppressed,
      tier: tier,
      soundcloudUrl: soundcloudUrl,
      venuesAndEvents: venuesAndEvents,
      excludedEventTypes: excludedEventTypes,
    );
  }
}
