// Guards the bundled Pretendard subsets (assets/fonts/, built by
// tool/fonts/subset_pretendard.py):
// - they are real OpenType/CFF fonts (they used to be saved HTML pages),
// - they stay lightweight (the full ~1.6 MB files caused an Android ANR),
// - every Hangul syllable/jamo, ASCII and Latin-1 character in the ARB copy is
//   covered, so app text never mixes Pretendard with a fallback font,
// - emoji-capable code points and ZWJ/variation selectors are left out, so
//   "❤️" etc. still fall back to the color emoji font,
// - the theme applies the family app-wide without a fontFamilyFallback that
//   would override the system's per-glyph fallback.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/theme/app_theme.dart';
import 'package:nod_try/theme/app_theme_enum.dart';

const _weights = {'Regular': 400, 'Medium': 500, 'Bold': 700};

/// Upper bound per weight. The subsets are ~350 KB; anything near the full
/// font's size means the subset step was skipped.
const _maxBytes = 420 * 1024;

const _regenerateHint =
    'Re-run tool/fonts/subset_pretendard.py (see its header) so the subset '
    'includes the new characters.';

void main() {
  for (final weight in _weights.keys) {
    group('Pretendard-$weight.otf', () {
      final file = File('assets/fonts/Pretendard-$weight.otf');
      late Uint8List bytes;
      late Set<int> cmap;

      setUpAll(() {
        bytes = file.readAsBytesSync();
        cmap = readCmap(bytes);
      });

      test('is a CFF OpenType font within the size budget', () {
        expect(String.fromCharCodes(bytes.take(4)), 'OTTO');
        expect(bytes.length, lessThan(_maxBytes));
        expect(readWeightClass(bytes), _weights[weight]);
      });

      test('covers the KS X 1001 Hangul set and Latin basics', () {
        final syllables = cmap.where((c) => c >= 0xAC00 && c <= 0xD7A3);
        expect(syllables.length, greaterThanOrEqualTo(2350));
        for (final c in [for (var c = 0x20; c <= 0x7E; c++) c]) {
          expect(cmap.contains(c), isTrue, reason: 'U+${_hex(c)} missing');
        }
        for (final c in '가각간똘힝ㄱㅎㅏㅣ₩…·–—“”‘’→←'.runes) {
          expect(
            cmap.contains(c),
            isTrue,
            reason: '${String.fromCharCode(c)} missing',
          );
        }
      });

      test('covers every Hangul/Latin character in the ARB copy', () {
        final missing = <int>{};
        for (final c in _arbCodePoints()) {
          if (_mustBeInSubset(c) && !cmap.contains(c)) missing.add(c);
        }
        expect(
          missing.map(String.fromCharCode).join(),
          isEmpty,
          reason: _regenerateHint,
        );
      });

      test('leaves emoji and sequence controls to the fallback fonts', () {
        // ❤ ☀ ♥ ✅ ✨ ⭐ ‼ ™, ZWJ, VS16, keycap.
        for (final c in [
          0x2764, 0x2600, 0x2665, 0x2705, 0x2728, 0x2B50, 0x203C, 0x2122, //
          0x200D, 0xFE0F, 0x20E3,
        ]) {
          expect(cmap.contains(c), isFalse, reason: 'U+${_hex(c)} present');
        }
        expect(cmap.where((c) => c > 0xFFFF), isEmpty);
      });
    });
  }

  test('theme applies Pretendard app-wide with system per-glyph fallback', () {
    final themes = [
      for (final type in AppThemeType.values) AppTheme.themeOf(type),
      AppTheme.darkTheme,
    ];
    for (final theme in themes) {
      final styles = <TextStyle?>[
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.titleMedium,
        theme.textTheme.labelLarge,
        theme.textTheme.displayLarge,
        theme.primaryTextTheme.bodyMedium,
      ];
      for (final style in styles) {
        expect(style?.fontFamily, 'Pretendard');
        expect(style?.fontFamilyFallback, isNull);
      }
    }
    final button = AppTheme.themeOf(
      AppThemeType.smokyPlum,
    ).elevatedButtonTheme.style?.textStyle?.resolve({});
    expect(button?.fontFamily, 'Pretendard');
  });

  test('pubspec declares the three Pretendard weights', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- family: Pretendard'));
    for (final MapEntry(key: weight, value: wght) in _weights.entries) {
      expect(
        pubspec,
        matches(
          RegExp(
            'asset: assets/fonts/Pretendard-$weight\\.otf\\s+weight: $wght',
          ),
        ),
      );
    }
  });
}

