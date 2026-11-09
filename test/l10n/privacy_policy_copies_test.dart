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
      // Invite reminders and widgets are enumerated.
      expect(text, contains('초대 리마인더'), reason: file.path);
      expect(text, contains('Invite reminders'), reason: file.path);
      expect(text, contains('잠금 화면 위젯'), reason: file.path);
      expect(text, contains('lock-screen widgets'), reason: file.path);
    }
  });
}
