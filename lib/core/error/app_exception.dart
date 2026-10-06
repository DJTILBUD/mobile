sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() =>
      message.isNotEmpty ? message : 'Noget gik galt. Prøv igen.';
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class NoMusicianProfileException extends AppException {
  const NoMusicianProfileException()
    : super('Denne konto har ingen musikerprofil. Kontakt support.');
}

class NeedsProfileSetupException extends AppException {
  const NeedsProfileSetupException() : super('');
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {this.code});

  /// The web API's stable, machine-readable rejection code (e.g.
  /// `customer_not_contacted`), when the route sends one. Prefer matching on
  /// this over the Danish `message` — the text is user-facing copy and will be
  /// reworded; the code will not. Null for raw DB/PostgREST errors.
  final String? code;

  @override
  String toString() => 'Kunne ikke hente data. Prøv igen.';
}

/// Thrown when the web API rejects a quote/offer with HTTP 400 and
/// `code: "billing_info_incomplete"` — the user must complete their billing /
/// self-billing info before they can submit. `message` carries the server's
/// Danish, user-facing reason.
class BillingInfoIncompleteException extends AppException {
  const BillingInfoIncompleteException(super.message);
}

/// A billing-lock rejection from the web API (web-app/documentation/billing-lock-plan.md):
/// a save on locked payment info (HTTP 423, `code: "billing_locked"`) or a refused change
/// request (`reason_required`, `not_locked`, `already_open`). `message` is the server's
/// Danish, user-facing text and is shown as-is.
class BillingLockException extends AppException {
  const BillingLockException(super.message, {this.code});

  final String? code;
}

class AgentException extends AppException {
  const AgentException(super.message);
}

class AgentLimitException extends AppException {
  const AgentLimitException({required this.limitType}) : super('');
  // 'daily' | 'monthly'
  final String limitType;
}
