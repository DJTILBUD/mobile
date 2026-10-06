// Payment-info readiness for DJs and musicians. Direct mirror of the web-app's
// single source of truth (web-app/src/helpers/selfBillingComplete.ts); keep the
// two in sync.
//
// Two payment paths (PaymentInfo.payment):
//   B-income  we pay the person and report via CPR: CPR + bank + address (DAC7).
//   Invoice   the performer is paid against an invoice. EVERY business type may
//             choose it: private -> CPR (no CVR; allowed since 2026-09-30, a
//             private person sends their own invoice with the CPR on it),
//             sole_trader -> CVR + CPR, aps -> CVR. Plus billing email and
//             reg + account. sole_trader / aps are self-billed by DJTILBUD.
//
// `isSelfBillingComplete` is the older payment-agnostic identity rule.
// `isPaymentInfoComplete` picks the rule from the payment type and is what the
// bid gates use (the web Redirecter enforces the same function).
//
// Per business type:
//   private     -> CPR required, no CVR
//   sole_trader -> CVR AND CPR required (enkeltmandsvirksomhed)
//   aps         -> CVR required, CPR not required
//
// Note: `cpr`, `registration_number` and `account_number` are stored encrypted,
// so only their PRESENCE is meaningful here (never their value).

/// Business entity type — mirrors the web-app `BusinessEntityType` union
/// ('private' | 'sole_trader' | 'aps') and the Postgres enum.
enum BusinessEntityType {
  private_,
  soleTrader,
  aps;

  static BusinessEntityType? fromString(String? value) {
    switch (value) {
      case 'private':
        return BusinessEntityType.private_;
      case 'sole_trader':
        return BusinessEntityType.soleTrader;
      case 'aps':
        return BusinessEntityType.aps;
      default:
        return null;
    }
  }

  String toDbString() {
    switch (this) {
      case BusinessEntityType.private_:
        return 'private';
      case BusinessEntityType.soleTrader:
        return 'sole_trader';
      case BusinessEntityType.aps:
        return 'aps';
    }
  }

  /// CVR is required for every business type except a private individual.
  bool get requiresCvr => this != BusinessEntityType.private_;

  /// CPR is required for every business type except an ApS.
  bool get requiresCpr => this != BusinessEntityType.aps;

  /// May choose Invoice: every type. A private person has a CPR where the others
  /// have a CVR. Mirror of INVOICE_BUSINESS_TYPES in the web-app.
  bool get canInvoice => true;
}

/// Everything the payment-type aware rule looks at. Built from a PaymentInfo via
/// `toReadinessInfo()`; mirror of `PaymentInfoShape` in the web-app.
class PaymentReadinessInfo {
  const PaymentReadinessInfo({
    this.payment,
    this.businessType,
    this.cpr,
    this.cvr,
    this.billingEmail,
    this.registrationNumber,
    this.accountNumber,
    this.street,
    this.cityPostalCode,
  });

  /// 'Invoice' | 'B-income' | null (nothing chosen yet).
  final String? payment;
  final BusinessEntityType? businessType;
  final String? cpr;
  final String? cvr;
  final String? billingEmail;
  final String? registrationNumber;
  final String? accountNumber;
  final String? street;
  final String? cityPostalCode;

  SelfBillingInfo toSelfBillingInfo() => SelfBillingInfo(
    businessType: businessType,
    cpr: cpr,
    cvr: cvr,
    billingEmail: billingEmail,
  );
}

/// The subset of private info that determines self-billing readiness.
class SelfBillingInfo {
  const SelfBillingInfo({
    this.businessType,
    this.cpr,
    this.cvr,
    this.billingEmail,
  });

  final BusinessEntityType? businessType;
  final String? cpr;
  final String? cvr;
  final String? billingEmail;
}

bool _present(String? v) => v != null && v.trim().isNotEmpty;

/// Mirror of `isSelfBillingComplete` in the web-app.
bool isSelfBillingComplete(SelfBillingInfo? info) {
  final type = info?.businessType;
  if (info == null || type == null) return false;
  if (!_present(info.billingEmail)) return false;
  if (type.requiresCvr && !_present(info.cvr)) return false;
  if (type.requiresCpr && !_present(info.cpr)) return false;
  return true;
}

/// The Invoice path: a business type with ITS ids (private: CPR; sole trader:
/// CVR + CPR; ApS: CVR), a billing email and a bank account. Mirror of `isSelfBillingPayoutReady` in the web-app.
bool isSelfBillingPayoutReady(PaymentReadinessInfo? info) {
  final type = info?.businessType;
  if (info == null || type == null) return false;
  if (!type.canInvoice) return false;
  if (!isSelfBillingComplete(info.toSelfBillingInfo())) return false;
  if (!_present(info.registrationNumber) || !_present(info.accountNumber)) {
    return false;
  }
  return true;
}

/// The B-income path: CPR + bank + address (DAC7). Mirror of `isDac7Complete`.
bool isDac7Complete(PaymentReadinessInfo? info) {
  if (info == null) return false;
  return _present(info.cpr) &&
      _present(info.registrationNumber) &&
      _present(info.accountNumber) &&
      _present(info.street) &&
      _present(info.cityPostalCode);
}

/// The rule the bid gates enforce, chosen by payment type. Mirror of
/// `isPaymentInfoComplete` in the web-app (used by its Redirecter).
bool isPaymentInfoComplete(PaymentReadinessInfo? info) {
  final payment = info?.payment;
  if (info == null || payment == null) return false;
  return payment == 'Invoice'
      ? isSelfBillingPayoutReady(info)
      : isDac7Complete(info);
}

/// Danish list of what an Invoice performer still lacks before self-billing can
/// pay them. Mirror of `missingPayoutReadyFields` in the web-app.
List<String> missingPayoutReadyFields(PaymentReadinessInfo? info) {
  final missing = <String>[];
  final type = info?.businessType;
  if (info == null || type == null || !type.canInvoice) {
    missing.add(
      'virksomhedstype (privatperson, enkeltmandsvirksomhed eller ApS)',
    );
  } else {
    if (type.requiresCvr && !_present(info.cvr)) missing.add('CVR');
    if (type.requiresCpr && !_present(info.cpr)) missing.add('CPR');
  }
  if (info == null || !_present(info.billingEmail)) {
    missing.add('fakturerings-email');
  }
  if (info == null ||
      !_present(info.registrationNumber) ||
      !_present(info.accountNumber)) {
    missing.add('bankoplysninger');
  }
  return missing;
}

/// Human-readable list (Danish) of what is still missing, for error messages.
/// Mirror of `missingSelfBillingFields` in the web-app.
List<String> missingSelfBillingFields(SelfBillingInfo? info) {
  final missing = <String>[];
  final type = info?.businessType;
  if (info == null || type == null) {
    missing.add('virksomhedstype');
    missing.add('CVR eller CPR');
  } else {
    if (type.requiresCvr && !_present(info.cvr)) missing.add('CVR');
    if (type.requiresCpr && !_present(info.cpr)) missing.add('CPR');
  }
  if (info == null || !_present(info.billingEmail)) {
    missing.add('fakturerings-email');
  }
  return missing;
}
