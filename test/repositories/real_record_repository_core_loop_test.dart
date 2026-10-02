import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/plan_model.dart';
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

const _owner = 'owner-uid';
const _manager = 'manager-uid';

Map<String, dynamic> _planDoc({
  String state = 'active',
  String? lastActionId,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final now = DateTime.now();
  return {
    'userId': _owner,
    'managerId': _manager,
    'state': state,
    'startDate': Timestamp.fromDate(
      startDate ?? now.subtract(const Duration(days: 3)),
    ),
    'endDate': Timestamp.fromDate(endDate ?? now.add(const Duration(days: 20))),
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
    if (lastActionId != null) 'lastActionId': lastActionId,
  };
}

/// An action as build ≥81 (or the server, within seconds) writes it: stamped
/// with the plan's manager, through which the manager may list it.
Map<String, dynamic> _action(
  String type,
  DateTime date, {
  bool stamped = true,
}) => {
  'userId': _owner,
  'planId': 'plan-1',
  if (stamped) 'managerId': _manager,
  'type': type,
  'date': Timestamp.fromDate(date),
  'title': '헬스장 가기',
};

DateTime _todayAt(int hour, [int minute = 0]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

void main() {
  late FakeFirebaseFirestore db;

  RealRecordRepository repoAs(String uid) =>
      RealRecordRepository(firestore: db, auth: _FakeAuth(uid));

  Future<Map<String, dynamic>> plan() async =>
      (await db.collection('plans').doc('plan-1').get()).data()!;

  Future<Map<String, dynamic>> action(String id) async =>
      (await db.collection('actions').doc(id).get()).data()!;

  setUp(() {
    db = FakeFirebaseFirestore();
  });

  group('reportCompletion', () {
    test('points plan.lastActionId at the new done action', () async {
      await db.collection('plans').doc('plan-1').set(_planDoc());

      await repoAs(_owner).reportCompletion('plan-1', note: '스쿼트 100개');

      final planData = await plan();
      final actionId = planData['lastActionId'] as String?;
      expect(actionId, isNotNull);
      expect((planData['completedDates'] as List), hasLength(1));
      expect(planData['lastActionNote'], '스쿼트 100개');

      final done = await action(actionId!);
      expect(done['type'], 'done');
      expect(done['planId'], 'plan-1');
      expect(done['userId'], _owner);
      expect(done['note'], '스쿼트 100개');
      expect(done['title'], '헬스장 가기');
    });
  });

  group('cheerPartner targets the right action', () {
    test('writes onto the action lastActionId points at', () async {
      // A skipped record created earlier the same day used to be picked by the
      // unfiltered limit(1) query.
      await db
          .collection('actions')
          .doc('skipped-today')
          .set(_action('skipped', _todayAt(0, 5)));
      await db
          .collection('actions')
          .doc('done-today')
          .set(_action('done', _todayAt(0, 10)));
      await db
          .collection('plans')
          .doc('plan-1')
          .set(_planDoc(lastActionId: 'done-today'));

      await repoAs(_manager).cheerPartner('plan-1', '❤️', message: '최고야');

      final done = await action('done-today');
      expect(done['verifiedBy'], _manager);
      expect(done['partnerMessage'], '최고야');
      expect((await action('skipped-today'))['verifiedBy'], isNull);

      final planData = await plan();
      expect(planData['lastUpdatedBy'], _manager);
      expect((planData['verifiedDates'] as List), hasLength(1));
    });

    test(
      'falls back to today\'s done action when there is no pointer',
      () async {
        // Plans written by older app versions have no lastActionId.
        await db
            .collection('actions')
            .doc('rested-today')
            .set(_action('rested', _todayAt(0, 1)));
        await db
            .collection('actions')
            .doc('done-today')
            .set(_action('done', _todayAt(0, 2)));
        await db.collection('plans').doc('plan-1').set(_planDoc());

        await repoAs(_manager).cheerPartner('plan-1', '🔥');

        expect((await action('done-today'))['verifiedBy'], _manager);
        expect((await action('rested-today'))['verifiedBy'], isNull);
      },
    );

    test(
      'ignores a pointer to an earlier day and uses today\'s done',
      () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await db
            .collection('actions')
            .doc('done-yesterday')
            .set(_action('done', yesterday));
        await db
            .collection('actions')
            .doc('done-today')
            .set(_action('done', _todayAt(0, 3)));
        await db
            .collection('plans')
            .doc('plan-1')
            .set(_planDoc(lastActionId: 'done-yesterday'));

        await repoAs(_manager).cheerPartner('plan-1', '💪');

        expect((await action('done-today'))['verifiedBy'], _manager);
        expect((await action('done-yesterday'))['verifiedBy'], isNull);
      },
    );

    test('a pointer to a deleted action falls back to the query', () async {
      await db
          .collection('actions')
          .doc('done-today')
          .set(_action('done', _todayAt(0, 3)));
      await db
          .collection('plans')
          .doc('plan-1')
          .set(_planDoc(lastActionId: 'deleted-action'));

      await repoAs(_manager).cheerPartner('plan-1', '❤️');

      expect((await action('done-today'))['verifiedBy'], _manager);
      final deleted = await db
          .collection('actions')
          .doc('deleted-action')
          .get();
      expect(deleted.exists, isFalse, reason: 'must not create the action');
    });

    test(
      'without lastActionId, an unstamped (legacy) record is out of reach',
      () async {
        // Written by build ≤80 and not stamped yet: the manager can't list
        // it (firestore.rules.next) until the server or the backfill stamps
        // it. The 인정 still lands on the plan.
        await db
            .collection('actions')
            .doc('done-today')
            .set(_action('done', _todayAt(0, 2), stamped: false));
        await db.collection('plans').doc('plan-1').set(_planDoc());

        await repoAs(_manager).cheerPartner('plan-1', '❤️');

        expect((await action('done-today'))['verifiedBy'], isNull);
        expect((await plan())['verifiedDates'] as List, hasLength(1));
      },
    );

    test('lastActionId reaches an unstamped record by id', () async {
      await db
          .collection('actions')
          .doc('done-today')
          .set(_action('done', _todayAt(0, 2), stamped: false));
      await db
          .collection('plans')
          .doc('plan-1')
          .set(_planDoc(lastActionId: 'done-today'));

      await repoAs(_manager).cheerPartner('plan-1', '❤️');

      expect((await action('done-today'))['verifiedBy'], _manager);
    });

    test('verifies no action when today has only a skip', () async {
      await db
          .collection('actions')
          .doc('skipped-today')
          .set(_action('skipped', _todayAt(0, 4)));
      await db.collection('plans').doc('plan-1').set(_planDoc());

      await repoAs(_manager).cheerPartner('plan-1', '👏');

      expect((await action('skipped-today'))['verifiedBy'], isNull);
    });
  });

  group('verifyPlan', () {
    test('verifies the lastActionId action and records the verifier', () async {
      await db
          .collection('actions')
          .doc('skipped-today')
          .set(_action('skipped', _todayAt(0, 1)));
      await db
          .collection('actions')
          .doc('done-today')
          .set(_action('done', _todayAt(0, 2)));
      await db
          .collection('plans')
          .doc('plan-1')
          .set(_planDoc(lastActionId: 'done-today'));

      await repoAs(_manager).verifyPlan('plan-1');

      expect((await action('done-today'))['verifiedBy'], _manager);
      expect((await action('skipped-today'))['verifiedBy'], isNull);
      final planData = await plan();
      expect(planData['lastUpdatedBy'], _manager);
      expect((planData['verifiedDates'] as List), hasLength(1));
    });

    test('falls back to today\'s done action by type', () async {
      await db
          .collection('actions')
          .doc('rested-today')
          .set(_action('rested', _todayAt(0, 1)));
      await db
          .collection('actions')
          .doc('done-today')
          .set(_action('done', _todayAt(0, 2)));
      await db.collection('plans').doc('plan-1').set(_planDoc());

      await repoAs(_manager).verifyPlan('plan-1');

      expect((await action('done-today'))['verifiedBy'], _manager);
      expect((await action('rested-today'))['verifiedBy'], isNull);
    });
  });

  group('verifyHistoryItem', () {
    test('marks the plan as last updated by the verifier', () async {
      await db
          .collection('actions')
          .doc('done-today')
          .set(_action('done', _todayAt(0, 2)));
      await db.collection('plans').doc('plan-1').set(_planDoc());

      await repoAs(_manager).verifyHistoryItem('done-today', message: '굿');

      final done = await action('done-today');
      expect(done['verifiedBy'], _manager);
      expect(done['comment'], '굿');
      final planData = await plan();
      // onPlanUpdated only sends the 인정 push when the manager wrote last.
      expect(planData['lastUpdatedBy'], _manager);
      expect((planData['verifiedDates'] as List), hasLength(1));
    });
  });

  group('approvePlan', () {
    test('restarts a pending plan\'s 4 weeks on the approval day', () async {
      final longAgo = DateTime.now().subtract(const Duration(days: 10));
      await db
          .collection('plans')
          .doc('plan-1')
          .set(
            _planDoc(
              state: 'pending_approval',
              startDate: longAgo,
              endDate: longAgo.add(const Duration(days: 27)),
            ),
          );

      await repoAs(_manager).approvePlan('plan-1');

      final planData = await plan();
      final now = DateTime.now();
      final start = (planData['startDate'] as Timestamp).toDate();
      final end = (planData['endDate'] as Timestamp).toDate();
      expect(planData['state'], 'active');
      expect(planData['lastUpdatedBy'], _manager);
      expect(start, DateTime(now.year, now.month, now.day));
      expect(end, DateTime(now.year, now.month, now.day + 27, 23, 59, 59));
    });

    test('leaves the dates of an already running plan alone', () async {
      final start = DateTime.now().subtract(const Duration(days: 10));
      final end = start.add(const Duration(days: 27));
      await db
          .collection('plans')
          .doc('plan-1')
          .set(_planDoc(state: 'active', startDate: start, endDate: end));

      await repoAs(_manager).approvePlan('plan-1');

      final planData = await plan();
      expect((planData['startDate'] as Timestamp).toDate(), start);
      expect((planData['endDate'] as Timestamp).toDate(), end);
      expect(planData['state'], 'active');
    });
  });

  group('isTodayDoneAction', () {
    final now = DateTime(2026, 10, 2, 21);

    test('accepts only a done record of the plan dated today', () {
      bool check(String type, DateTime date, {String planId = 'plan-1'}) {
        return RealRecordRepository.isTodayDoneAction(
          {'type': type, 'planId': planId, 'date': Timestamp.fromDate(date)},
          planId: 'plan-1',
          now: now,
        );
      }

      expect(check('done', DateTime(2026, 10, 2, 7)), isTrue);
      expect(check('skipped', DateTime(2026, 10, 2, 7)), isFalse);
      expect(check('rested', DateTime(2026, 10, 2, 7)), isFalse);
      expect(check('done', DateTime(2026, 10, 1, 23, 59)), isFalse);
      expect(check('done', DateTime(2026, 10, 2, 7), planId: 'other'), isFalse);
    });
  });

  test('Plan.fromMap reads lastActionId written by reportCompletion', () async {
    await db.collection('plans').doc('plan-1').set(_planDoc());
    await repoAs(_owner).reportCompletion('plan-1');

    final doc = await db.collection('plans').doc('plan-1').get();
    final parsed = Plan.fromMap(doc.data()!, doc.id);
    expect(parsed.lastActionId, isNotNull);
    expect(parsed.lastActionId, doc.data()!['lastActionId']);
  });
}
