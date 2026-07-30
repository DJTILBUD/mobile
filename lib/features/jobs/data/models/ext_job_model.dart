import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/job_model.dart';

class ExtJobModel {
  const ExtJobModel({
    required this.id,
    required this.leadName,
    required this.date,
    required this.status,
    required this.createdAt,
    this.phoneNumber,
    this.email,
    this.startTime,
    this.endTime,
    this.location,
    this.guestsAmount,
    this.eventType,
    this.budgetTarget,
    this.fullAmount,
    this.honorar,
    this.assignedDjId,
    this.assignedDjName,
    this.assignedMusicianId,
    this.assignedMusicianName,
    this.roleType,
    this.requestedMusicianHours,
    this.musicianStartTime,
    this.guestAge,
    this.addressAs,
    this.firstDanceSong,
    this.spotifyPlaylistUrl,
    this.specialConditions,
    this.earlySetup = false,
    this.wantsIc,
    this.region,
    this.notes,
    this.birthdayPersonAge,
    this.company,
    this.djReadyConfirmedAt,
    this.customerContactPlannedFor,
    this.hasActiveOffer = false,
    this.saxType,
    this.musicianSpecialRequest,
    this.songRequestToken,
    this.postalCode,
    this.extraHours,
    this.extraHoursPricePerHour,
    this.sentAt,
    this.deadlineExtendedUntil,
  });

  final int id;
  final String leadName;
  final String date;
  final String status;
  final String createdAt;
  final String? phoneNumber;
  final String? email;
  final String? startTime;
  final String? endTime;
  final String? location;
  final int? guestsAmount;
  final String? eventType;
  final String? budgetTarget;
  final double? fullAmount;
  final double? honorar;
  final String? assignedDjId;
  final String? assignedDjName;
  final String? assignedMusicianId;
  final String? assignedMusicianName;
  final String? roleType;
  final double? requestedMusicianHours;
  final String? musicianStartTime;
  final String? guestAge;
  final String? addressAs;
  final String? firstDanceSong;
  final String? spotifyPlaylistUrl;
  final String? specialConditions;
  final bool earlySetup;
  final bool? wantsIc;
  final String? region;
  final String? notes;
  final String? birthdayPersonAge;
  final String? company;
  final DateTime? djReadyConfirmedAt;
  final String? customerContactPlannedFor;
  final bool hasActiveOffer;
  final String? saxType;
  final String? musicianSpecialRequest;
  final String? songRequestToken;
  final String? postalCode;
  final double? extraHours;
  final num? extraHoursPricePerHour;
  final String? sentAt;
  final String? deadlineExtendedUntil;

