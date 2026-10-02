// Font loading for the store screenshot generator (tool/ only).
//
// `flutter test` renders with the Ahem-like FlutterTest font and no system
// fallback, so every glyph the screenshots show has to come from a font we
// load by hand:
//
// - Korean/Latin text: the app's `Pretendard` family. The committed
//   assets/fonts/Pretendard-*.otf files are not fonts (they are saved HTML
//   pages), so we load macOS's Apple SD Gothic Neo instead — the font iOS
//   itself falls back to when Pretendard is missing — under the family name
//   `Pretendard`, so the app's theme picks it up unchanged. Each weight is
//   pulled out of the .ttc collection as its own sfnt, because FontLoader only
//   reads the first face of a collection.
// - Emoji: Apple Color Emoji, registered as [kEmojiFontFamily] and added as a
//   fallback family (see [withScreenshotFontFallback]).
// - Material icons from the Flutter SDK cache.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kEmojiFontFamily = 'ScreenshotEmoji';

/// The app's font family name (lib/theme/app_theme.dart).
const kAppFontFamily = 'Pretendard';

const _sdGothicPath = '/System/Library/Fonts/AppleSDGothicNeo.ttc';
const _emojiPath = '/System/Library/Fonts/Apple Color Emoji.ttc';

/// What [loadScreenshotFonts] managed to load, for the run log.
class ScreenshotFontReport {
  ScreenshotFontReport({
    required this.textSource,
    required this.weights,
    required this.emoji,
    required this.materialIcons,
  });

  final String textSource;
  final List<int> weights;
  final bool emoji;
  final bool materialIcons;

  @override
  String toString() =>
      'text=$textSource weights=$weights emoji=$emoji '
      'materialIcons=$materialIcons';
}

/// Loads the fonts the screenshots need. Throws when no Korean-capable font
/// is available, because the output would otherwise be boxes.
Future<ScreenshotFontReport> loadScreenshotFonts() async {
  final report = await _loadTextFonts();
  final emoji = await _loadEmojiFont();
  final icons = await _loadMaterialIcons();
  return ScreenshotFontReport(
    textSource: report.$1,
    weights: report.$2,
    emoji: emoji,
    materialIcons: icons,
  );
}

Future<(String, List<int>)> _loadTextFonts() async {
  // A real Pretendard (if the asset is ever fixed) wins.
  final pretendard = [
    'assets/fonts/Pretendard-Regular.otf',
    'assets/fonts/Pretendard-Medium.otf',
    'assets/fonts/Pretendard-Bold.otf',
  ].map(File.new).where(_isFontFile).toList();
  if (pretendard.length == 3) {
    final loader = FontLoader(kAppFontFamily);
    for (final file in pretendard) {
      loader.addFont(_bytesOf(file));
    }
    await loader.load();
    return ('Pretendard assets', const [400, 500, 700]);
  }

  final collection = File(_sdGothicPath);
  if (!collection.existsSync()) {
    throw StateError(
      'No Korean font: the Pretendard assets are not font files and '
      '$_sdGothicPath is missing. Run the generator on macOS.',
    );
  }
  final faces = splitFontCollection(collection.readAsBytesSync());
  // One face per weight class; Apple SD Gothic Neo ships 100..900.
  final byWeight = <int, Uint8List>{};
  for (final face in faces) {
    final weight = readWeightClass(face);
    if (weight == null) continue;
    byWeight.putIfAbsent(weight, () => face);
  }
  const wanted = [400, 500, 600, 700, 800, 900];
  final loader = FontLoader(kAppFontFamily);
  final loaded = <int>[];
  for (final weight in wanted) {
    final face = byWeight[weight];
    if (face == null) continue;
    loader.addFont(Future.value(ByteData.sublistView(face)));
    loaded.add(weight);
  }
  if (loaded.isEmpty) {
    throw StateError('Could not read any face from $_sdGothicPath');
  }
  await loader.load();
  return ('Apple SD Gothic Neo', loaded);
}

Future<bool> _loadEmojiFont() async {
  final file = File(_emojiPath);
  if (!file.existsSync()) return false;
  final bytes = file.readAsBytesSync();
  final faces = _isCollection(bytes) ? splitFontCollection(bytes) : [bytes];
  final loader = FontLoader(kEmojiFontFamily)
    ..addFont(Future.value(ByteData.sublistView(faces.first)));
  await loader.load();
  return true;
}

