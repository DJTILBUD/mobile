import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_reference_format.dart';

enum PaymentType {
  invoice,
  bIncome;

  static PaymentType fromString(String value) {
    switch (value) {
      case 'Invoice':
        return PaymentType.invoice;
      case 'B-income':
        return PaymentType.bIncome;
      default:
        return PaymentType.invoice;
    }
  }

  String toDbString() {
    switch (this) {
      case PaymentType.invoice:
        return 'Invoice';
      case PaymentType.bIncome:
        return 'B-income';
    }
  }
}

class PaymentInfo {
  const PaymentInfo({
    required this.payment,
    this.cpr,
    this.registrationNumber,
    this.accountNumber,
    this.street,
    this.cityPostalCode,
    this.businessType,
    this.cvr,
    this.billingEmail,
    this.billingEmailSecondary,
    this.cvrCompanyName,
    this.billingLockedAt,
    this.referenceFormat = SelfBillingReferenceFormat.standard,
    this.selfBillingTermsAccepted = false,
  });

  final PaymentType payment;
  final String? cpr;
  final String? registrationNumber;
  final String? accountNumber;
  final String? street;
  final String? cityPostalCode;

  // Self-billing fields (see self_billing_complete.dart).
  final BusinessEntityType? businessType;
  final String? cvr;
  final String? billingEmail;

  /// Optional second address the self-billing "Afregning" is also sent to.
  /// Billing-locked like [billingEmail], but never required for completeness.
  final String? billingEmailSecondary;

  /// Registered company name behind the CVR, looked up by the web-app when the
  /// CVR is saved. Read-only on mobile: never sent back.
  final String? cvrCompanyName;

  /// Set = the info is locked since then and can only change after support
  /// approves a change request (web-app/documentation/billing-lock-plan.md).
  /// Server-owned: read-only on mobile, never sent back.
  final DateTime? billingLockedAt;

  bool get isLocked => billingLockedAt != null;

  /// The performer's own reference format. Not billing-locked, so it is
  /// saved separately ([ProfileRepository.saveSelfBillingReferenceFormat]).
  final SelfBillingReferenceFormat referenceFormat;

  /// Whether the performer accepted the self-billing terms (server-owned, read-only).
  final bool selfBillingTermsAccepted;

  /// Saved setup where DJTILBUD issues the afregning: everyone on Invoice,
  /// a private person too (since 2026-10-05).
  bool get isSelfBilled => payment == PaymentType.invoice;

  SelfBillingInfo toSelfBillingInfo() => SelfBillingInfo(
    businessType: businessType,
    cpr: cpr,
    cvr: cvr,
    billingEmail: billingEmail,
  );

  /// Input for the payment-type aware readiness rule (`isPaymentInfoComplete`).
  PaymentReadinessInfo toReadinessInfo() => PaymentReadinessInfo(
    payment: payment.toDbString(),
    businessType: businessType,
    cpr: cpr,
    cvr: cvr,
    billingEmail: billingEmail,
    registrationNumber: registrationNumber,
    accountNumber: accountNumber,
    street: street,
    cityPostalCode: cityPostalCode,
  );
}
