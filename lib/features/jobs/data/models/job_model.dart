import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';

class JobModel {
  const JobModel({
    required this.id,
    required this.eventType,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    required this.city,
    required this.region,
    required this.guestsAmount,
    required this.status,
    required this.createdAt,
    this.budgetStart,
    this.budgetEnd,
    this.genres,
    this.leadRequest,
    this.additionalInformation,
    this.requestedSaxophonist,
    this.requestedMusicianHours,
    this.birthdayPersonAge,
    this.leadName,
    this.leadEmail,
    this.leadPhoneNumber,
    this.customerNote,
    this.isExtJob = false,
    this.extJobId,
    this.quoteSendMode,
    this.isPaused = false,
    this.assignedDjName,
    this.sentAt,
    this.deadlineExtendedUntil,
    this.customerContactPlannedFor,
    this.musicianStartTime,
    this.roleType,
    this.hasActiveOffer = false,
    this.saxType,
    this.musicianSpecialRequest,
    this.songRequestToken,
    this.postalCode,
    this.guestAge,
    this.addressAs,
    this.firstDanceSong,
    this.spotifyPlaylistUrl,
    this.specialConditions,
    this.earlySetup = false,
  });

  final int id;
  final String eventType;
  final String date;
  final String timeStart;
  final String timeEnd;
  final String city;
  final String region;
  final int guestsAmount;
  final String status;
  final String createdAt;
  final double? budgetStart;
  final double? budgetEnd;
  final List<String>? genres;
  final String? leadRequest;
  final String? additionalInformation;
  final bool? requestedSaxophonist;
  final double? requestedMusicianHours;
  final String? birthdayPersonAge;
  final String? leadName;
  final String? leadEmail;
  final String? leadPhoneNumber;
  final String? customerNote;
  final bool isExtJob;
  final int? extJobId;
  final String? quoteSendMode;
  final bool isPaused;
  final String? assignedDjName;
  final String? sentAt;
  final String? deadlineExtendedUntil;
  final String? customerContactPlannedFor;
  final String? musicianStartTime;
  final String? roleType;
  final bool hasActiveOffer;
  final String? saxType;
  final String? musicianSpecialRequest;
  final String? songRequestToken;
  final String? postalCode;
  final String? guestAge;
  final String? addressAs;
  final String? firstDanceSong;
  final String? spotifyPlaylistUrl;
  final String? specialConditions;
  final bool earlySetup;

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: (json['id'] as num).toInt(),
      eventType: json['event_type'] as String,
      date: json['date'] as String,
      timeStart: json['time_start'] as String,
      timeEnd: json['time_end'] as String,
      city: json['city'] as String,
      region: json['region'] as String,
      guestsAmount: (json['guests_amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      budgetStart: (json['budget_start'] as num?)?.toDouble(),
      budgetEnd: (json['budget_end'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>?)?.cast<String>(),
      leadRequest: json['lead_request'] as String?,
      additionalInformation: json['additional_information'] as String?,
      requestedSaxophonist: json['requested_saxophonist'] as bool?,
      requestedMusicianHours:
          (json['requested_musician_hours'] as num?)?.toDouble(),
      birthdayPersonAge: json['birthday_person_age'] as String?,
      leadName: json['lead_name'] as String?,
      leadEmail: json['lead_email'] as String?,
      leadPhoneNumber: json['lead_phone_number'] as String?,
      customerNote: json['customer_note'] as String?,
      quoteSendMode: json['quote_send_mode'] as String?,
      isPaused: json['is_paused'] as bool? ?? false,
      sentAt: json['sent_at'] as String?,
      deadlineExtendedUntil: json['deadline_extended_until'] as String?,
      customerContactPlannedFor:
          json['customer_contact_planned_for'] as String?,
      musicianStartTime: _formatTime(json['musician_start_time']),
      roleType: json['role_type'] as String?,
      hasActiveOffer: json['has_active_offer'] as bool? ?? false,
      saxType: json['sax_type'] as String?,
      musicianSpecialRequest: json['musician_special_request'] as String?,
      songRequestToken: json['song_request_token'] as String?,
      postalCode: json['postal_code'] as String?,
      guestAge: json['guest_age'] as String?,
      addressAs: json['address_as'] as String?,
      firstDanceSong: json['first_dance_song'] as String?,
      spotifyPlaylistUrl: json['spotify_playlist_url'] as String?,
      specialConditions: json['special_conditions'] as String?,
      earlySetup: json['early_setup'] as bool? ?? false,
    );
  }

  static String? _formatTime(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  Job toEntity() {
    return Job(
      id: id,
      eventType: eventType,
      // tryParse + sentinel: a malformed date must never throw and blank the whole jobs list —
      // a single bad row survives as an obviously-wrong 1970 date instead (same "one bad row can't
      // kill the feed" principle as the sax_type fix).
      date: DateTime.tryParse(date) ?? DateTime.fromMillisecondsSinceEpoch(0),
      timeStart: timeStart,
      timeEnd: timeEnd,
      city: city,
      region: region,
      guestsAmount: guestsAmount,
      status: JobStatus.fromString(status),
      createdAt:
          DateTime.tryParse(createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      budgetStart: budgetStart,
      budgetEnd: budgetEnd,
      genres: genres,
      leadRequest: leadRequest,
      additionalInformation: additionalInformation,
      requestedSaxophonist: requestedSaxophonist ?? false,
      requestedMusicianHours: requestedMusicianHours,
      birthdayPersonAge: birthdayPersonAge,
      leadName: leadName,
      leadEmail: leadEmail,
      leadPhoneNumber: leadPhoneNumber,
      customerNote: customerNote,
      isExtJob: isExtJob,
      extJobId: extJobId,
      quoteSendMode: quoteSendMode,
      isPaused: isPaused,
      assignedDjName: assignedDjName,
      sentAt: sentAt != null ? DateTime.parse(sentAt!) : null,
      deadlineExtendedUntil:
          deadlineExtendedUntil != null
              ? DateTime.parse(deadlineExtendedUntil!)
              : null,
      customerContactPlannedFor:
          customerContactPlannedFor != null
              ? DateTime.parse(customerContactPlannedFor!)
              : null,
      musicianStartTime: musicianStartTime,
      roleType: roleType,
      hasActiveOffer: hasActiveOffer,
      saxType: saxType,
      musicianSpecialRequest: musicianSpecialRequest,
      songRequestToken: songRequestToken,
      postalCode: postalCode,
      guestAge: guestAge,
      addressAs: addressAs,
      firstDanceSong: firstDanceSong,
      spotifyPlaylistUrl: spotifyPlaylistUrl,
      specialConditions: specialConditions,
      earlySetup: earlySetup,
    );
  }
}
