// Value-level validation for the billing email fields on payment_screen.dart.
// Pure so it can run on the controller values (Form.validate() skips fields the
// lazy ListView has unmounted, see CLAUDE.md) and be unit-tested.

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// The primary billing email: required and a valid email.
String? validateBillingEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Påkrævet';
  if (!_emailRegex.hasMatch(v)) return 'Indtast en gyldig email';
  return null;
}

/// The optional second billing email (`billing_email_secondary`): empty is
/// fine; otherwise a valid email that differs from the primary one
/// (trimmed, case-insensitive).
String? validateSecondaryBillingEmail(String? value, String? primary) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return null;
  if (!_emailRegex.hasMatch(v)) return 'Indtast en gyldig email';
  if (v.toLowerCase() == (primary ?? '').trim().toLowerCase()) {
    return 'Den ekstra email skal være forskellig fra den første';
  }
  return null;
}
