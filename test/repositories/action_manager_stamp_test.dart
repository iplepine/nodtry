// Every action the app creates carries `managerId` = the plan's manager, so
// the partner can list it under firestore.rules.next right away (the server
// stamps the ones older builds write). A stamp the rules refuse — the plan's
// manager changed since the app read it — must never cost the record.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/repositories/real_record_repository.dart';

import '../support/participant_query_spy.dart';

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

const _owner = 'owner-uid';
const _manager = 'manager-uid';

Map<String, dynamic> _planDoc({String? managerId = _manager}) {
  final now = DateTime.now();
  return {
    'userId': _owner,
    if (managerId != null) 'managerId': managerId,
    'state': 'active',
    'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'endDate': Timestamp.fromDate(now.add(const Duration(days: 20))),
    'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late ParticipantQuerySpy spy;

  RealRecordRepository repoAs(String uid) =>
      RealRecordRepository(firestore: spy, auth: _FakeAuth(uid));

  Future<List<Map<String, dynamic>>> actions() async => [
    for (final doc in (await db.collection('actions').get()).docs) doc.data(),
  ];

  setUp(() async {
    db = FakeFirebaseFirestore();
    spy = ParticipantQuerySpy(db);
  });

  group('actionManagerStampFor', () {
    test('is the plan\'s manager, or nothing', () {
      expect(actionManagerStampFor({'managerId': 'm'}), 'm');
      expect(actionManagerStampFor({'managerId': ''}), isNull);
      expect(actionManagerStampFor({'managerId': 3}), isNull);
      expect(actionManagerStampFor({}), isNull);
      expect(actionManagerStampFor(null), isNull);
    });
  });

  group('new actions carry the plan\'s manager', () {
    setUp(() => db.doc('plans/plan-1').set(_planDoc()));

    test('했어 (reportCompletion)', () async {
      final result = await repoAs(_owner).reportCompletion('plan-1');

      final done = (await db.doc('actions/${result.actionId}').get()).data()!;
      expect(done['managerId'], _manager);
      expect(done['type'], 'done');
    });

    test('skip, rest and reconcile', () async {
      final repo = repoAs(_owner);
      await repo.reportSkip('plan-1');
      await repo.reportRest('plan-1');
      await repo.reconcilePlan('plan-1', HistoryStatus.done);

      final written = await actions();
      expect(written.map((a) => a['type']).toSet(), {
        'skipped',
        'rested',
        'done',
      });
      expect(written.map((a) => a['managerId']).toSet(), {_manager});
    });

    test('rescue (the record stays the owner\'s)', () async {
      await repoAs(_manager).rescuePlan('plan-1');

      final rescued = (await actions()).single;
      expect(rescued['type'], 'rescued');
      expect(rescued['userId'], _owner);
      expect(rescued['managerId'], _manager);
      expect(rescued['rescuedBy'], _manager);
    });
  });

  test('a plan without a manager writes no managerId', () async {
    await db.doc('plans/plan-1').set(_planDoc(managerId: null));

    final repo = repoAs(_owner);
    await repo.reportCompletion('plan-1');
    await repo.reportSkip('plan-1');

    for (final action in await actions()) {
      expect(action.containsKey('managerId'), isFalse);
    }
  });

  group('a refused stamp still saves the record, unstamped', () {
    setUp(() async {
      await db.doc('plans/plan-1').set(_planDoc());
      spy.denyActionManagerStamp = true;
    });

    test('했어: same action id, plan points at it', () async {
      final result = await repoAs(_owner).reportCompletion('plan-1', note: '굿');

      expect(result.queued, isFalse);
      final done = (await db.doc('actions/${result.actionId}').get()).data()!;
      expect(done.containsKey('managerId'), isFalse);
      expect(done['note'], '굿');
      final plan = (await db.doc('plans/plan-1').get()).data()!;
      expect(plan['lastActionId'], result.actionId);
      expect(plan['completedDates'] as List, hasLength(1));
    });

    test('skip', () async {
      await repoAs(_owner).reportSkip('plan-1');

      final skipped = (await actions()).single;
      expect(skipped['type'], 'skipped');
      expect(skipped.containsKey('managerId'), isFalse);
    });
  });
}
