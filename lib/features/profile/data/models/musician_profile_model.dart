import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';

class MusicianProfileModel {
  const MusicianProfileModel({
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

  factory MusicianProfileModel.fromJson(Map<String, dynamic> json) {
    return MusicianProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      instrument: json['instrument'] as String? ?? '',
      hourlyRate: (json['hourly_rate'] as num?)?.toInt() ?? 0,
      minimumBookingRate: (json['minimum_booking_rate'] as num?)?.toInt() ?? 0,
      regions: (json['regions'] as List<dynamic>?)?.cast<String>() ?? [],
      aboutText: json['about_text'] as String?,
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      genres: (json['genres'] as List<dynamic>?)?.cast<String>(),
      djSaxCollaboration: json['dj_sax_collaboration'] as String?,
      venuesAndEvents: (json['venues_and_events'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'instrument': instrument,
      'hourly_rate': hourlyRate,
      'minimum_booking_rate': minimumBookingRate,
      'regions': regions,
      'about_text': aboutText,
      'experience_years': experienceYears,
      'genres': genres,
      'dj_sax_collaboration': djSaxCollaboration,
      'venues_and_events': venuesAndEvents,
    };
  }

  MusicianProfile toEntity() {
    return MusicianProfile(
      id: id,
      fullName: fullName,
      phone: phone,
      instrument: instrument,
      hourlyRate: hourlyRate,
      minimumBookingRate: minimumBookingRate,
      regions: regions,
      aboutText: aboutText,
      experienceYears: experienceYears,
      genres: genres,
      djSaxCollaboration: djSaxCollaboration,
      venuesAndEvents: venuesAndEvents,
    );
  }
}
