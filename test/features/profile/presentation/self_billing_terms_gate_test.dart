import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/profile/data/models/payment_info_model.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';

/// Mirrors web needsSelfBillingTermsAcceptance (DjSidebar/MusicianSidebar): flag on, saved payment
/// type Faktura, terms not accepted yet.
bool _needs({required bool live, PaymentInfo? info}) {
  final container = ProviderContainer(
    overrides: [
      selfBillingLiveProvider.overrideWith((ref) async => live),
      djPaymentInfoProvider.overrideWith((ref) async => info),
    ],
  );
  addTearDown(container.dispose);
  return container.read(needsSelfBillingTermsProvider(true));
}

Future<bool> _settle({required bool live, PaymentInfo? info}) async {
  final container = ProviderContainer(
    overrides: [
      selfBillingLiveProvider.overrideWith((ref) async => live),
      djPaymentInfoProvider.overrideWith((ref) async => info),
    ],
  );
  addTearDown(container.dispose);
  await container.read(selfBillingLiveProvider.future);
  await container.read(djPaymentInfoProvider.future);
  return container.read(needsSelfBillingTermsProvider(true));
}

void main() {
  const invoiceNotAccepted = PaymentInfo(payment: PaymentType.invoice);
  const invoiceAccepted = PaymentInfo(
    payment: PaymentType.invoice,
    selfBillingTermsAccepted: true,
  );
  const bIncome = PaymentInfo(payment: PaymentType.bIncome);

  test('flag on + Faktura + not accepted -> popup', () async {
    expect(await _settle(live: true, info: invoiceNotAccepted), isTrue);
  });

  test('flag OFF -> never, even when not accepted', () async {
    expect(await _settle(live: false, info: invoiceNotAccepted), isFalse);
  });

  test('already accepted -> no popup', () async {
    expect(await _settle(live: true, info: invoiceAccepted), isFalse);
  });

  test('B-honorar or no payment info -> no popup', () async {
    expect(await _settle(live: true, info: bIncome), isFalse);
    expect(await _settle(live: true, info: null), isFalse);
  });

  test(
    'false while still loading, so the gate never blocks on a slow lookup',
    () {
      expect(_needs(live: true, info: invoiceNotAccepted), isFalse);
    },
  );

  test('the model reads self_billing_terms_accepted_at', () {
    final accepted =
        PaymentInfoModel.fromJson({
          'payment': 'Invoice',
          'self_billing_terms_accepted_at': '2026-10-06T10:00:00Z',
        }).toEntity();
    final open = PaymentInfoModel.fromJson({'payment': 'Invoice'}).toEntity();
    expect(accepted.selfBillingTermsAccepted, isTrue);
    expect(open.selfBillingTermsAccepted, isFalse);
  });
}
