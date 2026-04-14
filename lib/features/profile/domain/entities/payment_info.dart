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
  });

  final PaymentType payment;
  final String? cpr;
  final int? registrationNumber;
  final String? accountNumber;
  final String? street;
  final String? cityPostalCode;
}
