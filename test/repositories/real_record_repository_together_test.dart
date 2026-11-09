import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/proof_photo.dart';
import 'package:nod_try/models/together_log.dart';
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

class _FakeStorage implements ProofPhotoStorage {
  final objects = <String, Uint8List>{};

  @override
  Future<void> upload(
    String path,
    Uint8List jpegBytes, {
    Duration timeout = kProofUploadTimeout,
  }) async {
    objects[path] = jpegBytes;
  }

  @override
  Future<Uint8List?> download(String path) async => objects[path];

  @override
  Future<void> delete(String path) async => objects.remove(path);
}

// Alice logs "같이 했어"; Bob (her partner) answers with 나도 했어.
const _alice = 'alice';
const _bob = 'bob';

Map<String, dynamic> _planDoc(String owner, String manager) {
  final now = DateTime.now();
  return {
    'userId': owner,
    'managerId': manager,
    'state': 'active',
    'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'endDate': Timestamp.fromDate(now.add(const Duration(days: 20))),
    'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'workoutType': 'gym',
    'items': [
      {
        'title': owner == _alice ? '헬스장 가기' : '같이 헬스',
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

  RealRecordRepository repoAs(String uid) => RealRecordRepository(
    firestore: db,
    auth: _FakeAuth(uid),
    proofStorage: storage,
  );

  Future<Map<String, dynamic>> doc(String path) async =>
      (await db.doc(path).get()).data()!;

  const tag = TogetherTag(partnerUid: _bob, partnerPlanId: 'planB');
  final photo = ProofPhotoUpload(
    bytes: Uint8List.fromList(List.generate(32, (i) => i)),
    source: ProofSource.camera,
    takenAt: DateTime(2026, 11, 10, 19, 5),
  );

  setUp(() async {
    db = FakeFirebaseFirestore();
    storage = _FakeStorage();
    await db.doc('plans/planA').set(_planDoc(_alice, _bob));
    await db.doc('plans/planB').set(_planDoc(_bob, _alice));
  });

  group('reportCompletion with 같이 했어', () {
    test('tags my action and marks my plan; nothing is written for the '
        'partner', () async {
      final result = await repoAs(
        _alice,
      ).reportCompletion('planA', photo: photo, together: tag);

      final action = await doc('actions/${result.actionId}');
      expect(action['type'], 'done');
      expect(action['togetherWithUid'], _bob);
      expect(action['togetherPartnerPlanId'], 'planB');
      expect(action['proofSource'], 'camera');
      expect(action['managerId'], _bob);

      final plan = Plan.fromMap(await doc('plans/planA'), 'planA');
      expect(plan.lastActionId, result.actionId);
      expect(plan.lastTogether?.actionId, result.actionId);
      expect(plan.lastTogether?.withUid, _bob);
      expect(plan.lastTogether?.planId, 'planB');

      // Consent: Bob's plan and records are untouched until he taps.
      final bobPlan = Plan.fromMap(await doc('plans/planB'), 'planB');
      expect(bobPlan.completedDates, isEmpty);
      final bobActions = await db
          .collection('actions')
          .where('userId', isEqualTo: _bob)
          .get();
      expect(bobActions.docs, isEmpty);
    });

    test('without the toggle nothing new is written', () async {
      final result = await repoAs(_alice).reportCompletion('planA');
      final action = await doc('actions/${result.actionId}');
      expect(action.containsKey('togetherWithUid'), isFalse);
      expect(action.containsKey('togetherPartnerPlanId'), isFalse);
      expect((await doc('plans/planA')).containsKey('lastTogether'), isFalse);
    });
  });

  group('confirmTogether (나도 했어)', () {
    Future<String> aliceLogs({ProofPhotoUpload? withPhoto}) async {
      final result = await repoAs(
        _alice,
      ).reportCompletion('planA', photo: withPhoto, together: tag);
      return result.actionId!;
    }

    test("logs Bob's own done, sharing Alice's photo by reference", () async {
      final sourceId = await aliceLogs(withPhoto: photo);
      final alicePath = proofPhotoPathFor(
        ownerUid: _alice,
        planId: 'planA',
        actionId: sourceId,
      );

      final result = await repoAs(
        _bob,
      ).confirmTogether('planB', sourceActionId: sourceId);
      expect(result.outcome, TogetherConfirmOutcome.logged);
      expect(result.photoPath, alicePath);

      final action = await doc('actions/${result.actionId}');
      expect(action['userId'], _bob);
      expect(action['planId'], 'planB');
      expect(action['type'], 'done');
      expect(action['managerId'], _alice);
      expect(action['proofPhotoPath'], alicePath);
      // The original source value — action values never change.
      expect(action['proofSource'], 'camera');
      expect(
        (action['proofTakenAt'] as Timestamp).toDate(),
        DateTime(2026, 11, 10, 19, 5),
      );
      expect(action['sharedProofFromUid'], _alice);
      expect(action['togetherActionId'], sourceId);
      // A confirmation never asks back.
      expect(action.containsKey('togetherWithUid'), isFalse);

      final plan = Plan.fromMap(await doc('plans/planB'), 'planB');
      expect(plan.lastActionId, result.actionId);
      expect(plan.completedDates, hasLength(1));
      // Bob's plan doesn't adopt Alice's photo as his own (share cards,
      // today's photo): it stays on the action only.
      expect(plan.lastProofPhotoPath, isNull);
      expect(todayProofPhotoPathOf(plan), isNull);
      // No new Storage object: the photo is shared, not copied.
      expect(storage.objects.keys, [alicePath]);
    });

    test('without a photo the record has none', () async {
      final sourceId = await aliceLogs();
      final result = await repoAs(
        _bob,
      ).confirmTogether('planB', sourceActionId: sourceId);
      expect(result.logged, isTrue);
      final action = await doc('actions/${result.actionId}');
      expect(action.containsKey('proofPhotoPath'), isFalse);
      expect(action.containsKey('proofSource'), isFalse);
      expect(action['sharedProofFromUid'], _alice);
    });

    test('a photo Alice deleted first is not shared', () async {
      final sourceId = await aliceLogs(withPhoto: photo);
      final path = proofPhotoPathFor(
        ownerUid: _alice,
        planId: 'planA',
        actionId: sourceId,
      );
      await repoAs(_alice).deleteProofPhoto(path);

      final result = await repoAs(
        _bob,
      ).confirmTogether('planB', sourceActionId: sourceId);
      expect(result.logged, isTrue);
      expect(result.photoPath, isNull);
      final action = await doc('actions/${result.actionId}');
      expect(action.containsKey('proofPhotoPath'), isFalse);
    });

    test('twice the same day writes once', () async {
      final sourceId = await aliceLogs();
      final first = await repoAs(
        _bob,
      ).confirmTogether('planB', sourceActionId: sourceId);
      final second = await repoAs(
        _bob,
      ).confirmTogether('planB', sourceActionId: sourceId);
      expect(first.logged, isTrue);
      expect(second.outcome, TogetherConfirmOutcome.alreadyLogged);
      final bobActions = await db
          .collection('actions')
          .where('userId', isEqualTo: _bob)
          .get();
      expect(bobActions.docs, hasLength(1));
    });

    test('writes nothing for a record that does not ask me about this '
        'plan', () async {
      final sourceId = await aliceLogs();
      // Not for this plan.
      await db.doc('plans/planB2').set(_planDoc(_bob, _alice));
      expect(
        (await repoAs(
          _bob,
        ).confirmTogether('planB2', sourceActionId: sourceId)).outcome,
        TogetherConfirmOutcome.unavailable,
      );
      // Not for me.
      expect(
        (await repoAs(
          'carol',
        ).confirmTogether('planB', sourceActionId: sourceId)).outcome,
        TogetherConfirmOutcome.unavailable,
      );
      // Gone.
      expect(
        (await repoAs(
          _bob,
        ).confirmTogether('planB', sourceActionId: 'nope')).outcome,
        TogetherConfirmOutcome.unavailable,
      );
      // A plain record (no toggle).
      final plain = await repoAs(_alice).reportCompletion('planA');
      expect(
        (await repoAs(
          _bob,
        ).confirmTogether('planB', sourceActionId: plain.actionId!)).outcome,
        TogetherConfirmOutcome.unavailable,
      );
      final bobActions = await db
          .collection('actions')
          .where('userId', isEqualTo: _bob)
          .get();
      expect(bobActions.docs, isEmpty);
    });

    test("only my own plan can take it", () async {
      final sourceId = await aliceLogs();
      // A plan id of Alice's own, as if Bob's app named it.
      await db.doc('actions/$sourceId').update({
        'togetherPartnerPlanId': 'planA',
      });
      expect(
        (await repoAs(
          _bob,
        ).confirmTogether('planA', sourceActionId: sourceId)).outcome,
        TogetherConfirmOutcome.unavailable,
      );
    });
  });

  group('isTogetherClaimFor', () {
    final now = DateTime(2026, 11, 11, 20);
    Map<String, dynamic> claim([Map<String, dynamic> extra = const {}]) => {
      'userId': _alice,
      'type': 'done',
      'date': Timestamp.fromDate(DateTime(2026, 11, 11, 19)),
      'togetherWithUid': _bob,
      'togetherPartnerPlanId': 'planB',
      ...extra,
    };
    bool check(Map<String, dynamic>? action) =>
        RealRecordRepository.isTogetherClaimFor(
          action,
          myUid: _bob,
          planId: 'planB',
          now: now,
        );

    test('accepts only a done record of today naming me and my plan', () {
      expect(check(claim()), isTrue);
      expect(check(null), isFalse);
      expect(check(claim({'type': 'skipped'})), isFalse);
      expect(check(claim({'userId': _bob})), isFalse);
      expect(check(claim({'togetherWithUid': 'carol'})), isFalse);
      expect(check(claim({'togetherPartnerPlanId': 'x'})), isFalse);
      expect(check(claim({'sharedProofFromUid': 'x'})), isFalse);
      expect(
        check(claim({'date': Timestamp.fromDate(DateTime(2026, 11, 10, 23))})),
        isFalse,
      );
    });
  });
}
