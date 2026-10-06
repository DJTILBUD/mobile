import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirror of web-app/src/helpers/selfBillingComplete.test.ts. If a case is added
// there, add it here too (and vice versa): the two implementations must agree.
void main() {
  group('isSelfBillingComplete', () {
    test('incomplete when no record or no business type', () {
      expect(isSelfBillingComplete(null), isFalse);
      expect(
        isSelfBillingComplete(
          const SelfBillingInfo(cpr: 'x', cvr: '1', billingEmail: 'a@b.dk'),
        ),
        isFalse,
      );
    });

    test(
      'ApS requires CVR, private requires CPR, sole trader requires both',
      () {
        expect(
          isSelfBillingComplete(
            const SelfBillingInfo(
              businessType: BusinessEntityType.aps,
              cvr: '12345678',
              billingEmail: 'a@b.dk',
            ),
          ),
          isTrue,
        );
        expect(
          isSelfBillingComplete(
            const SelfBillingInfo(
              businessType: BusinessEntityType.private_,
              cpr: '123456-7890',
              billingEmail: 'a@b.dk',
            ),
          ),
          isTrue,
        );
        expect(
          isSelfBillingComplete(
            const SelfBillingInfo(
              businessType: BusinessEntityType.soleTrader,
              cvr: '12345678',
              billingEmail: 'a@b.dk',
            ),
          ),
          isFalse,
        );
      },
    );
  });

  group('isPaymentInfoComplete (payment-type aware)', () {
    PaymentReadinessInfo base({
      String? payment = 'Invoice',
      BusinessEntityType? businessType = BusinessEntityType.soleTrader,
      String? cpr = '123456-7890',
      String? cvr = '46181786',
      String? billingEmail = 'a@b.dk',
      String? registrationNumber = '1234',
      String? accountNumber = '1234567890',
      String? street = 'Vej 1',
      String? cityPostalCode = '8000 Aarhus',
    }) => PaymentReadinessInfo(
      payment: payment,
      businessType: businessType,
      cpr: cpr,
      cvr: cvr,
      billingEmail: billingEmail,
      registrationNumber: registrationNumber,
      accountNumber: accountNumber,
      street: street,
      cityPostalCode: cityPostalCode,
    );

    test('no payment type chosen is never complete', () {
      expect(isPaymentInfoComplete(base(payment: null)), isFalse);
      expect(isPaymentInfoComplete(null), isFalse);
    });

    test('Invoice + private is complete with CPR, email and bank, no CVR', () {
      final priv = base(businessType: BusinessEntityType.private_, cvr: null);
      expect(isPaymentInfoComplete(priv), isTrue);
      expect(isSelfBillingPayoutReady(priv), isTrue);
    });

    test('Invoice + private still needs CPR, billing email and bank', () {
      expect(
        isPaymentInfoComplete(
          base(businessType: BusinessEntityType.private_, cvr: null, cpr: null),
        ),
        isFalse,
      );
      expect(
        isPaymentInfoComplete(
          base(
            businessType: BusinessEntityType.private_,
            cvr: null,
            billingEmail: ' ',
          ),
        ),
        isFalse,
      );
      expect(
        isPaymentInfoComplete(
          base(
            businessType: BusinessEntityType.private_,
            cvr: null,
            accountNumber: null,
          ),
        ),
        isFalse,
      );
    });

    test('Invoice + sole trader needs CVR, CPR, email and bank', () {
      expect(isPaymentInfoComplete(base()), isTrue);
      expect(isPaymentInfoComplete(base(cvr: null)), isFalse);
      expect(isPaymentInfoComplete(base(cpr: null)), isFalse);
      expect(isPaymentInfoComplete(base(accountNumber: null)), isFalse);
      expect(isPaymentInfoComplete(base(registrationNumber: '  ')), isFalse);
    });

    test('Invoice + aps needs CVR, email and bank but not CPR', () {
      expect(
        isPaymentInfoComplete(
          base(businessType: BusinessEntityType.aps, cpr: null),
        ),
        isTrue,
      );
      expect(
        isPaymentInfoComplete(
          base(businessType: BusinessEntityType.aps, billingEmail: ' '),
        ),
        isFalse,
      );
    });

    test(
      'B-income needs CPR, bank and address and ignores business identity',
      () {
        expect(
          isPaymentInfoComplete(
            base(
              payment: 'B-income',
              businessType: BusinessEntityType.private_,
              cvr: null,
              billingEmail: null,
            ),
          ),
          isTrue,
        );
        expect(
          isPaymentInfoComplete(
            base(
              payment: 'B-income',
              businessType: BusinessEntityType.private_,
              cpr: null,
            ),
          ),
          isFalse,
        );
        expect(
          isPaymentInfoComplete(
            base(
              payment: 'B-income',
              businessType: BusinessEntityType.private_,
              street: null,
            ),
          ),
          isFalse,
        );
      },
    );

    test(
      'missingPayoutReadyFields asks a private person for CPR and bank, never a CVR',
      () {
        final missing = missingPayoutReadyFields(
          base(
            businessType: BusinessEntityType.private_,
            cvr: null,
            cpr: null,
            accountNumber: null,
          ),
        );
        expect(missing, ['CPR', 'bankoplysninger']);
      },
    );
  });
}
