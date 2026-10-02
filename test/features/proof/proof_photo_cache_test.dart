import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/proof/data/proof_photo_cache.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/connect_repository.dart';

class _SpyCache extends ProofPhotoCache {
  _SpyCache() : super(fetch: (_) async => null, directory: () async => null);

  int clears = 0;

  @override
  Future<void> clear() async {
    clears++;
  }
}

void main() {
  final bytes = Uint8List.fromList([1, 2, 3, 4]);
  const path = 'proofs/u1/plan-1/a1.jpg';

  test('fetches once, then serves from memory', () async {
    var fetches = 0;
    final cache = ProofPhotoCache(
      fetch: (_) async {
        fetches++;
        return bytes;
      },
      directory: () async => null,
    );

    expect(cache.peek(path), isNull);
    expect(await cache.load(path), bytes);
    expect(await cache.load(path), bytes);
    expect(cache.peek(path), bytes);
    expect(fetches, 1);
  });

  test('concurrent loads of one path share a single fetch', () async {
    var fetches = 0;
    final gate = Completer<Uint8List?>();
    final cache = ProofPhotoCache(
      fetch: (_) {
        fetches++;
        return gate.future;
      },
      directory: () async => null,
    );

    final a = cache.load(path);
    final b = cache.load(path);
    gate.complete(bytes);
    expect(await a, bytes);
    expect(await b, bytes);
    expect(fetches, 1);
  });

  test('a denied read surfaces as ProofPhotoUnavailableException', () async {
    final cache = ProofPhotoCache(
      fetch: (_) async => throw Exception('storage/unauthorized'),
      directory: () async => null,
    );
    await expectLater(
      cache.load(path),
      throwsA(isA<ProofPhotoUnavailableException>()),
    );

    final gone = ProofPhotoCache(
      fetch: (_) async => null,
      directory: () async => null,
    );
    await expectLater(
      gone.load(path),
      throwsA(isA<ProofPhotoUnavailableException>()),
    );
  });

  test('clear() forgets everything, also a download still in flight', () async {
    var fetches = 0;
    final gate = Completer<Uint8List?>();
    final cache = ProofPhotoCache(
      fetch: (_) {
        fetches++;
        return fetches == 1 ? gate.future : Future.value(bytes);
      },
      directory: () async => null,
    );

    final pending = cache.load(path);
    await cache.clear(); // e.g. the couple disconnected mid-download
    gate.complete(bytes);
    await pending;

    expect(cache.peek(path), isNull, reason: 'must not refill after clear');
    await cache.load(path);
    expect(fetches, 2);
  });

  test('keeps photos on disk and deletes them on clear()', () async {
    final dir = await Directory.systemTemp.createTemp('proof_cache_test');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final cacheDir = Directory('${dir.path}/proof_photos');
    var fetches = 0;
    ProofPhotoCache build() => ProofPhotoCache(
      fetch: (_) async {
        fetches++;
        return bytes;
      },
      directory: () async => cacheDir,
    );

    await build().load(path);
    final file = File('${cacheDir.path}/${proofCacheFileName(path)}');
    expect(await file.exists(), isTrue);
    expect(file.path, isNot(contains('u1')), reason: 'no ids in file names');

    // A fresh cache (app restart) reads the disk copy instead of fetching.
    final restarted = build();
    expect(await restarted.load(path), bytes);
    expect(fetches, 1);

    await restarted.clear();
    expect(await cacheDir.exists(), isFalse);
  });

  test('evict() drops one photo', () async {
    var fetches = 0;
    final cache = ProofPhotoCache(
      fetch: (_) async {
        fetches++;
        return bytes;
      },
      directory: () async => null,
    );
    await cache.load(path);
    await cache.evict(path);
    expect(cache.peek(path), isNull);
    await cache.load(path);
    expect(fetches, 2);
  });

  test('a directory lookup that never answers falls back to memory', () async {
    final cache = ProofPhotoCache(
      fetch: (_) async => bytes,
      directory: () => Completer<Directory?>().future,
    );
    expect(await cache.load(path), bytes);
  });

  group('proofPhotoCacheBinderProvider', () {
    late StreamController<ConnectionStatus> status;
    late _SpyCache cache;
    late ProviderContainer container;

    setUp(() {
      status = StreamController<ConnectionStatus>();
      cache = _SpyCache();
      container = ProviderContainer(
        overrides: [
          connectionStatusStreamProvider.overrideWith((ref) => status.stream),
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<User?>.empty(),
          ),
          proofPhotoCacheProvider.overrideWithValue(cache),
        ],
      );
      container.listen(proofPhotoCacheBinderProvider, (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await status.close();
    });

    Future<void> emit(ConnectionStatus value) async {
      status.add(value);
      await Future<void>.delayed(Duration.zero);
    }

    test('clears when the couple disconnects', () async {
      await emit(ConnectionStatus.active);
      expect(cache.clears, 0);

      await emit(ConnectionStatus.none);
      expect(cache.clears, 1);

      await emit(ConnectionStatus.none);
      expect(cache.clears, 1, reason: 'no repeat without a change');
    });

    test('clears when a run starts disconnected (left while the app was '
        'closed)', () async {
      await emit(ConnectionStatus.none);
      expect(cache.clears, 1);
    });
  });
}
