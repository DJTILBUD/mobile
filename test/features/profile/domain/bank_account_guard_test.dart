import 'package:dj_tilbud_app/features/profile/domain/bank_account_guard.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors web-app/src/helpers/bankAccountGuard.test.ts case for case.
void main() {
  BankAccountProblem? alex(String? account, {String? cvr = '44276038'}) =>
      bankAccountProblem(
        registrationNumber: '6116',
        accountNumber: account,
        cvr: cvr,
        cpr: '250405-7049',
      );

  test('rejects the real incident: the CVR typed as the account number', () {
    expect(alex('44276038'), BankAccountProblem.matchesCvr);
  });

  test('rejects the CVR with spaces or leading zeros', () {
    expect(alex('4427 6038'), BankAccountProblem.matchesCvr);
    expect(alex('0044276038'), BankAccountProblem.matchesCvr);
  });

  test('rejects the CVR split across reg and account', () {
    expect(
      bankAccountProblem(
        cvr: '44276038',
        registrationNumber: '4427',
        accountNumber: '6038',
      ),
      BankAccountProblem.matchesCvr,
    );
  });

  test('rejects the CPR as the account number, with or without the dash', () {
    expect(alex('2504057049', cvr: null), BankAccountProblem.matchesCpr);
    expect(alex('250405-7049', cvr: null), BankAccountProblem.matchesCpr);
  });

  test('rejects the CPR split across reg and account', () {
    expect(
      bankAccountProblem(
        cpr: '250405-7049',
        registrationNumber: '2504',
        accountNumber: '057049',
      ),
      BankAccountProblem.matchesCpr,
    );
  });

  test('rejects an account equal to the reg number', () {
    expect(
      bankAccountProblem(registrationNumber: '6116', accountNumber: '6116'),
      BankAccountProblem.matchesReg,
    );
  });

  test('rejects one repeated digit', () {
    expect(
      bankAccountProblem(registrationNumber: '6116', accountNumber: '00000000'),
      BankAccountProblem.repeatedDigit,
    );
    expect(
      bankAccountProblem(
        registrationNumber: '6116',
        accountNumber: '1111111111',
      ),
      BankAccountProblem.repeatedDigit,
    );
  });

  test('rejects wrong lengths and letters', () {
    expect(
      bankAccountProblem(accountNumber: '123'),
      BankAccountProblem.accountFormat,
    );
    expect(
      bankAccountProblem(accountNumber: '12345678901'),
      BankAccountProblem.accountFormat,
    );
    expect(
      bankAccountProblem(accountNumber: 'DK5000400440116243'),
      BankAccountProblem.accountFormat,
    );
  });

  test('rejects a malformed reg number', () {
    expect(
      bankAccountProblem(
        registrationNumber: '61160',
        accountNumber: '3456789012',
      ),
      BankAccountProblem.regFormat,
    );
    expect(
      bankAccountProblem(
        registrationNumber: '61a6',
        accountNumber: '3456789012',
      ),
      BankAccountProblem.regFormat,
    );
  });

  test('accepts a normal account, also with separators', () {
    expect(alex('3456789012'), isNull);
    expect(alex('345-678 9012'), isNull);
    expect(
      bankAccountProblem(
        registrationNumber: '400',
        accountNumber: '4401162430',
      ),
      isNull,
    );
  });

  test('does not judge an empty account', () {
    expect(alex(''), isNull);
    expect(alex(null), isNull);
  });

  test('ignores a CVR or CPR that is not a full number', () {
    expect(bankAccountProblem(cvr: '4427', accountNumber: '44276038'), isNull);
    expect(
      bankAccountProblem(cpr: '250405', accountNumber: '2504050000'),
      isNull,
    );
  });

  test('returns the Danish message', () {
    expect(
      bankAccountError(
        registrationNumber: '6116',
        accountNumber: '44276038',
        cvr: '44276038',
      ),
      bankAccountMessages[BankAccountProblem.matchesCvr],
    );
    expect(
      bankAccountError(registrationNumber: '6116', accountNumber: '3456789012'),
      isNull,
    );
  });
}
