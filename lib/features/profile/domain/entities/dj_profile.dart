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
    this.equipmentStatus,
    this.soundcloudUrl,
    this.venuesAndEvents,
    this.excludedEventTypes = const [],
    this.onboardingCompletedAt,
    this.songRequestToken,
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

  /// `DjInfos.equipment_status`: 'equipped' or 'non_equipped' (WKNDS delivers
  /// the gear). Set by admin only, so it is read here and never written back.
  final String? equipmentStatus;
  final String? soundcloudUrl;
  final List<String>? venuesAndEvents;
  final List<String> excludedEventTypes;
  final DateTime? onboardingCompletedAt;

  /// Stable per-DJ token encoded in the song-request QR. The web resolver maps
  /// it to the DJ's soonest upcoming event at scan time.
  final String? songRequestToken;
}
