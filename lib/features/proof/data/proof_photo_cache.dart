import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/history_item.dart';
import '../../../providers/repository_provider.dart';
import '../../../repositories/connect_repository.dart';

/// Thrown by [ProofPhotoCache.load] when a photo can't be shown: the read was
/// denied (e.g. after disconnecting), the object is gone, or the network
/// failed.
class ProofPhotoUnavailableException implements Exception {
  const ProofPhotoUnavailableException(this.path, [this.cause]);

  final String path;
  final Object? cause;

  @override
  String toString() => 'ProofPhotoUnavailableException($path, $cause)';
}

/// Fetches proof photo bytes for a Storage path (`ref(path).getData()`).
typedef ProofPhotoFetcher = Future<Uint8List?> Function(String path);

/// Resolves the directory for the on-disk cache, or null to keep it in
/// memory only.
typedef ProofCacheDirectory = Future<Directory?> Function();

/// In-memory + on-disk cache of proof photos, keyed by Storage path.
///
/// Photos are loaded with `getData()` through the Storage rules — never via a
/// download URL — so the cache is what keeps the feed from refetching. It is
/// wiped when the couple disconnects or the account changes
/// ([proofPhotoCacheBinderProvider]), so an ex-partner's photos don't linger
/// on the device.
class ProofPhotoCache {
  ProofPhotoCache({
    required ProofPhotoFetcher fetch,
    ProofCacheDirectory? directory,
    this.maxMemoryEntries = 40,
  }) : _fetch = fetch,
       _directory = directory ?? defaultProofCacheDirectory;

  final ProofPhotoFetcher _fetch;
  final ProofCacheDirectory _directory;
  final int maxMemoryEntries;

  /// The directory is resolved once. A platform that never answers (widget
  /// tests have no path_provider) must not stall loading, so give up after a
  /// moment and keep the cache in memory only.
  Future<Directory?>? _resolvedDirectory;

  Future<Directory?> _cacheDirectory() {
    return _resolvedDirectory ??= Future<Directory?>.sync(_directory)
        .timeout(const Duration(seconds: 2))
        .then<Directory?>(
          (dir) => dir,
          onError: (Object e) {
            debugPrint('[ProofPhotoCache] no disk cache: $e');
            return null;
          },
        );
  }

  // Insertion-ordered: the first key is the least recently used.
  final LinkedHashMap<String, Uint8List> _memory = LinkedHashMap();
  final Map<String, Future<Uint8List>> _inFlight = {};

  /// Bumped by [clear] so loads that started before it don't refill the cache.
  int _generation = 0;

  /// The bytes for [path] if they are already in memory.
  Uint8List? peek(String path) {
    final bytes = _memory.remove(path);
    if (bytes != null) _memory[path] = bytes;
    return bytes;
  }

  /// The bytes for [path]: memory, then disk, then the network. Concurrent
  /// loads of one path share a single fetch. Throws
  /// [ProofPhotoUnavailableException] when the photo can't be loaded.
  Future<Uint8List> load(String path) {
    final cached = peek(path);
    if (cached != null) return SynchronousFuture(cached);
    final pending = _inFlight[path];
    if (pending != null) return pending;

    final generation = _generation;
    final future = _loadUncached(path, generation).whenComplete(() {
      _inFlight.remove(path);
    });
    _inFlight[path] = future;
    return future;
  }

  Future<Uint8List> _loadUncached(String path, int generation) async {
    final file = await _fileFor(path);
    if (file != null) {
      try {
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            if (generation == _generation) _remember(path, bytes);
            return bytes;
          }
        }
      } catch (e) {
        debugPrint('[ProofPhotoCache] disk read failed: $e');
      }
    }

    Uint8List? bytes;
    try {
      bytes = await _fetch(path);
    } catch (e) {
      throw ProofPhotoUnavailableException(path, e);
    }
    if (bytes == null || bytes.isEmpty) {
      throw ProofPhotoUnavailableException(path);
    }
    // Don't repopulate a cache that was cleared (disconnect) mid-download.
    if (generation != _generation) return bytes;

    _remember(path, bytes);
    if (file != null) {
      try {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      } catch (e) {
        debugPrint('[ProofPhotoCache] disk write failed: $e');
      }
    }
    return bytes;
  }

  void _remember(String path, Uint8List bytes) {
    _memory.remove(path);
    _memory[path] = bytes;
    while (_memory.length > maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  /// Forgets one photo (e.g. after its owner deleted it).
  Future<void> evict(String path) async {
    _memory.remove(path);
    _inFlight.remove(path);
    final file = await _fileFor(path);
    try {
      if (file != null && await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[ProofPhotoCache] evict failed: $e');
    }
  }

  /// Forgets every photo, in memory and on disk.
  Future<void> clear() async {
    _generation++;
    _memory.clear();
    _inFlight.clear();
    try {
      final dir = await _cacheDirectory();
      if (dir != null && await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[ProofPhotoCache] clear failed: $e');
    }
  }

  Future<File?> _fileFor(String path) async {
    try {
      final dir = await _cacheDirectory();
      if (dir == null) return null;
      return File('${dir.path}/${proofCacheFileName(path)}');
    } catch (e) {
      // No path_provider (tests) or no file system: memory only.
      return null;
    }
  }
}

/// Disk file name for a Storage path: a hash, so the uids and plan ids in the
/// path don't end up in file names.
@visibleForTesting
String proofCacheFileName(String path) {
  return '${sha1.convert(utf8.encode(path))}.jpg';
}

/// `<temporary directory>/proof_photos`; the OS may purge it, which is fine
/// for a cache.
Future<Directory?> defaultProofCacheDirectory() async {
  final base = await getTemporaryDirectory();
  return Directory('${base.path}/proof_photos');
}

/// The app-wide proof photo cache, reading through the record repository.
final proofPhotoCacheProvider = Provider<ProofPhotoCache>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return ProofPhotoCache(fetch: repository.downloadProofPhoto);
});

/// The action a proof photo belongs to (for its source badge when only the
/// plan's `lastProofPhotoPath` is at hand). Null when it can't be read.
final proofActionMetaProvider = FutureProvider.autoDispose
    .family<HistoryItem?, String>((ref, actionId) async {
      try {
        return await ref
            .watch(recordRepositoryProvider)
            .getHistoryItem(actionId);
      } catch (e) {
        debugPrint('[ProofPhoto] action lookup failed: $e');
        return null;
      }
    });

/// Watch once from the app root: clears [proofPhotoCacheProvider] when the
/// couple disconnects (from either side) or the signed-in account changes.
final proofPhotoCacheBinderProvider = Provider<void>((ref) {
  void clear(String reason) {
    debugPrint('[ProofPhotoCache] clearing ($reason)');
    unawaited(ref.read(proofPhotoCacheProvider).clear());
  }

  ref.listen<AsyncValue<ConnectionStatus>>(connectionStatusStreamProvider, (
    previous,
    next,
  ) {
    final was = previous?.value;
    final now = next.value;
    // Also on the first status of a run: a partner may have disconnected
    // while the app was closed, leaving their photos on disk.
    if (now != null && now != ConnectionStatus.active && was != now) {
      clear('not connected');
    }
  }, fireImmediately: true);

  ref.listen(authStateChangesProvider, (previous, next) {
    final was = previous?.value?.uid;
    final now = next.value?.uid;
    if (was != null && was != now) clear('account changed');
  });
});
