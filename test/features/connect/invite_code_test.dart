import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/domain/invite_code.dart';

void main() {
  group('alphabet and generation', () {
    test('new codes never use the look-alikes 0, O, 1, I or L', () {
      for (final c in ['0', 'O', '1', 'I', 'L']) {
        expect(kInviteCodeAlphabet.contains(c), isFalse, reason: c);
      }
      // The same 31 characters the server rotates codes with.
      expect(kInviteCodeAlphabet.length, 31);
      expect(kInviteCodeAlphabet.split('').toSet().length, 31);
    });

    test('generated codes are 8 characters from the alphabet', () {
      final random = Random(7);
      for (var i = 0; i < 500; i++) {
        final code = generateInviteCode(random);
        expect(code.length, kInviteCodeLength);
        expect(
          code.split('').every(kInviteCodeAlphabet.contains),
          isTrue,
          reason: code,
        );
        // Old app builds validate `^[A-Z0-9]{8}$`; new codes must pass it.
        expect(isValidInviteCode(code), isTrue);
      }
    });

    test('the default generator is secure and still well-formed', () {
      final codes = {for (var i = 0; i < 50; i++) generateInviteCode()};
      expect(codes.length, greaterThan(45));
      expect(codes.every(isValidInviteCode), isTrue);
    });

    test('existing codes with old characters still validate', () {
      expect(isValidInviteCode('AB0O1IL9'), isTrue);
      expect(isValidInviteCode('ABCD123'), isFalse);
      expect(isValidInviteCode('ABCD12345'), isFalse);
      expect(isValidInviteCode('abcd2345'), isFalse);
    });
  });

  group('normalizeInviteCode', () {
    test('trims, upper-cases and drops spaces and hyphens', () {
      expect(normalizeInviteCode('  abcd2345 \n'), 'ABCD2345');
      expect(normalizeInviteCode('ABCD-2345'), 'ABCD2345');
      expect(normalizeInviteCode('abcd 2345'), 'ABCD2345');
      expect(normalizeInviteCode('AB CD-23 45'), 'ABCD2345');
      expect(normalizeInviteCode('ABCD–2345'), 'ABCD2345'); // en dash
      expect(normalizeInviteCode('ABCD_2345'), 'ABCD2345');
    });

    test('does not rewrite look-alikes, so old codes keep working', () {
      expect(normalizeInviteCode('ab0o1il9'), 'AB0O1IL9');
    });
  });

  group('findInviteCodeInText', () {
    const code = 'K7MP2QXR';

    test('finds the code inside the whole Korean share message', () {
      const message =
          '나 운동 약속 걸었어 🤙 지민 운동하는지 봐줘! 둘운완 깔고 코드 $code 넣으면 '
          '연결돼 → https://nod-try.web.app/i/$code';
      expect(findInviteCodeInText(message), code);
    });

    test('finds the code in the English message, a bare link or alone', () {
      expect(
        findInviteCodeInText(
          'Get DuoDone and enter code $code to connect → link',
        ),
        code,
      );
      expect(findInviteCodeInText('https://nod-try.web.app/i/$code'), code);
      expect(findInviteCodeInText(code), code);
      expect(findInviteCodeInText('  $code\n'), code);
    });

    test('a lower-cased link still yields the code, upper-cased', () {
      expect(findInviteCodeInText('https://nod-try.web.app/i/k7mp2qxr'), code);
    });

    test('a code glued to Hangul or punctuation is found', () {
      expect(findInviteCodeInText('코드$code넣어'), code);
      expect(findInviteCodeInText('($code)'), code);
      expect(findInviteCodeInText('코드: $code.'), code);
    });

    test('the link code wins over another 8-character token', () {
      expect(
        findInviteCodeInText('ZZZZ9999 → https://nod-try.web.app/i/$code'),
        code,
      );
    });

    test('ignores longer words, lowercase words, dates and empty text', () {
      expect(findInviteCodeInText('KAKAOTALKS are fun'), isNull);
      expect(findInviteCodeInText('ABCDEFGHIJ'), isNull);
      expect(findInviteCodeInText('password'), isNull);
      expect(findInviteCodeInText('오늘은 20261003 이에요'), isNull);
      expect(findInviteCodeInText(''), isNull);
      expect(findInviteCodeInText(null), isNull);
      expect(findInviteCodeInText('코드 없음'), isNull);
    });

    test('an all-digit token is skipped but a later real code is found', () {
      expect(findInviteCodeInText('20261003 / $code'), code);
    });
  });

  test('inviteLinkFor builds the Hosting landing link', () {
    expect(inviteLinkFor('K7MP2QXR'), 'https://nod-try.web.app/i/K7MP2QXR');
  });

  test('InviteCodeSource ids and fallback', () {
    expect(InviteCodeSource.fromId('clipboard'), InviteCodeSource.clipboard);
    expect(InviteCodeSource.fromId('link'), InviteCodeSource.link);
    expect(InviteCodeSource.fromId('manual'), InviteCodeSource.manual);
    expect(InviteCodeSource.fromId(null), InviteCodeSource.manual);
    expect(InviteCodeSource.fromId('nope'), InviteCodeSource.manual);
  });
}
