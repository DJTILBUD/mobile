import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';

class PaymentInfoModel {
  const PaymentInfoModel({
    required this.payment,
    this.cpr,
    this.registrationNumber,
    this.accountNumber,
    this.street,
    this.cityPostalCode,
  });

  final String payment;
  final String? cpr;
  final int? registrationNumber;
  final String? accountNumber;
  final String? street;
  final String? cityPostalCode;

  factory PaymentInfoModel.fromJson(Map<String, dynamic> json) {
    return PaymentInfoModel(
      payment: json['payment'] as String? ?? 'Invoice',
      cpr: json['cpr'] as String?,
      registrationNumber: (json['registration_number'] as num?)?.toInt(),
      accountNumber: json['account_number'] as String?,
      street: json['street'] as String?,
      cityPostalCode: json['city_postal_code'] as String?,
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
    );
  }
}
