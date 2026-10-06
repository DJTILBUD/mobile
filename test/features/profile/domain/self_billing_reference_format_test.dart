import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/profile/data/models/payment_info_model.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_reference_format.dart';

/// Mirrors web-app src/helpers/selfBillingReferenceFormat.ts: the two DB enum
/// values, and unknown/missing reads as standard (the DB default).
void main() {
  group('SelfBillingReferenceFormat', () {
    test('db values match the Postgres enum', () {
      expect(SelfBillingReferenceFormat.values.map((f) => f.dbValue).toList(), [
        'standard',
        'date_seq',
      ]);
    });

    test('fromDb falls back to standard', () {
      expect(
        SelfBillingReferenceFormat.fromDb('date_seq'),
        SelfBillingReferenceFormat.dateSeq,
      );
      expect(
        SelfBillingReferenceFormat.fromDb(null),
        SelfBillingReferenceFormat.standard,
      );
      expect(
        SelfBillingReferenceFormat.fromDb('nonsense'),
        SelfBillingReferenceFormat.standard,
      );
    });
  });

  group('PaymentInfoModel', () {
    test('parses the format and never sends it with the locked form', () {
      final model = PaymentInfoModel.fromJson({
        'payment': 'Invoice',
        'business_type': 'aps',
        'self_billing_reference_format': 'date_seq',
      });
      expect(
        model.toEntity().referenceFormat,
        SelfBillingReferenceFormat.dateSeq,
      );
      expect(
        model.toJson().containsKey('self_billing_reference_format'),
        isFalse,
      );
    });
  });

  group('PaymentInfo.isSelfBilled', () {
    PaymentInfo info(PaymentType p, BusinessEntityType? b) =>
        PaymentInfo(payment: p, businessType: b);

    test('everyone on Invoice, a private person too; never B-income', () {
      expect(
        info(PaymentType.invoice, BusinessEntityType.aps).isSelfBilled,
        isTrue,
      );
      expect(
        info(PaymentType.invoice, BusinessEntityType.soleTrader).isSelfBilled,
        isTrue,
      );
      expect(
        info(PaymentType.invoice, BusinessEntityType.private_).isSelfBilled,
        isTrue,
      );
      expect(info(PaymentType.invoice, null).isSelfBilled, isTrue);
      expect(
        info(PaymentType.bIncome, BusinessEntityType.aps).isSelfBilled,
        isFalse,
      );
    });
  });
}