String _hex(int c) => c.toRadixString(16).toUpperCase().padLeft(4, '0');

/// Characters that must render in Pretendard: Hangul syllables, modern
/// compatibility jamo, printable ASCII and Latin-1.
bool _mustBeInSubset(int c) =>
    (c >= 0xAC00 && c <= 0xD7A3) ||
    (c >= 0x3131 && c <= 0x3163) ||
    (c >= 0x20 && c <= 0x7E) ||
    (c >= 0xA1 && c <= 0xFF && c != 0xAD);

Set<int> _arbCodePoints() {
  final out = <int>{};
  for (final entity in Directory('lib/l10n').listSync()) {
    if (entity is! File || !entity.path.endsWith('.arb')) continue;
    final json = jsonDecode(entity.readAsStringSync()) as Map<String, dynamic>;
    for (final MapEntry(:key, :value) in json.entries) {
      if (key.startsWith('@') || value is! String) continue;
      out.addAll(value.runes.where((c) => c >= 0x20));
    }
  }
  return out;
}

int? _tableOffset(ByteData data, String tag) {
  final want = tag.codeUnits.fold<int>(0, (acc, c) => (acc << 8) | c);
  final numTables = data.getUint16(4);
  for (var t = 0; t < numTables; t++) {
    final r = 12 + t * 16;
    if (data.getUint32(r) == want) return data.getUint32(r + 8);
  }
  return null;
}

/// `OS/2.usWeightClass`.
int? readWeightClass(Uint8List font) {
  final data = ByteData.sublistView(font);
  final os2 = _tableOffset(data, 'OS/2');
  return os2 == null ? null : data.getUint16(os2 + 4);
}

/// Code points mapped by the font's Unicode BMP (format 4) cmap subtable.
Set<int> readCmap(Uint8List font) {
  final data = ByteData.sublistView(font);
  final cmap = _tableOffset(data, 'cmap');
  if (cmap == null) throw StateError('no cmap table');
  final numSubtables = data.getUint16(cmap + 2);
  for (var i = 0; i < numSubtables; i++) {
    final r = cmap + 4 + i * 8;
    final platform = data.getUint16(r);
    final encoding = data.getUint16(r + 2);
    final offset = cmap + data.getUint32(r + 4);
    final isUnicodeBmp =
        (platform == 3 && encoding == 1) || (platform == 0 && encoding == 3);
    if (!isUnicodeBmp || data.getUint16(offset) != 4) continue;
    return _readFormat4(data, offset);
  }
  throw StateError('no format 4 Unicode cmap');
}

Set<int> _readFormat4(ByteData data, int offset) {
  final segCount = data.getUint16(offset + 6) ~/ 2;
  final endCodes = offset + 14;
  final startCodes = endCodes + segCount * 2 + 2;
  final idDeltas = startCodes + segCount * 2;
  final idRangeOffsets = idDeltas + segCount * 2;
  final out = <int>{};
  for (var s = 0; s < segCount; s++) {
    final end = data.getUint16(endCodes + s * 2);
    final start = data.getUint16(startCodes + s * 2);
    final delta = data.getInt16(idDeltas + s * 2);
    final rangeOffsetPos = idRangeOffsets + s * 2;
    final rangeOffset = data.getUint16(rangeOffsetPos);
    for (var c = start; c <= end && c != 0xFFFF; c++) {
      int glyph;
      if (rangeOffset == 0) {
        glyph = (c + delta) & 0xFFFF;
      } else {
        final pos = rangeOffsetPos + rangeOffset + (c - start) * 2;
        final raw = data.getUint16(pos);
        glyph = raw == 0 ? 0 : (raw + delta) & 0xFFFF;
      }
      if (glyph != 0) out.add(c);
    }
  }
  return out;
}
