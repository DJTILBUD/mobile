import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_reference_format.dart';

class PaymentInfoModel {
  const PaymentInfoModel({
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
    this.referenceFormat,
    this.selfBillingTermsAcceptedAt,
  });

  final String payment;
  final String? cpr;
  final String? registrationNumber;
  final String? accountNumber;
  final String? street;
  final String? cityPostalCode;
  final String? businessType;
  final String? cvr;
  final String? billingEmail;
  final String? billingEmailSecondary;
  // Server-derived; parsed for display, deliberately absent from toJson().
  final String? cvrCompanyName;
  // Server-owned lock timestamp; parsed for display, absent from toJson().
  final String? billingLockedAt;
  // Not billing-locked: saved on its own, so deliberately absent from toJson().
  final String? referenceFormat;
  // Server-owned (stamped by the accept-terms endpoint); read-only, absent from toJson().
  final String? selfBillingTermsAcceptedAt;

  factory PaymentInfoModel.fromJson(Map<String, dynamic> json) {
    return PaymentInfoModel(
      payment: json['payment'] as String? ?? 'Invoice',
      cpr: json['cpr'] as String?,
      registrationNumber: json['registration_number']?.toString(),
      accountNumber: json['account_number'] as String?,
      street: json['street'] as String?,
      cityPostalCode: json['city_postal_code'] as String?,
      businessType: json['business_type'] as String?,
      cvr: json['cvr'] as String?,
      billingEmail: json['billing_email'] as String?,
      // Optional; an empty string is treated as not set.
      billingEmailSecondary: _nullIfBlank(
        json['billing_email_secondary'] as String?,
      ),
      cvrCompanyName: json['cvr_company_name'] as String?,
      billingLockedAt: json['billing_locked_at'] as String?,
      referenceFormat: json['self_billing_reference_format'] as String?,
      selfBillingTermsAcceptedAt:
          json['self_billing_terms_accepted_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment': payment,
      'cpr': cpr,
      'registration_number': registrationNumber,
      'account_number': accountNumber,
      'street': street,
      'city_postal_code': cityPostalCode,
      'business_type': businessType,
      'cvr': cvr,
      'billing_email': billingEmail,
      'billing_email_secondary': billingEmailSecondary,
    };
  }

  PaymentInfo toEntity() {
    return PaymentInfo(
      payment: PaymentType.fromString(payment),
      cpr: cpr,
      registrationNumber: registrationNumber,
      accountNumber: accountNumber,
      street: street,
      cityPostalCode: cityPostalCode,
      businessType: BusinessEntityType.fromString(businessType),
      cvr: cvr,
      billingEmail: billingEmail,
      billingEmailSecondary: billingEmailSecondary,
      cvrCompanyName: cvrCompanyName,
      billingLockedAt:
          billingLockedAt == null
              ? null
              : DateTime.tryParse(billingLockedAt!)?.toLocal(),
      referenceFormat: SelfBillingReferenceFormat.fromDb(referenceFormat),
      selfBillingTermsAccepted: selfBillingTermsAcceptedAt != null,
    );
  }
}

String? _nullIfBlank(String? v) => (v == null || v.trim().isEmpty) ? null : v;
