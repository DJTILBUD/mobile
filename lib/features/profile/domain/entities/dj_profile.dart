class DjProfile {
  const DjProfile({
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
}