  factory ExtJobModel.fromJson(Map<String, dynamic> json) {
    // PostgreSQL time fields come as "HH:MM:SS", display as "HH:MM"
    String? formatTime(dynamic raw) {
      if (raw == null) return null;
      final s = raw.toString();
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    return ExtJobModel(
      id: (json['id'] as num).toInt(),
      leadName: json['lead_name'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      startTime: formatTime(json['start_time']),
      endTime: formatTime(json['end_time']),
      musicianStartTime: formatTime(json['musician_start_time']),
      location: json['location'] as String?,
      guestsAmount: (json['guests_amount'] as num?)?.toInt(),
      eventType: json['event_type'] as String?,
      budgetTarget: json['budget_target'] as String?,
      fullAmount: (json['full_amount'] as num?)?.toDouble(),
      honorar: (json['honorar'] as num?)?.toDouble(),
      assignedDjId: json['assigned_dj_id'] as String?,
      assignedDjName: json['assigned_dj_name'] as String?,
      assignedMusicianId: json['assigned_musician_id'] as String?,
      assignedMusicianName: json['assigned_musician_name'] as String?,
      roleType: json['role_type'] as String?,
      requestedMusicianHours:
          (json['requested_musician_hours'] as num?)?.toDouble(),
      guestAge: json['guest_age'] as String?,
      addressAs: json['address_as'] as String?,
      firstDanceSong: json['first_dance_song'] as String?,
      spotifyPlaylistUrl: json['spotify_playlist_url'] as String?,
      specialConditions: json['special_conditions'] as String?,
      earlySetup: json['early_setup'] as bool? ?? false,
      wantsIc: json['wants_ic'] as bool?,
      region: json['region'] as String?,
      notes: json['notes'] as String?,
      birthdayPersonAge: json['birthday_person_age'] as String?,
      company: json['company'] as String?,
      djReadyConfirmedAt:
          json['dj_ready_confirmed_at'] != null
              ? DateTime.parse(json['dj_ready_confirmed_at'] as String)
              : null,
      customerContactPlannedFor:
          json['customer_contact_planned_for'] as String?,
      hasActiveOffer: json['has_active_offer'] as bool? ?? false,
      saxType: json['sax_type'] as String?,
      musicianSpecialRequest: json['musician_special_request'] as String?,
      songRequestToken: json['song_request_token'] as String?,
      postalCode: json['postal_code'] as String?,
      extraHours: (json['extra_hours'] as num?)?.toDouble(),
      extraHoursPricePerHour:
          (json['extra_hours_price_per_hour'] as num?)?.toDouble(),
      sentAt: json['sent_at'] as String?,
      deadlineExtendedUntil: json['deadline_extended_until'] as String?,
    );
  }

  ExtJob toEntity() {
    return ExtJob(
      id: id,
      leadName: leadName,
      // tryParse + sentinel so one malformed date can't blank the whole feed (see JobModel).
      date: DateTime.tryParse(date) ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: ExtJobStatus.fromString(status),
      createdAt:
          DateTime.tryParse(createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      phoneNumber: phoneNumber,
      email: email,
      startTime: startTime,
      endTime: endTime,
      location: location,
      postalCode: postalCode,
      guestsAmount: guestsAmount,
      eventType: eventType,
      budgetTarget: budgetTarget,
      fullAmount: fullAmount,
      honorar: honorar,
      assignedDjId: assignedDjId,
      assignedDjName: assignedDjName,
      assignedMusicianId: assignedMusicianId,
      assignedMusicianName: assignedMusicianName,
      roleType: roleType,
      requestedMusicianHours: requestedMusicianHours,
      musicianStartTime: musicianStartTime,
      saxType: saxType,
      guestAge: guestAge,
      addressAs: addressAs,
      firstDanceSong: firstDanceSong,
      spotifyPlaylistUrl: spotifyPlaylistUrl,
      specialConditions: specialConditions,
      earlySetup: earlySetup,
      wantsIc: wantsIc,
      region: region,
      notes: notes,
      birthdayPersonAge: birthdayPersonAge,
      company: company,
      djReadyConfirmedAt: djReadyConfirmedAt,
      customerContactPlannedFor:
          customerContactPlannedFor != null
              ? DateTime.parse(customerContactPlannedFor!)
              : null,
      songRequestToken: songRequestToken,
      musicianSpecialRequest: musicianSpecialRequest,
      extraHours: extraHours,
      extraHoursPricePerHour: extraHoursPricePerHour,
      sentAt: sentAt != null ? DateTime.parse(sentAt!) : null,
      deadlineExtendedUntil:
          deadlineExtendedUntil != null
              ? DateTime.parse(deadlineExtendedUntil!)
              : null,
    );
  }

  /// Maps this ext job to a Job entity so it can be shown in the
  /// instrumentalist jobs feed without any visible difference.
  Job toJobEntity() {
    return toJobModel().toEntity();
  }

  /// Maps this ext job to a JobModel for use inside ServiceOfferModel.
  JobModel toJobModel() {
    return JobModel(
      id: id,
      extJobId: id,
      isExtJob: true,
      eventType: eventType ?? 'Arrangement',
      date: date,
      timeStart: startTime ?? '00:00',
      timeEnd: endTime ?? '00:00',
      city: location ?? '',
      region: region ?? '',
      postalCode: postalCode,
      guestsAmount: guestsAmount ?? 0,
      status: status,
      createdAt: createdAt,
      requestedMusicianHours: requestedMusicianHours,
      birthdayPersonAge: birthdayPersonAge,
      leadName: leadName,
      leadEmail: email,
      leadPhoneNumber: phoneNumber,
      requestedSaxophonist: true,
      leadRequest: notes,
      assignedDjName: assignedDjName,
      musicianStartTime: musicianStartTime,
      roleType: roleType,
      hasActiveOffer: hasActiveOffer,
      saxType: saxType,
      musicianSpecialRequest: musicianSpecialRequest,
      guestAge: guestAge,
      addressAs: addressAs,
      firstDanceSong: firstDanceSong,
      spotifyPlaylistUrl: spotifyPlaylistUrl,
      specialConditions: specialConditions,
      earlySetup: earlySetup,
      // Carry the decision-window fields so the offer detail screen (which sees an ext job as a
      // Job via this mapper) can render the customer countdown the same as a normal job.
      sentAt: sentAt,
      deadlineExtendedUntil: deadlineExtendedUntil,
    );
  }
}
