import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/profile/data/models/payment_info_model.dart';
import 'package:dj_tilbud_app/features/profile/domain/billing_email_validation.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/billing_change_request.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';

// Billing lock (web-app/documentation/billing-lock-plan.md): the lock state and
// the change request come from the web API and must survive parsing.
void main() {
  group('PaymentInfoModel billing_locked_at', () {
    test('null means editable', () {
      final info =
          PaymentInfoModel.fromJson({'payment': 'B-income'}).toEntity();
      expect(info.isLocked, isFalse);
      expect(info.billingLockedAt, isNull);
    });

    test('a timestamp means locked', () {
      final info =
          PaymentInfoModel.fromJson({
            'payment': 'Invoice',
            'billing_locked_at': '2026-09-29T10:00:00+00:00',
          }).toEntity();
      expect(info.isLocked, isTrue);
      expect(info.billingLockedAt!.toUtc(), DateTime.utc(2026, 9, 29, 10));
    });

    test('is never sent back to the server', () {
      final model = PaymentInfoModel.fromJson({
        'payment': 'Invoice',
        'billing_locked_at': '2026-09-29T10:00:00+00:00',
      });
      expect(model.toJson().containsKey('billing_locked_at'), isFalse);
    });
  });

  group('PaymentInfoModel billing_email_secondary', () {
    test('round-trips through fromJson, toEntity and toJson', () {
      final model = PaymentInfoModel.fromJson({
        'payment': 'Invoice',
        'billing_email': 'a@b.dk',
        'billing_email_secondary': 'bogholder@b.dk',
      });
      expect(model.toEntity().billingEmailSecondary, 'bogholder@b.dk');
      expect(model.toJson()['billing_email_secondary'], 'bogholder@b.dk');
    });

    test('missing or empty means null', () {
      expect(
        PaymentInfoModel.fromJson({
          'payment': 'Invoice',
        }).toEntity().billingEmailSecondary,
        isNull,
      );
      final model = PaymentInfoModel.fromJson({
        'payment': 'Invoice',
        'billing_email_secondary': '  ',
      });
      expect(model.toEntity().billingEmailSecondary, isNull);
      expect(model.toJson()['billing_email_secondary'], isNull);
    });

    test('is not required for completeness', () {
      final info =
          PaymentInfoModel.fromJson({
            'payment': 'Invoice',
            'business_type': 'aps',
            'cvr': '12345678',
            'billing_email': 'a@b.dk',
            'registration_number': '1234',
            'account_number': '1234567890',
          }).toEntity();
      expect(info.billingEmailSecondary, isNull);
      expect(isPaymentInfoComplete(info.toReadinessInfo()), isTrue);
    });
  });

  group('validateSecondaryBillingEmail', () {
    test('empty is allowed', () {
      expect(validateSecondaryBillingEmail('', 'a@b.dk'), isNull);
      expect(validateSecondaryBillingEmail(null, 'a@b.dk'), isNull);
      expect(validateSecondaryBillingEmail('   ', 'a@b.dk'), isNull);
    });

    test('must be a valid email', () {
      expect(
        validateSecondaryBillingEmail('ikke-en-email', 'a@b.dk'),
        'Indtast en gyldig email',
      );
    });

    test('must differ from the primary (trimmed, case-insensitive)', () {
      expect(
        validateSecondaryBillingEmail(' A@B.dk ', 'a@b.dk'),
        'Den ekstra email skal være forskellig fra den første',
      );
      expect(validateSecondaryBillingEmail('c@b.dk', 'a@b.dk'), isNull);
    });
  });

  group('BillingChangeRequest.fromJson', () {
    test('parses every status string the API sends', () {
      for (final entry
          in {
            'pending': BillingChangeRequestStatus.pending,
            'approved': BillingChangeRequestStatus.approved,
            'rejected': BillingChangeRequestStatus.rejected,
            'completed': BillingChangeRequestStatus.completed,
          }.entries) {
        final r = BillingChangeRequest.fromJson({
          'id': 1,
          'status': entry.key,
          'reason': 'Ny bank',
        });
        expect(r.status, entry.value);
      }
    });

    test('keeps the admin note', () {
      final r = BillingChangeRequest.fromJson({
        'id': 7,
        'status': 'rejected',
        'reason': 'Ny bank',
        'admin_note': 'Send kontoudtog',
        'created_at': '2026-09-29T10:00:00+00:00',
        'resolved_at': null,
      });
      expect(r.id, 7);
      expect(r.adminNote, 'Send kontoudtog');
      expect(r.createdAt, isNotNull);
      expect(r.resolvedAt, isNull);
    });
  });
}