Future<bool> _loadMaterialIcons() async {
  final file = File(
    '${_flutterRoot()}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) return false;
  final loader = FontLoader('MaterialIcons')..addFont(_bytesOf(file));
  await loader.load();
  return true;
}

Future<ByteData> _bytesOf(File file) async =>
    ByteData.sublistView(await file.readAsBytes());

bool _isFontFile(File file) {
  if (!file.existsSync()) return false;
  final bytes = file.readAsBytesSync();
  if (bytes.length < 4) return false;
  final signature = String.fromCharCodes(bytes.take(4));
  return signature == 'OTTO' ||
      signature == 'ttcf' ||
      signature == 'true' ||
      (bytes[0] == 0 && bytes[1] == 1 && bytes[2] == 0 && bytes[3] == 0);
}

bool _isCollection(Uint8List bytes) =>
    bytes.length > 12 && String.fromCharCodes(bytes.take(4)) == 'ttcf';

String _flutterRoot() {
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.parent.path != dir.path) {
    final materialFont = File(
      '${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (materialFont.existsSync()) return dir.path;
    dir = dir.parent;
  }
  final fallback = Platform.environment['FLUTTER_ROOT'];
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return dir.path;
}

/// Splits a TrueType/OpenType collection (.ttc) into standalone sfnt fonts.
///
/// Each face keeps its own table directory; tables shared between faces are
/// copied into every face that lists them. Table checksums stay valid because
/// the table bytes are unchanged (head.checkSumAdjustment is not recomputed,
/// which font engines don't verify).
List<Uint8List> splitFontCollection(Uint8List ttc) {
  final data = ByteData.sublistView(ttc);
  if (!_isCollection(ttc)) return [ttc];
  final numFonts = data.getUint32(8);
  final faces = <Uint8List>[];
  for (var i = 0; i < numFonts; i++) {
    final offset = data.getUint32(12 + i * 4);
    faces.add(_extractFace(ttc, data, offset));
  }
  return faces;
}

Uint8List _extractFace(Uint8List ttc, ByteData data, int faceOffset) {
  final sfntVersion = data.getUint32(faceOffset);
  final numTables = data.getUint16(faceOffset + 4);
  final records = <({int tag, int checksum, int offset, int length})>[];
  for (var t = 0; t < numTables; t++) {
    final r = faceOffset + 12 + t * 16;
    records.add((
      tag: data.getUint32(r),
      checksum: data.getUint32(r + 4),
      offset: data.getUint32(r + 8),
      length: data.getUint32(r + 12),
    ));
  }

  final headerSize = 12 + numTables * 16;
  var total = headerSize;
  for (final record in records) {
    total += (record.length + 3) & ~3;
  }
  final out = Uint8List(total);
  final view = ByteData.sublistView(out);

  var entrySelector = 0;
  while ((1 << (entrySelector + 1)) <= numTables) {
    entrySelector++;
  }
  final searchRange = (1 << entrySelector) * 16;
  view
    ..setUint32(0, sfntVersion)
    ..setUint16(4, numTables)
    ..setUint16(6, searchRange)
    ..setUint16(8, entrySelector)
    ..setUint16(10, numTables * 16 - searchRange);

  var cursor = headerSize;
  for (var t = 0; t < records.length; t++) {
    final record = records[t];
    final r = 12 + t * 16;
    view
      ..setUint32(r, record.tag)
      ..setUint32(r + 4, record.checksum)
      ..setUint32(r + 8, cursor)
      ..setUint32(r + 12, record.length);
    out.setRange(cursor, cursor + record.length, ttc, record.offset);
    cursor += (record.length + 3) & ~3;
  }
  return out;
}

/// `OS/2.usWeightClass` of a standalone sfnt, or null without an OS/2 table.
int? readWeightClass(Uint8List font) {
  final data = ByteData.sublistView(font);
  final numTables = data.getUint16(4);
  const os2 = 0x4F532F32; // 'OS/2'
  for (var t = 0; t < numTables; t++) {
    final r = 12 + t * 16;
    if (data.getUint32(r) == os2) {
      final offset = data.getUint32(r + 8);
      return data.getUint16(offset + 4);
    }
  }
  return null;
}

/// [theme] with the emoji font as a fallback on every text style, so emoji in
/// app copy (🏃, ❤️, 🤙 …) render instead of boxes. Button themes that set
/// their own text style (it replaces the inherited one) get it too.
ThemeData withScreenshotFontFallback(ThemeData theme) {
  const fallback = [kEmojiFontFamily];
  ButtonStyle? patch(ButtonStyle? style) {
    final textStyle = style?.textStyle;
    if (style == null || textStyle == null) return style;
    return style.copyWith(
      textStyle: WidgetStateProperty.resolveWith(
        (states) =>
            textStyle.resolve(states)?.copyWith(fontFamilyFallback: fallback),
      ),
    );
  }

  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: fallback),
    primaryTextTheme: theme.primaryTextTheme.apply(
      fontFamilyFallback: fallback,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: patch(theme.elevatedButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: patch(theme.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: patch(theme.textButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: patch(theme.filledButtonTheme.style),
    ),
  );
}
