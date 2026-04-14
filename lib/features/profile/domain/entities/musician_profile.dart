class MusicianProfile {
  const MusicianProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.instrument,
    required this.hourlyRate,
    required this.minimumBookingRate,
    required this.regions,
    this.aboutText,
    this.experienceYears,
    this.genres,
    this.djSaxCollaboration,
    this.venuesAndEvents,
  });

  final String id;
  final String fullName;
  final String phone;
  final String instrument;
  final int hourlyRate;
  final int minimumBookingRate;
  final List<String> regions;
  final String? aboutText;
  final int? experienceYears;
  final List<String>? genres;
  final String? djSaxCollaboration;
  final List<String>? venuesAndEvents;
}
