import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';

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

  SelfBillingInfo toSelfBillingInfo() => SelfBillingInfo(
    businessType: businessType,
    cpr: cpr,
    cvr: cvr,
    billingEmail: billingEmail,
  );
}
