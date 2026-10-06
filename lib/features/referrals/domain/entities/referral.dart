/// A job a performer handed to DJTILBUD ("Henvisninger" - "Henvis en kunde til os").
/// Pure Dart mirror of the web `ReferralListItem` (web-app/src/helpers/referrals.ts).
/// Plan: web-app/documentation/referrals-plan.md.
enum ReferralType { djReferral, saxophonistReferral, wineReferral }

enum ReferralStatus { open, closed, canceled }

/// What the customer is looking for. Mirrors `external_job_role_type`.
enum ReferralRoleType { djOnly, musicianOnly, djAndMusician }

class ReferralJob {
  const ReferralJob({
    required this.id,
    required this.leadName,
    required this.date,
    required this.status,
    this.eventType,
    this.location,
  });

  final int id;
  final String leadName;
  final DateTime date;

  /// The raw `ExtJobs.status` value (open, sent, closed, customer_contacted, ...).
  final String status;
  final String? eventType;
  final String? location;
}

class Referral {
  const Referral({
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
  final ReferralType type;
  final ReferralStatus status;
  final int rewardDkk;
  final DateTime createdAt;
  final DateTime? closedAt;
  final DateTime? canceledAt;
  final String? canceledReason;
  final ReferralJob? job;

  /// The self-billing `Payouts.status` for the reward, null until the cron has created one.
  final String? payoutStatus;

  /// "#E123", the app-wide ext-job-ref convention. Every referral a performer creates is an
  /// ExtJobs lead (see createReferral.ts), so this is always correct without needing the server
  /// to distinguish job_id/ext_job_id the way the admin-facing wine-referral case does.
  String? get jobRef => job == null ? null : '#E${job!.id}';
}

/// What the performer fills in when handing a job over. Mirrors the body of
/// `POST /api/referrals` (web-app/src/app/api/referrals/validations/ReferralRequestSchema.ts).
class ReferralInput {
  const ReferralInput({
    required this.leadName,
    required this.phoneNumber,
    required this.date,
    required this.eventType,
    required this.region,
    this.email,
    this.location,
    this.guestsAmount,
    this.roleType = ReferralRoleType.djOnly,
    this.notes,
  });

  final String leadName;
  final String phoneNumber;
  final DateTime date;

  /// One of [referralEventTypes] (the Danish label the customer forms store).
  final String eventType;

  /// One of [referralRegions] (the `region` enum).
  final String region;
  final String? email;
  final String? location;
  final int? guestsAmount;
  final ReferralRoleType roleType;
  final String? notes;
}
