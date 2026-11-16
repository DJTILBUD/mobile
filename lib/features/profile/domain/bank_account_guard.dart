/// Guards a performer's bank account against the mistake that cost a DJ his
/// payout (2026-10-13): he typed his CVR number into the account field and the
/// payout went to a non-existent account. A CVR and an account number are both
/// 8 digits, so nothing caught it.
///
/// Mirrors `web-app/src/helpers/bankAccountGuard.ts` (and admin
/// `lib/bankAccountGuard.ts`) rule for rule, with the same tests. The web-app
/// save route enforces it too; this copy lets the form explain it before saving.
library;

enum BankAccountProblem {
  accountFormat,
  regFormat,
  matchesCvr,
  matchesCpr,
  matchesReg,
  repeatedDigit,
}

const bankAccountMessages = <BankAccountProblem, String>{
  BankAccountProblem.accountFormat:
      'Kontonummeret skal være 4 til 10 cifre. Du finder det i din netbank.',
  BankAccountProblem.regFormat: 'Registreringsnummeret skal være 4 cifre.',
  BankAccountProblem.matchesCvr:
      'Kontonummeret er det samme som dit CVR-nummer. Skriv kontonummeret fra din bank, ikke dit CVR-nummer.',
  BankAccountProblem.matchesCpr:
      'Kontonummeret er det samme som dit CPR-nummer. Skriv kontonummeret fra din bank, ikke dit CPR-nummer.',
  BankAccountProblem.matchesReg:
      'Kontonummeret er det samme som registreringsnummeret. Skriv kontonummeret fra din bank.',
  BankAccountProblem.repeatedDigit:
      'Kontonummeret ser ikke rigtigt ud. Skriv kontonummeret fra din bank.',
};

String _digits(String? value) =>
    value == null ? '' : value.replaceAll(RegExp(r'\D'), '');

String _strip(String s) => s.replaceFirst(RegExp(r'^0+'), '');

/// Null when the account is plausible or empty (completeness is checked
/// elsewhere).
BankAccountProblem? bankAccountProblem({
  String? registrationNumber,
  String? accountNumber,
  String? cvr,
  String? cpr,
}) {
  final rawAccount = (accountNumber ?? '').trim();
  if (rawAccount.isEmpty) return null;

  final account = _digits(rawAccount);
  if (!RegExp(r'^[\d\s.-]+$').hasMatch(rawAccount) ||
      account.length < 4 ||
      account.length > 10) {
    return BankAccountProblem.accountFormat;
  }

  final regRaw = (registrationNumber ?? '').trim();
  final reg = _digits(regRaw);
  if (regRaw.isNotEmpty &&
      (reg.isEmpty ||
          reg.length > 4 ||
          !RegExp(r'^[\d\s]+$').hasMatch(regRaw))) {
    return BankAccountProblem.regFormat;
  }
  final regPadded = reg.isEmpty ? '' : reg.padLeft(4, '0');

  final cvrDigits = _digits(cvr);
  final cprDigits = _digits(cpr);
  final accountKey = _strip(account);
  final combined = _strip(regPadded + account);

  if (cvrDigits.length == 8 &&
      (accountKey == _strip(cvrDigits) || combined == _strip(cvrDigits))) {
    return BankAccountProblem.matchesCvr;
  }
  if (cprDigits.length == 10 &&
      (accountKey == _strip(cprDigits) ||
          combined == _strip(cprDigits) ||
          account.contains(cprDigits))) {
    return BankAccountProblem.matchesCpr;
  }
  if (regPadded.isNotEmpty && accountKey == _strip(regPadded)) {
    return BankAccountProblem.matchesReg;
  }
  if (RegExp(r'^(\d)\1+$').hasMatch(account)) {
    return BankAccountProblem.repeatedDigit;
  }
  return null;
}

String? bankAccountError({
  String? registrationNumber,
  String? accountNumber,
  String? cvr,
  String? cpr,
}) {
  final problem = bankAccountProblem(
    registrationNumber: registrationNumber,
    accountNumber: accountNumber,
    cvr: cvr,
    cpr: cpr,
  );
  return problem == null ? null : bankAccountMessages[problem];
}
