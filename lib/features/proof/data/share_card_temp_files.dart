import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'proof_photo_cache.dart';

/// The temporary files that can hold a proof photo outside [ProofPhotoCache]:
/// the share card PNG handed to the system share sheet
/// (`<temp>/duodone_share_card.png`, which may show my partner's photo on a
/// together card) and share_plus' own copy of it (Android copies shared
/// files into `<cache>/share_plus` and only empties it on the next share).
///
/// The card PNG is deleted as soon as the share sheet returns. Everything is
/// also wiped with the proof cache when the couple disconnects or the account
/// changes ([proofPhotoCacheBinderProvider]).
class ShareCardTempFiles {
  ShareCardTempFiles({ProofCacheDirectory? directory})
    : _directory = directory ?? _defaultDirectory;

  static const cardFileName = 'duodone_share_card.png';

  /// share_plus' Android share cache folder, under the same cache directory
  /// path_provider reports as temporary.
  static const sharePlusFolderName = 'share_plus';

  final ProofCacheDirectory _directory;

  static Future<Directory?> _defaultDirectory() async {
    return getTemporaryDirectory();
  }

  /// Writes [png] where the share sheet can read it.
  Future<File> writeCard(Uint8List png) async {
    final dir = await _directory();
    if (dir == null) throw StateError('share card: no temporary directory');
    final file = File('${dir.path}/$cardFileName');
    await file.writeAsBytes(png, flush: true);
    return file;
  }

  /// Deletes the card PNG. Best-effort; never throws.
  ///
  /// share_plus' Android copy is left alone here: the app the user picked
  /// may still be reading it when the share call returns.
  Future<void> deleteCard() async {
    try {
      final dir = await _directory();
      if (dir == null) return;
      final file = File('${dir.path}/$cardFileName');
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[ShareCardTempFiles] could not delete the card: $e');
    }
  }

  /// Deletes the card PNG and share_plus' copy. Best-effort; never throws.
  Future<void> clear() async {
    await deleteCard();
    try {
      final dir = await _directory();
      if (dir == null) return;
      final folder = Directory('${dir.path}/$sharePlusFolderName');
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (e) {
      debugPrint('[ShareCardTempFiles] could not clear the share cache: $e');
    }
  }
}

final shareCardTempFilesProvider = Provider<ShareCardTempFiles>(
  (ref) => ShareCardTempFiles(),
);
