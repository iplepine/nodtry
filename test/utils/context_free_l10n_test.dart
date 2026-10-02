import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/utils/context_free_l10n.dart';

void main() {
  tearDown(() => setContextFreeLocaleCode(null));

  test('the Settings language wins over the device language', () {
    setContextFreeLocaleCode('ko');
    expect(contextFreeLanguageCode(), 'ko');
    expect(contextFreeL10n().notifReminderBody, '인증 한 번이면 오늘 기록 끝이에요 📸');

    setContextFreeLocaleCode('en');
    expect(contextFreeLanguageCode(), 'en');
    expect(
      contextFreeL10n().notifReminderBody,
      'One check-in and today is logged 📸',
    );
  });

  test('without a Settings choice it follows the device', () {
    setContextFreeLocaleCode(null);
    final device = PlatformDispatcher.instance.locale.languageCode;
    expect(contextFreeLanguageCode(), device.startsWith('ko') ? 'ko' : 'en');
  });

  test('unsupported languages fall back to English', () {
    setContextFreeLocaleCode('ja');
    expect(contextFreeLanguageCode(), 'en');
    expect(contextFreeL10n().notifFallbackTitle, 'DuoDone');
  });

  test('notification channel copy is localized and brand-consistent', () {
    setContextFreeLocaleCode('ko');
    final ko = contextFreeL10n();
    expect(ko.notifFallbackTitle, '둘운완');
    expect(ko.notifChannelRemindersName, isNotEmpty);
    expect(ko.notifChannelGeneralName, isNot(contains('메이트')));

    setContextFreeLocaleCode('en');
    final en = contextFreeL10n();
    expect(en.notifChannelGeneralDesc, isNot(contains('accountability')));
  });

  test('a history record without a title gets the neutral fallback', () {
    final map = <String, dynamic>{'type': 'done', 'userId': 'me'};

    setContextFreeLocaleCode('ko');
    expect(HistoryItem.fromMap(map, 'a').title, '약속');

    setContextFreeLocaleCode('en');
    expect(HistoryItem.fromMap(map, 'b').title, 'Promise');
  });
}
