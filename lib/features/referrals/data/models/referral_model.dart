import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/referral_labels.dart';

/// JSON shape of `GET /api/referrals` items (web `ReferralListItem`) and of the `referral` +
/// `extJob` returned by `POST /api/referrals`.
class ReferralModel {
  const ReferralModel({
    required this.id,
    required this.type,
    required this.status,
    required this.rewardDkk,
    required this.createdAt,
    this.closedAt,
    this.canceledAt,
    this.canceledReason,
    this.job,
    this.payoutStatus,
  });

  final int id;
  final String type;
  final String status;
  final num rewardDkk;
  final String createdAt;
  final String? closedAt;
  final String? canceledAt;
  final String? canceledReason;
  final Map<String, dynamic>? job;
  final String? payoutStatus;

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      status: json['status'] as String,
      rewardDkk: _num(json['reward_dkk']),
      createdAt: json['created_at'] as String,
      closedAt: json['closed_at'] as String?,
      canceledAt: json['canceled_at'] as String?,
      canceledReason: json['canceled_reason'] as String?,
      job: json['job'] as Map<String, dynamic>?,
      payoutStatus: json['payout_status'] as String?,
    );
  }

  /// The POST response carries the bare `Referrals` row plus the created ExtJob separately.
  factory ReferralModel.fromCreateResponse(
    Map<String, dynamic> referral,
    Map<String, dynamic>? extJob,
  ) {
    return ReferralModel.fromJson({
      ...referral,
      'job':
          extJob == null
              ? null
              : {
                'id': extJob['id'],
                'lead_name': extJob['lead_name'],
                'date': extJob['date'],
                'event_type': extJob['event_type'],
                'location': extJob['location'],
                'status': extJob['status'],
              },
      'payout_status': null,
    });
  }

  static num _num(Object? v) =>
      v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

  Referral toEntity() {
    final j = job;
    return Referral(
      id: id,
      type: _type(type),
      status: _status(status),
      rewardDkk: rewardDkk.round(),
      createdAt: DateTime.parse(createdAt),
      closedAt: closedAt == null ? null : DateTime.tryParse(closedAt!),
      canceledAt: canceledAt == null ? null : DateTime.tryParse(canceledAt!),
      canceledReason: canceledReason,
      payoutStatus: payoutStatus,
      job:
          j == null || j['date'] == null
              ? null
              : ReferralJob(
                id: (j['id'] as num).toInt(),
                leadName: (j['lead_name'] as String?) ?? '',
                date: DateTime.parse(j['date'] as String),
                status: (j['status'] as String?) ?? 'open',
                eventType: j['event_type'] as String?,
                location: j['location'] as String?,
              ),
    );
  }

  static ReferralType _type(String v) => switch (v) {
    'dj_referral' => ReferralType.djReferral,
    'saxophonist_referral' => ReferralType.saxophonistReferral,
    _ => ReferralType.wineReferral,
  };

  static ReferralStatus _status(String v) => switch (v) {
    'closed' => ReferralStatus.closed,
    'canceled' => ReferralStatus.canceled,
    _ => ReferralStatus.open,
  };

  static Map<String, dynamic> inputToJson(ReferralInput input) {
    String? clean(String? s) =>
        (s == null || s.trim().isEmpty) ? null : s.trim();
    return {
      'lead_name': input.leadName.trim(),
      'phone_number': input.phoneNumber.trim(),
      'email': clean(input.email),
      'date': input.date.toIso8601String().substring(0, 10),
      'event_type': input.eventType,
      'region': input.region,
      'location': clean(input.location),
      'guests_amount': input.guestsAmount,
      'role_type': roleTypeApiValue(input.roleType),
      'notes': clean(input.notes),
    };
  }
}
