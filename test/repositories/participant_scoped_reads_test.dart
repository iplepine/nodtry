// Build 81 must work under both firestore.rules (deployed) and the staged
// firestore.rules.next, which only lets participants read: every query the
// repositories run is recorded and checked against rules.next's list rules
// (test/support/participant_query_spy.dart), and the exact shapes are pinned
// to the contract in docs/operations/SECURITY_RULES.md ("읽기 축소").
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/repositories/real_connect_repository.dart';
import 'package:nod_try/repositories/real_record_repository.dart';
import 'package:nod_try/repositories/real_user_repository.dart';

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

const _me = 'alice';
const _partner = 'bob';

Timestamp _day(int n) => Timestamp.fromDate(DateTime(2026, 10, n, 12));

Map<String, dynamic> _plan(
  String userId, {
  String? managerId,
  String state = 'active',
  DateTime? endDate,
}) {
  final now = DateTime.now();
  return {
    'userId': userId,
    if (managerId != null) 'managerId': managerId,
    'state': state,
    'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'endDate': Timestamp.fromDate(endDate ?? now.add(const Duration(days: 20))),
    'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'items': [
      {
        'title': '헬스장 가기',
        'days': [1, 2, 3, 4, 5, 6, 7],
        'count': 7,
      },
    ],
  };
}

Map<String, dynamic> _action(
  String userId,
  String planId,
  Timestamp date, {
  String? managerId,
  String type = 'done',
}) => {
  'userId': userId,
  'planId': planId,
  if (managerId != null) 'managerId': managerId,
  'type': type,
  'title': '헬스장 가기',
  'date': date,
};

