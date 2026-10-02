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

/// In-memory Storage that records the order of calls.
class _Storage implements ProofPhotoStorage {
  _Storage(this.calls);

  final List<String> calls;
  final objects = <String, Uint8List>{};
  bool uploadFails = false;
  bool deleteFails = false;

  @override
  Future<void> upload(
    String path,
    Uint8List jpegBytes, {
    Duration timeout = kProofUploadTimeout,
  }) async {
    calls.add('upload');
    // A cancel that came too late: the bytes landed, the call still failed.
    objects[path] = jpegBytes;
    if (uploadFails) throw const ProofUploadTimeoutException();
  }

  @override
  Future<Uint8List?> download(String path) async => objects[path];

  @override
  Future<void> delete(String path) async {
    calls.add('storage.delete');
    if (deleteFails) throw Exception('storage/retry-limit-exceeded');
    objects.remove(path);
  }
}

const _owner = 'owner-uid';
const _manager = 'manager-uid';

Map<String, dynamic> _planDoc({
  String state = 'active',
  List<Timestamp> completed = const [],
}) {
  final now = DateTime.now();
  return {
    'userId': _owner,
    'managerId': _manager,
    'state': state,
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
    'completedDates': completed,
    'verifiedDates': <Timestamp>[],
  };
}

void main() {
  late FakeFirebaseFirestore db;
  late List<String> calls;
  late _Storage storage;

  RealRecordRepository repoAs(String uid) => RealRecordRepository(
    firestore: db,
    auth: _FakeAuth(uid),
    proofStorage: storage,
  );

  Future<Map<String, dynamic>> plan() async =>
      (await db.collection('plans').doc('plan-1').get()).data()!;

  Future<Map<String, dynamic>> action(String id) async =>
      (await db.collection('actions').doc(id).get()).data()!;

  final photo = ProofPhotoUpload(
    bytes: Uint8List.fromList(List.generate(64, (i) => i)),
    source: ProofSource.camera,
    takenAt: DateTime.now(),
  );

  setUp(() async {
    db = FakeFirebaseFirestore();
    calls = [];
    storage = _Storage(calls);
    await db.collection('plans').doc('plan-1').set(_planDoc());
  });

  group('a 기록-tab 인정 of today\'s record', () {
    test('is the same 인정 as the Now tab: emoji, note and one cheer', () async {
      final result = await repoAs(_owner).reportCompletion('plan-1');

      await repoAs(
        _manager,
      ).verifyHistoryItem(result.actionId!, reaction: '🔥', message: '멋지다');

      final planData = await plan();
      // The owner's card shows today's emoji and note…
      expect(planData['lastCheerType'], '🔥');
      expect(planData['lastComment'], '멋지다');
      expect(planData['lastCheerAt'], isA<Timestamp>());
      expect(planData['lastUpdatedBy'], _manager);
      // …and the cheers doc carries the push with them (one 인정, one push).
      final cheers = await db.collection('cheers').get();
      expect(cheers.docs, hasLength(1));
      final cheer = cheers.docs.single.data();
      expect(cheer['fromUserId'], _manager);
      expect(cheer['toUserId'], _owner);
      expect(cheer['planId'], 'plan-1');
      expect(cheer['reactionType'], '🔥');
      expect(cheer['message'], '멋지다');
    });

    test('a past day\'s 인정 leaves today\'s card state alone', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await db.collection('actions').doc('old').set({
        'userId': _owner,
        'planId': 'plan-1',
        'type': 'done',
        'date': Timestamp.fromDate(yesterday),
        'title': '헬스장 가기',
      });

      await repoAs(_manager).verifyHistoryItem('old', reaction: '👏');

      final planData = await plan();
      expect(planData.containsKey('lastCheerType'), isFalse);
      expect(planData.containsKey('lastCheerAt'), isFalse);
      expect((planData['verifiedDates'] as List), hasLength(1));
      expect((await db.collection('cheers').get()).docs, isEmpty);
      expect((await action('old'))['reaction'], '👏');
    });
  });

  group('cheerPartner', () {
    test('writes the cheer and the 인정 together, once', () async {
      final result = await repoAs(_owner).reportCompletion('plan-1');

      await repoAs(_manager).cheerPartner('plan-1', '❤️', message: '최고');

      expect((await db.collection('cheers').get()).docs, hasLength(1));
      expect((await action(result.actionId!))['verifiedBy'], _manager);
      expect((await plan())['lastComment'], '최고');
    });
  });

  group('deleteProofPhoto', () {
    test('clears the references before deleting the object', () async {
      final result = await repoAs(
        _owner,
      ).reportCompletion('plan-1', photo: photo);
      calls.clear();

      await repoAs(_owner).deleteProofPhoto(result.photoPath!);

      expect(calls, ['storage.delete']);
      expect(
        (await action(result.actionId!)).containsKey('proofPhotoPath'),
        isFalse,
      );
      expect((await plan()).containsKey('lastProofPhotoPath'), isFalse);
    });

    test('a failed Storage delete leaves no broken reference behind', () async {
      final result = await repoAs(
        _owner,
      ).reportCompletion('plan-1', photo: photo);
      storage.deleteFails = true;

      // Not thrown: the photo is already gone from both feeds.
      await repoAs(_owner).deleteProofPhoto(result.photoPath!);

      expect(
        (await action(result.actionId!)).containsKey('proofPhotoPath'),
        isFalse,
      );
      expect((await plan()).containsKey('lastProofPhotoPath'), isFalse);
    });
  });

  group('reportCompletion', () {
    test('a failed upload deletes whatever landed, best-effort', () async {
      storage.uploadFails = true;

      final result = await repoAs(
        _owner,
      ).reportCompletion('plan-1', photo: photo);
      await Future<void>.delayed(Duration.zero);

      expect(result.photoFailed, isTrue);
      expect(calls, ['upload', 'storage.delete']);
      expect(storage.objects, isEmpty);
      expect(
        (await action(result.actionId!)).containsKey('proofPhotoPath'),
        isFalse,
      );
    });

    test('an acknowledged commit is not queued', () async {
      final result = await repoAs(_owner).reportCompletion('plan-1');
      expect(result.queued, isFalse);
    });
  });

  group('approvePlan', () {
    test('a pending plan with logged days keeps its period', () async {
      final start = DateTime.now().subtract(const Duration(days: 3));
      await db
          .collection('plans')
          .doc('plan-1')
          .set(
            _planDoc(
              state: 'pending_approval',
              completed: [
                Timestamp.fromDate(start.add(const Duration(hours: 20))),
              ],
            ),
          );
      final before = (await plan())['startDate'] as Timestamp;

      await repoAs(_manager).approvePlan('plan-1');

      final planData = await plan();
      expect(planData['state'], 'active');
      expect(planData['startDate'], before);
    });
  });

  group('updatePlanItems', () {
    test('writes only the items, stamped by me', () async {
      // The partner's 인정 lands while my reminder editor is open.
      await db.collection('plans').doc('plan-1').update({
        'verifiedDates': [Timestamp.now()],
        'lastUpdatedBy': _manager,
      });

      await repoAs(_owner).updatePlanItems('plan-1', [
        PlanItem(
          title: '헬스장 가기',
          days: const [1, 2, 3, 4, 5, 6, 7],
          count: 7,
          notificationTime: NotificationTime.custom(22, 0),
        ),
      ]);

      final planData = await plan();
      expect(planData['lastUpdatedBy'], _owner);
      expect((planData['verifiedDates'] as List), hasLength(1));
      final saved = Plan.fromMap(planData, 'plan-1');
      expect(saved.items.single.notificationTime?.hour, 22);
    });
  });
}
