import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';

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
    );
  }
}
