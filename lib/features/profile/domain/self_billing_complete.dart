// Self-billing readiness: a DJ/musician must provide their business type, the
// matching company number(s) and a billing email before they can submit
// quotes/offers. This is a direct mirror of the web-app's single source of truth
// (web-app/src/helpers/selfBillingComplete.ts) — keep the two in sync.
//
// Per business type:
//   private     -> CPR required, no CVR
//   sole_trader -> CVR AND CPR required (enkeltmandsvirksomhed)
//   aps         -> CVR required, CPR not required
//
// Note: `cpr` is stored encrypted, so only its PRESENCE is meaningful here
// (never its value). The server is the real gate; this mirror just lets the UI
// pre-disable submit and hint the user.

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