/// alice ⇄ bob are linked (each manages the other's main plan); mallory ⇄
/// carol are strangers. Like rules-tests/test-next/fixtures.js, plus bob's
/// plans alice does not manage (bSolo, and bOld from an earlier partner).
Future<void> _seed(FakeFirebaseFirestore db) async {
  Future<void> put(String path, Map<String, dynamic> data) =>
      db.doc(path).set(data);

  for (final uid in ['alice', 'bob', 'mallory', 'carol']) {
    await put('users/$uid', {
      'displayName': uid,
      'inviteCode': '${uid.toUpperCase().padRight(6, 'X').substring(0, 6)}23',
      'loginType': 'guest',
    });
  }

  await put('plans/aPlan', _plan('alice', managerId: 'bob'));
  await put('plans/aSolo', _plan('alice'));
  await put('plans/bPlan', _plan('bob', managerId: 'alice'));
  await put('plans/bSolo', _plan('bob'));
  await put('plans/bOld', _plan('bob', managerId: 'carol', state: 'active'));
  await put('plans/mPlan', _plan('mallory', managerId: 'carol'));

  await put('actions/a1', _action('alice', 'aPlan', _day(1), managerId: 'bob'));
  await put('actions/a2', _action('alice', 'aSolo', _day(2)));
  await put('actions/aLegacy', _action('alice', 'aPlan', _day(3)));
  await put('actions/b1', _action('bob', 'bPlan', _day(4), managerId: 'alice'));
  await put(
    'actions/bLegacy',
    _action('bob', 'bPlan', _day(2), type: 'skipped'),
  );
  await put('actions/bSolo1', _action('bob', 'bSolo', _day(2)));
  await put(
    'actions/m1',
    _action('mallory', 'mPlan', _day(1), managerId: 'carol'),
  );

  await put('relations/rAB', {'managerId': 'alice', 'executorId': 'bob'});
  await put('relations/rBA', {'managerId': 'bob', 'executorId': 'alice'});
  await put('relations/rMC', {'managerId': 'mallory', 'executorId': 'carol'});
  await put('relations/rCM', {'managerId': 'carol', 'executorId': 'mallory'});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late ParticipantQuerySpy spy;

  RealRecordRepository records() =>
      RealRecordRepository(firestore: spy, auth: _FakeAuth(_me));

  setUp(() async {
    db = FakeFirebaseFirestore();
    await _seed(db);
    spy = ParticipantQuerySpy(db);
  });

  tearDown(() {
    // Every query any test ran must pass rules.next for the signed-in user.
    expect(spy.rulesNextViolations(_me), isEmpty);
  });

  group('the spy flags what rules.next denies', () {
    test('build ≤80 shapes', () async {
      await spy
          .collection('actions')
          .where('userId', whereIn: [_me, _partner])
          .get();
      await spy.collection('actions').where('planId', isEqualTo: 'bPlan').get();
      await spy.collection('plans').where('userId', isEqualTo: _partner).get();
      await spy.collection('users').where('inviteCode', isEqualTo: 'X').get();
      await spy.collection('plans').get();
      await spy
          .collection('plans')
          .where(
            Filter.or(
              Filter('userId', isEqualTo: _me),
              Filter('state', isEqualTo: 'active'),
            ),
          )
          .get();

      expect(spy.rulesNextViolations(_me), hasLength(6));
      spy.clear();
    });
  });

  group('plans', () {
    test('my own: userId == me', () async {
      final plans = await records().getPlansByUserId(_me);

      expect(plans.map((p) => p.id).toSet(), {'aPlan', 'aSolo'});
      expect(spy.shapes, ['plans where userId == alice']);
    });

    test('my partner\'s: only the ones I manage', () async {
      final plans = await records().getPlansByUserId(_partner);

      expect(plans.map((p) => p.id), ['bPlan']);
      expect(spy.shapes, ['plans where userId == bob && managerId == alice']);
    });

    test('streams use the same shapes', () async {
      final repo = records();
      final mine = await repo.getAllPlansByUserIdStream(_me).first;
      final theirs = await repo.getAllPlansByUserIdStream(_partner).first;
      final active = await repo.getPlansByUserIdStream(_partner).first;

      expect(mine.map((p) => p.id).toSet(), {'aPlan', 'aSolo'});
      expect(theirs.map((p) => p.id), ['bPlan']);
      expect(active.map((p) => p.id), ['bPlan']);
      expect(spy.shapes, [
        'plans where userId == alice',
        'plans where userId == bob && managerId == alice',
        'plans where userId == bob && managerId == alice',
      ]);
    });

    test(
      'completeOverduePlans reads only my plans and the ones I manage',
      () async {
        final ended = DateTime.now().subtract(const Duration(days: 2));
        await db.doc('plans/aEnded').set(_plan(_me, endDate: ended));
        await db
            .doc('plans/bEnded')
            .set(_plan(_partner, managerId: _me, endDate: ended));
        await db.doc('plans/mEnded').set(_plan('mallory', endDate: ended));

        final completed = await records().completeOverduePlans();

        expect(completed.toSet(), {'aEnded', 'bEnded'});
        expect((await db.doc('plans/mEnded').get())['state'], 'active');
        expect(spy.shapes, [
          'plans where userId == alice || managerId == alice',
        ]);
      },
    );

    test('the home stream: plans and relations OR-ed on me', () async {
      await records().getHomeCardStatesStream().first;

      expect(spy.shapes, [
        'plans where userId == alice || managerId == alice',
        'relations where executorId == alice || managerId == alice',
      ]);
    });
  });

  group('actions', () {
    test('history of me + partner: two queries merged, newest first', () async {
      final items = await records()
          .getHistoryItemsStream(userIds: [_me, _partner])
          .first;

      // bob's unstamped (bLegacy) and unmanaged (bSolo1) records are not
      // shared with me; m1 is a stranger's.
      expect(items.map((i) => i.id), ['b1', 'aLegacy', 'a2', 'a1']);
      expect(spy.shapes, [
        'actions where userId == alice orderBy date desc',
        'actions where userId == bob && managerId == alice orderBy date desc',
      ]);
    });

    test('a failing partner query keeps my own history', () async {
      // e.g. the (userId, managerId, date) index still building.
      spy.failWhen = (q) => q.shape.contains('managerId == alice');

      final items = await records()
          .getHistoryItemsStream(userIds: [_me, _partner])
          .first;

      expect(items.map((i) => i.id), ['aLegacy', 'a2', 'a1']);
    });

    test('history without user ids: mine only', () async {
      final items = await records().getHistoryItemsStream().first;

      expect(items.map((i) => i.id), ['aLegacy', 'a2', 'a1']);
      expect(spy.shapes, ['actions where userId == alice orderBy date desc']);
    });

    test('getHistoryItems: mine only', () async {
      final items = await records().getHistoryItems();

      expect(items.map((i) => i.id), ['aLegacy', 'a2', 'a1']);
      expect(spy.shapes, ['actions where userId == alice orderBy date desc']);
    });

    test('my plan\'s timeline: planId && userId == me', () async {
      final items = await records()
          .getHistoryItemsByPlanIdStream('aPlan', ownerId: _me)
          .first;

      expect(items.map((i) => i.id), ['aLegacy', 'a1']);
      expect(spy.shapes, [
        'actions where planId == aPlan && userId == alice orderBy date desc',
      ]);
    });

    test('my partner\'s plan timeline: planId && managerId == me', () async {
      final items = await records()
          .getHistoryItemsByPlanIdStream('bPlan', ownerId: _partner)
          .first;

      // bLegacy shows up once the server (or the backfill) stamps it.
      expect(items.map((i) => i.id), ['b1']);
      expect(spy.shapes, [
        'actions where planId == bPlan && managerId == alice orderBy date desc',
      ]);
    });

    test('a timeline without its owner runs both shapes', () async {
      final items = await records()
          .getHistoryItemsByPlanIdStream('bPlan')
          .first;

      expect(items.map((i) => i.id), ['b1']);
      expect(spy.shapes.toSet(), {
        'actions where planId == bPlan && userId == alice orderBy date desc',
        'actions where planId == bPlan && managerId == alice orderBy date desc',
      });
    });

    test(
      '인정 without lastActionId finds today\'s record shared with me',
      () async {
        final now = DateTime.now();
        await db.doc('plans/bToday').set(_plan(_partner, managerId: _me));
        await db
            .doc('actions/bDoneToday')
            .set(
              _action(
                _partner,
                'bToday',
                Timestamp.fromDate(now),
                managerId: _me,
              ),
            );

        await records().verifyPlan('bToday');

        expect((await db.doc('actions/bDoneToday').get())['verifiedBy'], _me);
        expect(spy.shapes, [
          'actions where planId == bToday && managerId == alice && '
              'date >= <time> && date <= <time> orderBy date desc',
        ]);
      },
    );
  });

  group('relations and users', () {
    RealConnectRepository connect() =>
        RealConnectRepository(firestore: spy, auth: _FakeAuth(_me));

    test('connections: executorId == me, managerId == me', () async {
      final relations = await connect().getConnections();

      expect(relations, hasLength(2));
      expect(spy.shapes, [
        'relations where executorId == alice',
        'relations where managerId == alice',
      ]);
    });

    test('disconnect finds the pair through my relations only', () async {
      await connect().disconnectByUser(_partner);

      expect((await db.collection('relations').get()).docs.map((d) => d.id), {
        'rMC',
        'rCM',
      });
      expect(spy.shapes, [
        'relations where executorId == alice || managerId == alice',
      ]);
    });

    test('partner profiles are read by uid, never listed', () async {
      final users = await RealUserRepository(
        firestore: spy,
        auth: _FakeAuth(_me),
      ).getUsersByIds([_partner, 'ghost', _partner]);

      expect(users.map((u) => u.uid), [_partner]);
      expect(spy.queries, isEmpty);
    });
  });
}
