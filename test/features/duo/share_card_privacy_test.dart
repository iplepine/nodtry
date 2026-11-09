// The share card must not outlive its share, and a partner's withdrawn
// consent must never come from a stale offline copy.
// ignore_for_file: subtype_of_sealed_class

import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/presentation/duo_share_card.dart';
import 'package:nod_try/features/proof/data/share_card_temp_files.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/real_user_repository.dart';
import 'package:nod_try/repositories/user_repository.dart';
import 'package:share_plus/share_plus.dart';

class _Platform {
  _Platform(this.answer);

  final Future<ShareResult> Function(ShareParams params) answer;
  final List<bool> fileExistedWhileSharing = [];

  Future<ShareResult> share(ShareParams params) async {
    fileExistedWhileSharing.add(File(params.files!.single.path).existsSync());
    return answer(params);
  }
}

class _Users extends Fake implements UserRepository {
  _Users(this.answer);

  final Future<bool> Function(String uid) answer;

  @override
  Future<bool> fetchPartnerPhotoShareConsent(String uid) => answer(uid);
}

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'me';
}

class _FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();
}

/// Records the [GetOptions] of every `users/{uid}` get, then forwards to a
/// [FakeFirebaseFirestore].
class _SpyFirestore extends Fake implements FirebaseFirestore {
  _SpyFirestore(this.db);

  final FakeFirebaseFirestore db;
  final List<GetOptions?> gets = [];

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _SpyCollection(this, db.collection(path));
}

class _SpyCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _SpyCollection(this.spy, this.inner);

  final _SpyFirestore spy;
  final CollectionReference<Map<String, dynamic>> inner;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _SpyDoc(spy, inner.doc(path));
}

class _SpyDoc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _SpyDoc(this.spy, this.inner);

  final _SpyFirestore spy;
  final DocumentReference<Map<String, dynamic>> inner;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    spy.gets.add(options);
    return inner.get(options);
  }
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('share_card_privacy_test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  ShareCardTempFiles files() => ShareCardTempFiles(directory: () async => dir);
  File card() => File('${dir.path}/${ShareCardTempFiles.cardFileName}');

  group('the card PNG', () {
    test('exists while the share sheet is up, gone once it returns', () async {
      final platform = _Platform(
        (_) async =>
            const ShareResult('com.kakao.talk', ShareResultStatus.success),
      );
      final sharer = SharePlusShareCardSharer(
        files: files(),
        share: platform.share,
      );

      final result = await sharer.sharePng(
        Uint8List.fromList([1, 2, 3]),
        text: 'hi',
      );

      expect(platform.fileExistedWhileSharing, [true]);
      expect(result.shared, isTrue);
      expect(result.target, 'kakao');
      expect(card().existsSync(), isFalse);
    });

    test('is deleted when the share is dismissed', () async {
      final sharer = SharePlusShareCardSharer(
        files: files(),
        share: _Platform(
          (_) async => const ShareResult('', ShareResultStatus.dismissed),
        ).share,
      );

      final result = await sharer.sharePng(Uint8List.fromList([1]), text: '');

      expect(result.shared, isFalse);
      expect(card().existsSync(), isFalse);
    });

    test('is deleted when the share throws', () async {
      final sharer = SharePlusShareCardSharer(
        files: files(),
        share: _Platform((_) async => throw Exception('x')).share,
      );

      await expectLater(
        sharer.sharePng(Uint8List.fromList([1]), text: ''),
        throwsException,
      );
      expect(card().existsSync(), isFalse);
    });

    test('clear() also removes share_plus\' Android copy', () async {
      await card().writeAsBytes([1]);
      final copy = File(
        '${dir.path}/${ShareCardTempFiles.sharePlusFolderName}/'
        '${ShareCardTempFiles.cardFileName}',
      );
      await copy.create(recursive: true);
      final unrelated = File('${dir.path}/proof_photos/keep.jpg');
      await unrelated.create(recursive: true);

      await files().clear();

      expect(card().existsSync(), isFalse);
      expect(copy.parent.existsSync(), isFalse);
      expect(unrelated.existsSync(), isTrue, reason: 'only share files');
    });

    test('clear() without a directory or files never throws', () async {
      await ShareCardTempFiles(directory: () async => null).clear();
      await ShareCardTempFiles(
        directory: () async => throw Exception('no path_provider'),
      ).clear();
      await files().clear();
    });
  });

  group('shareCardPartnerConsentProvider', () {
    Future<bool> consent(Future<bool> Function(String) answer) {
      final container = ProviderContainer(
        overrides: [userRepositoryProvider.overrideWithValue(_Users(answer))],
      );
      addTearDown(container.dispose);
      return container.read(shareCardPartnerConsentProvider)('partner');
    }

    test('passes the server answer through', () async {
      expect(await consent((_) async => true), isTrue);
      expect(await consent((_) async => false), isFalse);
    });

    test('fails closed: offline / denied is "no"', () async {
      expect(
        await consent(
          (_) async => throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
          ),
        ),
        isFalse,
      );
    });
  });

  group('RealUserRepository.fetchPartnerPhotoShareConsent', () {
    late FakeFirebaseFirestore db;
    late _SpyFirestore spy;
    late RealUserRepository repository;

    setUp(() async {
      db = FakeFirebaseFirestore();
      spy = _SpyFirestore(db);
      repository = RealUserRepository(firestore: spy, auth: _FakeAuth());
      await db.collection('users').doc('yes').set({
        'allowPartnerPhotoInShareCard': true,
      });
      await db.collection('users').doc('no').set({
        'allowPartnerPhotoInShareCard': false,
      });
      await db.collection('users').doc('old').set({'name': '예전 빌드'});
    });

    test('reads the field, missing or absent profile is false', () async {
      expect(await repository.fetchPartnerPhotoShareConsent('yes'), isTrue);
      expect(await repository.fetchPartnerPhotoShareConsent('no'), isFalse);
      expect(await repository.fetchPartnerPhotoShareConsent('old'), isFalse);
      expect(await repository.fetchPartnerPhotoShareConsent('ghost'), isFalse);
    });

    test('always asks the server, never the offline cache', () async {
      await repository.fetchPartnerPhotoShareConsent('yes');
      expect(spy.gets.map((o) => o?.source), [Source.server]);
    });
  });
}
