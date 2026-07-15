import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/core/utils/phone_utils.dart';

/// `Jobs.lead_phone_number` is free text (`text NOT NULL`, no format constraint) filled
/// from the WordPress customer forms, so these cover what customers actually type.
void main() {
  group('dialablePhoneNumber — real numbers', () {
    test('keeps a already-clean international number as-is', () {
      expect(dialablePhoneNumber('+4542360666'), '+4542360666');
    });

    test('strips the spaces Danes write numbers with', () {
      expect(dialablePhoneNumber('+45 42 36 06 66'), '+4542360666');
      expect(dialablePhoneNumber('42 36 06 66'), '42360666');
    });

    test('strips punctuation but keeps the leading +', () {
      expect(dialablePhoneNumber('+45-42.36.06.66'), '+4542360666');
      expect(dialablePhoneNumber('(+45) 42360666'), '+4542360666');
    });

    test('a bare 8-digit Danish number is dialable', () {
      expect(dialablePhoneNumber('42360666'), '42360666');
    });

    test('a 00-prefixed international number keeps its digits', () {
      expect(dialablePhoneNumber('004542360666'), '004542360666');
    });
  });

  group(
    'dialablePhoneNumber — non-numbers must return null, not an empty recipient',
    () {
      // The bug this guards: naive stripping turns these into "", which builds
      // `sms:?body=...` — a composer whose recipient chip spins forever.
      test('placeholder text is not a number', () {
        expect(dialablePhoneNumber('ikke oplyst'), isNull);
        expect(dialablePhoneNumber('n/a'), isNull);
        expect(dialablePhoneNumber('-'), isNull);
        expect(dialablePhoneNumber('ved ikke'), isNull);
      });

      test('null and blank are not numbers', () {
        expect(dialablePhoneNumber(null), isNull);
        expect(dialablePhoneNumber(''), isNull);
        expect(dialablePhoneNumber('   '), isNull);
      });

      test('too few digits to be a real number', () {
        expect(dialablePhoneNumber('1234567'), isNull); // 7 digits
        expect(dialablePhoneNumber('+45 12'), isNull);
      });

      test(
        'an email or text with a couple of stray digits is not a number',
        () {
          expect(dialablePhoneNumber('kontakt mig pa mail'), isNull);
          expect(dialablePhoneNumber('ring efter kl 18'), isNull);
        },
      );
    },
  );

  group('dialablePhoneNumber — output is always a valid sms: recipient', () {
    test('never emits a non-leading +, which iOS cannot parse', () {
      // Apple's SMS Links grammar allows digits and a leading +. A mid-string +
      // would make the recipient unresolvable.
      expect(dialablePhoneNumber('+45+42360666'), '+4542360666');
      expect(dialablePhoneNumber('45+42360666'), '4542360666');
    });

    test('result contains only digits after an optional single leading +', () {
      for (final raw in [
        '+45 42 36 06 66',
        '(45) 42-36-06-66',
        '0045/42360666',
      ]) {
        final out = dialablePhoneNumber(raw);
        expect(out, isNotNull, reason: '$raw should be dialable');
        expect(
          RegExp(r'^\+?\d+$').hasMatch(out!),
          isTrue,
          reason: '$raw -> "$out" is not a clean sms: recipient',
        );
      }
    });
  });
}
