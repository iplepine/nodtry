import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The privacy policy lives in three files that must say the same thing:
/// the hosted page (`hosting/public/privacy/index.html`), its legacy copy
/// (`privacy-policy/index.html`) and the Markdown copy (`PRIVACY_POLICY.md`).
void main() {
  final hosted = File('hosting/public/privacy/index.html');
  final legacy = File('privacy-policy/index.html');
  final markdown = File('PRIVACY_POLICY.md');

  test('the two HTML copies are identical', () {
    expect(legacy.readAsStringSync(), hosted.readAsStringSync());
  });

  test('all copies carry the same effective date (ko and en)', () {
    for (final file in [hosted, markdown]) {
      final text = file.readAsStringSync();
      expect(text, contains('시행일: 2026년 11월 10일'), reason: file.path);
      expect(
        text,
        contains('Effective Date: November 10, 2026'),
        reason: file.path,
      );
    }
  });

  test('all copies disclose the consent-gated share card in ko and en', () {
    for (final file in [hosted, markdown]) {
      final text = file.readAsStringSync();
      // Proof photos are partner-only by default, not unconditionally.
      expect(text, contains('기본적으로 나와'), reason: file.path);
      expect(text, contains('by default, only you and'), reason: file.path);
      expect(text, isNot(contains('no sharing with other users.</li>')));
      // The opt-in share card, rendered on the partner's device.
      expect(text, contains('공유 카드(선택, 기본 꺼짐)'), reason: file.path);
      expect(
        text,
        contains('Share cards (optional, off by default)'),
        reason: file.path,
      );
      expect(text, contains('카드는 짝꿍의 기기 안에서 만들어져요'), reason: file.path);
      expect(
        text,
        contains("The card is created on your partner's device"),
        reason: file.path,
      );
      // The card's temporary file: deleted after the share, as the app does
      // (SharePlusShareCardSharer / ShareCardTempFiles).
      expect(text, contains('공유 창이 닫히면 지워져요'), reason: file.path);
      expect(
        text,
        contains('is deleted when the share sheet closes'),
        reason: file.path,
      );
      expect(text, isNot(contains('임시 폴더에 잠시 저장돼요')));
      // Invite reminders and widgets are enumerated.
      expect(text, contains('초대 리마인더'), reason: file.path);
      expect(text, contains('Invite reminders'), reason: file.path);
      expect(text, contains('잠금 화면 위젯'), reason: file.path);
      expect(text, contains('lock-screen widgets'), reason: file.path);
    }
  });

  test(
    'support, terms and Play listings never say "partner only" unqualified',
    () {
      final files = [
        'hosting/public/support/index.html',
        'support/index.html',
        'hosting/public/terms/index.html',
        'android/fastlane/metadata/android/ko-KR/full_description.txt',
        'android/fastlane/metadata/android/en-US/full_description.txt',
      ];
      const absolute = [
        '<p>나와 연결된 짝꿍 1명만 볼 수 있어요',
        'Only your one connected partner.',
        '콘텐츠는 연결된 짝꿍에게만 보여요',
        'Your content is visible only to your connected partner.',
        '· 인증샷은 연결된 짝꿍 1명만 볼 수 있어요.',
        '· Only your connected partner can see your proof photos.',
      ];
      for (final path in files) {
        final text = File(path).readAsStringSync();
        for (final claim in absolute) {
          expect(text, isNot(contains(claim)), reason: '$path: $claim');
        }
      }
      final support = File(
        'hosting/public/support/index.html',
      ).readAsStringSync();
      expect(support, contains('기본적으로 나와 연결된 짝꿍 1명만'));
      expect(support, contains('By default, only your one connected partner'));
      final terms = File('hosting/public/terms/index.html').readAsStringSync();
      expect(terms, contains('기본적으로 연결된 짝꿍에게만 보여요'));
      expect(terms, contains('By default, your content is visible only'));
    },
  );
}
