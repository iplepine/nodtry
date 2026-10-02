import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/proof_photo.dart';
import 'package:nod_try/repositories/proof_photo_storage.dart';
import 'package:nod_try/repositories/real_record_repository.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(String uid) : currentUser = _FakeUser(uid);

  @override
  final User? currentUser;
}

/// In-memory Storage with switchable failure modes.
class _FakeStorage implements ProofPhotoStorage {
  final objects = <String, Uint8List>{};
  final deleted = <String>[];
  bool fail = false;
  bool hang = false;

  @override
  Future<void> upload(
    String path,
    Uint8List jpegBytes, {
    Duration timeout = kProofUploadTimeout,
  }) async {
    if (fail) throw Exception('storage/unauthorized');
    if (hang) {
      // Never finishes on its own: the repository's timeout must give up.
      await Future<void>.delayed(const Duration(days: 1)).timeout(timeout);
    }
    objects[path] = jpegBytes;
  }

  @override
  Future<Uint8List?> download(String path) async => objects[path];

  @override
  Future<void> delete(String path) async {
    deleted.add(path);
    objects.remove(path);
  }
}

const _owner = 'owner-uid';
const _manager = 'manager-uid';

Map<String, dynamic> _planDoc() {
  final now = DateTime.now();
  return {
    'userId': _owner,
    'managerId': _manager,
    'state': 'active',
    'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'endDate': Timestamp.fromDate(now.add(const Duration(days: 20))),
    'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'workoutType': 'gym',
    'items': [
      {
        'title': '헬스장 가기',
        'days': [1, 2, 3, 4, 5, 6, 7],
        'count': 7,
      },
    ],
    'completedDates': <Timestamp>[],
    'verifiedDates': <Timestamp>[],
  };
}

