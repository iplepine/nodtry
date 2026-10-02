import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the 둘운완 copy rules (docs/product/PIVOT_DUOUNWAN_SPEC.md §3) on
/// the ARB files themselves, so a reworded string can't quietly bring back the
/// old brand, the retired "실천 메이트" role, or a `{name}님` placeholder.
Map<String, String> _messages(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in raw.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

void main() {
  final ko = _messages('lib/l10n/app_ko.arb');
  final en = _messages('lib/l10n/app_en.arb');

  test('ko and en define the same keys', () {
    expect(ko.keys.toSet().difference(en.keys.toSet()), isEmpty);
    expect(en.keys.toSet().difference(ko.keys.toSet()), isEmpty);
  });

  test('the app is called 둘운완 / DuoDone', () {
    expect(ko['appTitle'], '둘운완');
    expect(en['appTitle'], 'DuoDone');
    expect(ko['splashTagline'], '둘이 보면, 진짜 하게 돼요.');
    expect(ko['tabNow'], '지금');
    expect(ko['tabHistory'], '기록');
    expect(ko['tabUs'], '우리');
    expect(en['tabUs'], 'Us');
  });

  // The one-time rename notice for existing users (spec §5) has to say what
  // the app used to be called. It is the only string allowed to.
  const renameNoticeKey = 'pivotNoticeTitle';

  test('retired brand and role names are gone', () {
    final retiredKo = RegExp(r'실천 메이트|메이트|공부|스터디|파일럿|그래,\s?해봐');
    final retiredBoth = RegExp(r'Nod&Try|Nodtry');
    final retiredEn = RegExp(r'[Aa]ccountability partner|\bstudy\b|\bpilot\b');

    final offenders = <String>[
      for (final MapEntry(:key, :value) in ko.entries)
        if (key != renameNoticeKey &&
            (retiredKo.hasMatch(value) || retiredBoth.hasMatch(value)))
          'ko $key: $value',
      for (final MapEntry(:key, :value) in en.entries)
        if (key != renameNoticeKey &&
            (retiredEn.hasMatch(value) || retiredBoth.hasMatch(value)))
          'en $key: $value',
    ];
    expect(offenders, isEmpty);
  });

  test('the rename notice names the old app and the new one', () {
    // Quoted, so the old name doesn't read as a sentence ("그래, 해봐가 …").
    expect(ko[renameNoticeKey], "'그래,해봐'가 둘운완이 됐어요");
    expect(en[renameNoticeKey], 'Nod&Try is now DuoDone');
    expect(ko['pivotNoticeBody'], '약속, 기록, 짝꿍 연결은 그대로예요.');
    expect(en[renameNoticeKey], contains('DuoDone'));
  });

  test('no Korean string addresses a placeholder with 님', () {
    final offenders = [
      for (final MapEntry(:key, :value) in ko.entries)
        if (RegExp(r'\}님').hasMatch(value)) '$key: $value',
    ];
    expect(offenders, isEmpty);
  });

  test(
    'a name placeholder is never followed by a batchim-dependent particle',
    () {
      // {name}이/가/을/를/은/는/과/와/랑/이랑 depends on the name's last sound;
      // pass withJosa(name, '…') from the call site instead.
      final unsafe = RegExp(
        r'\{name\}(이랑|랑|이|가|을|를|은|는|과|와|아|야|으로|로)(?![가-힣])',
      );
      final offenders = [
        for (final MapEntry(:key, :value) in ko.entries)
          if (unsafe.hasMatch(value)) '$key: $value',
      ];
      expect(offenders, isEmpty);
    },
  );
}
