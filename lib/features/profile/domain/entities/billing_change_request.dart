/// A performer's request to unlock their billing info, handled by support in the
/// admin tool (web-app/documentation/billing-lock-plan.md). Mirrors the public
/// shape returned by `GET/POST /api/billing-change-requests`.
enum BillingChangeRequestStatus {
  pending,
  approved,
  rejected,
  completed;

  static BillingChangeRequestStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return BillingChangeRequestStatus.approved;
      case 'rejected':
        return BillingChangeRequestStatus.rejected;
      case 'completed':
        return BillingChangeRequestStatus.completed;
      default:
        return BillingChangeRequestStatus.pending;
    }
  }
}

class BillingChangeRequest {
  const BillingChangeRequest({
    required this.id,
    required this.status,
    required this.reason,
    this.adminNote,
    this.createdAt,
    this.resolvedAt,
  });

  final int id;
  final BillingChangeRequestStatus status;
  final String reason;
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  factory BillingChangeRequest.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return BillingChangeRequest(
      id: (json['id'] as num).toInt(),
      status: BillingChangeRequestStatus.fromString(json['status'] as String?),
      reason: json['reason'] as String? ?? '',
      adminNote: json['admin_note'] as String?,
      createdAt: date(json['created_at']),
      resolvedAt: date(json['resolved_at']),
    );
  }
}