void main() {
  late FakeFirebaseFirestore db;
  late _FakeStorage storage;

  RealRecordRepository repoAs(
    String uid, {
    Duration timeout = kProofUploadTimeout,
  }) => RealRecordRepository(
    firestore: db,
    auth: _FakeAuth(uid),
    proofStorage: storage,
    proofUploadTimeout: timeout,
  );

  Future<Map<String, dynamic>> plan() async =>
      (await db.collection('plans').doc('plan-1').get()).data()!;

  Future<Map<String, dynamic>> action(String id) async =>
      (await db.collection('actions').doc(id).get()).data()!;

  final photo = ProofPhotoUpload(
    bytes: Uint8List.fromList(List.generate(64, (i) => i)),
    source: ProofSource.gallery,
    takenAt: DateTime(2026, 9, 28, 7, 15),
  );

  setUp(() async {
    db = FakeFirebaseFirestore();
    storage = _FakeStorage();
    await db.collection('plans').doc('plan-1').set(_planDoc());
  });

  group('reportCompletion with a proof photo', () {
    test('uploads under proofs/{uid}/{planId}/{actionId}.jpg and writes '
        'the path, never a URL, to the plan and the action', () async {
      final result = await repoAs(
        _owner,
      ).reportCompletion('plan-1', note: '하체', photo: photo);

      final actionId = result.actionId!;
      final expectedPath = 'proofs/$_owner/plan-1/$actionId.jpg';
      expect(result.photoPath, expectedPath);
      expect(result.hasPhoto, isTrue);
      expect(result.photoFailed, isFalse);
      expect(storage.objects.keys, [expectedPath]);
      expect(storage.objects[expectedPath], photo.bytes);

      final planData = await plan();
      expect(planData['lastActionId'], actionId);
      expect(planData['lastProofPhotoPath'], expectedPath);
      expect(planData['lastProofAt'], isA<Timestamp>());
      expect((planData['completedDates'] as List), hasLength(1));
      expect(planData['lastActionNote'], '하체');

      final done = await action(actionId);
      expect(done['type'], 'done');
      expect(done['proofPhotoPath'], expectedPath);
      expect(done['proofSource'], 'gallery');
      expect(
        (done['proofTakenAt'] as Timestamp).toDate(),
        DateTime(2026, 9, 28, 7, 15),
      );

      // No download URL anywhere: plans and actions are readable by any
      // signed-in user.
      for (final value in [...planData.values, ...done.values]) {
        if (value is String) expect(value, isNot(startsWith('http')));
      }

      final parsed = Plan.fromMap(planData, 'plan-1');
      expect(parsed.lastProofPhotoPath, expectedPath);
      expect(todayProofPhotoPathOf(parsed), expectedPath);
    });

    test('a camera photo without a capture time omits proofTakenAt', () async {
      final result = await repoAs(_owner).reportCompletion(
        'plan-1',
        photo: ProofPhotoUpload(
          bytes: Uint8List.fromList([1, 2, 3]),
          source: ProofSource.camera,
        ),
      );

      final done = await action(result.actionId!);
      expect(done['proofSource'], 'camera');
      expect(done.containsKey('proofTakenAt'), isFalse);
    });

    test(
      'a failed upload still saves the record, without photo fields',
      () async {
        storage.fail = true;

        final result = await repoAs(
          _owner,
        ).reportCompletion('plan-1', photo: photo);

        expect(result.actionId, isNotNull);
        expect(result.hasPhoto, isFalse);
        expect(result.photoFailed, isTrue);
        expect(result.attemptedSource, ProofSource.gallery);

        final planData = await plan();
        expect((planData['completedDates'] as List), hasLength(1));
        expect(planData['lastActionId'], result.actionId);
        expect(planData.containsKey('lastProofPhotoPath'), isFalse);
        expect(planData.containsKey('lastProofAt'), isFalse);

        final done = await action(result.actionId!);
        expect(done['type'], 'done');
        expect(done.containsKey('proofPhotoPath'), isFalse);
        expect(done.containsKey('proofSource'), isFalse);
      },
    );

    test(
      'a slow upload times out and the record is saved without it',
      () async {
        storage.hang = true;

        final result = await repoAs(
          _owner,
          timeout: const Duration(milliseconds: 20),
        ).reportCompletion('plan-1', photo: photo);

        expect(result.photoFailed, isTrue);
        expect(storage.objects, isEmpty);
        final planData = await plan();
        expect((planData['completedDates'] as List), hasLength(1));
        expect(planData.containsKey('lastProofPhotoPath'), isFalse);
      },
    );

    test(
      'without a photo nothing is uploaded and no proof field is written',
      () async {
        final result = await repoAs(_owner).reportCompletion('plan-1');

        expect(result.hasPhoto, isFalse);
        expect(result.photoFailed, isFalse);
        expect(storage.objects, isEmpty);
        final done = await action(result.actionId!);
        expect(done.containsKey('proofPhotoPath'), isFalse);
      },
    );
  });

  group('reactions', () {
    test(
      'cheerPartner stores the tapped emoji on today\'s done action',
      () async {
        final result = await repoAs(
          _owner,
        ).reportCompletion('plan-1', photo: photo);

        await repoAs(_manager).cheerPartner('plan-1', '💪');

        final done = await action(result.actionId!);
        expect(done['verifiedBy'], _manager);
        expect(done['reaction'], '💪');
        final planData = await plan();
        expect(planData['lastCheerType'], '💪');
        expect((planData['verifiedDates'] as List), hasLength(1));

        final cheers = await db.collection('cheers').get();
        expect(cheers.docs.single.data()['reactionType'], '💪');
      },
    );

    test('verifyHistoryItem stores the reaction with the 인정', () async {
      final result = await repoAs(_owner).reportCompletion('plan-1');

      await repoAs(
        _manager,
      ).verifyHistoryItem(result.actionId!, reaction: '👏');

      final done = await action(result.actionId!);
      expect(done['verifiedBy'], _manager);
      expect(done['reaction'], '👏');
      expect(done.containsKey('comment'), isFalse);
      expect((await plan())['lastUpdatedBy'], _manager);
    });

    test('getHistoryItem maps the proof fields of one action', () async {
      final result = await repoAs(
        _owner,
      ).reportCompletion('plan-1', photo: photo);

      final item = await repoAs(_manager).getHistoryItem(result.actionId!);

      expect(item!.proofPhotoPath, result.photoPath);
      expect(item.proofSourceType, ProofSource.gallery);
      expect(item.proofTakenAt, DateTime(2026, 9, 28, 7, 15));
      expect(await repoAs(_manager).getHistoryItem('missing'), isNull);
    });
  });

  group('deleteProofPhoto', () {
    test('removes the object and clears the proof fields', () async {
      final result = await repoAs(
        _owner,
      ).reportCompletion('plan-1', photo: photo);
      final path = result.photoPath!;

      await repoAs(_owner).deleteProofPhoto(path);

      expect(storage.deleted, [path]);
      expect(storage.objects, isEmpty);
      final done = await action(result.actionId!);
      expect(done['type'], 'done', reason: 'the record itself stays');
      expect(done.containsKey('proofPhotoPath'), isFalse);
      expect(done.containsKey('proofSource'), isFalse);
      expect(done.containsKey('proofTakenAt'), isFalse);
      final planData = await plan();
      expect(planData.containsKey('lastProofPhotoPath'), isFalse);
      expect(planData.containsKey('lastProofAt'), isFalse);
      expect(planData['lastActionId'], result.actionId);
    });

    test('leaves a newer photo on the plan alone', () async {
      final first = await repoAs(
        _owner,
      ).reportCompletion('plan-1', photo: photo);
      final second = await repoAs(
        _owner,
      ).reportCompletion('plan-1', photo: photo);

      await repoAs(_owner).deleteProofPhoto(first.photoPath!);

      expect((await plan())['lastProofPhotoPath'], second.photoPath);
      expect(
        (await action(second.actionId!))['proofPhotoPath'],
        second.photoPath,
      );
    });

    test('refuses a photo that is not the caller\'s', () async {
      final result = await repoAs(
        _owner,
      ).reportCompletion('plan-1', photo: photo);

      await expectLater(
        repoAs(_manager).deleteProofPhoto(result.photoPath!),
        throwsArgumentError,
      );
      expect(storage.deleted, isEmpty);
    });
  });
}
