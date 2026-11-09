// The actions-first read path (REMAINING_IMPROVEMENTS.md §3, 1단계) through
// the real repository on a fake Firestore: streamed plans gain the record
// days their actions have, with one bounded listener per plan owner, query
// shapes that rules.next allows, and the arrays alone when actions fail.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/repositories/plan_action_records_source.dart';
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

const _me = 'alice';
const _partner = 'bob';

final DateTime _now = DateTime.now();

DateTime _day(int offset, {int hour = 12}) =>
    DateTime(_now.year, _now.month, _now.day + offset, hour);

Timestamp _ts(DateTime d) => Timestamp.fromDate(d);

Map<String, dynamic> _plan(
  String userId, {
  String? managerId,
  List<DateTime> completed = const [],
  int startOffset = -10,
  int endOffset = 17,
}) => {
  'userId': userId,
  if (managerId != null) 'managerId': managerId,
  'state': 'active',
  'startDate': _ts(_day(startOffset, hour: 0)),
  'endDate': _ts(DateTime(_now.year, _now.month, _now.day + endOffset, 23)),
  'createdAt': _ts(_day(startOffset, hour: 0)),
  'workoutType': 'gym',
  'items': [
    {
      'title': '헬스장 가기',
      'days': [1, 2, 3, 4, 5, 6, 7],
      'count': 7,
    },
  ],
  'completedDates': [for (final d in completed) _ts(d)],
};

Map<String, dynamic> _action(
  String userId,
  String planId,
  DateTime date, {
  String type = 'done',
  String? managerId,
}) => {
  'userId': userId,
  'planId': planId,
  'type': type,
  'date': _ts(date),
  'title': '헬스장 가기',
  if (managerId != null) 'managerId': managerId,
};

Set<int> _keys(List<DateTime> dates) => {
  for (final d in dates) d.year * 10000 + d.month * 100 + d.day,
};

Future<T> _until<T>(Stream<T> stream, bool Function(T) test) =>
    stream.firstWhere(test).timeout(const Duration(seconds: 5));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late ParticipantQuerySpy spy;

  RealRecordRepository records() =>
      RealRecordRepository(firestore: spy, auth: _FakeAuth(_me));

  setUp(() {
    db = FakeFirebaseFirestore();
    spy = ParticipantQuerySpy(db);
  });

  tearDown(() {
    expect(spy.rulesNextViolations(_me), isEmpty);
  });

  test('the window starts on a Monday at least 35 days back', () {
    for (var i = 0; i < 14; i++) {
      final now = DateTime(2026, 11, 3 + i, 18, 30);
      final start = PlanActionRecordsSource.windowStartFor(now);
      expect(start.weekday, DateTime.monday, reason: '$now');
      expect(start.hour, 0);
      final back = DateTime(now.year, now.month, now.day).difference(start);
      expect(back.inDays, inInclusiveRange(35, 41), reason: '$now');
    }
  });

  group('my plans', () {
    setUp(() async {
      // Yesterday and today only have an action (e.g. a write that never
      // reached the array); 3 days ago only the array has it.
      await db
          .doc('plans/aPlan')
          .set(_plan(_me, managerId: _partner, completed: [_day(-3)]));
      await db.doc('actions/a1').set(_action(_me, 'aPlan', _day(-1)));
      await db
          .doc('actions/a2')
          .set(_action(_me, 'aPlan', _day(0), type: 'rested'));
      // Before the window: not read (the array is what counts there).
      await db.doc('actions/aOld').set(_action(_me, 'aPlan', _day(-60)));
      // Another of my plans, and a stranger's record on my plan id.
      await db.doc('actions/a3').set(_action(_me, 'aOther', _day(-1)));
      await db.doc('actions/x1').set(_action('mallory', 'aPlan', _day(-2)));
    });

    test('the arrays first, then the actions merged in', () async {
      final emissions = <List<Plan>>[];
      final merged = await _until(
        records().getPlansByUserIdStream(_me).map((plans) {
          emissions.add(plans);
          return plans;
        }),
        (plans) => plans.single.restedDates.isNotEmpty,
      );

      final plan = merged.single;
      expect(_keys(plan.completedDates), _keys([_day(-3), _day(-1)]));
      expect(_keys(plan.restedDates), _keys([_day(0)]));
      // Arrays only at first: the stream never waits on the actions.
      expect(_keys(emissions.first.single.completedDates), _keys([_day(-3)]));
      // Written back as stored.
      expect(
        (plan.toMap()['completedDates'] as List).map(
          (t) => (t as Timestamp).toDate(),
        ),
        [_day(-3)],
      );
      expect(spy.shapes.where((s) => s.startsWith('actions')), [
        'actions where userId == alice && date >= <time> orderBy date desc',
      ]);
    });

    test('a failing actions query leaves the arrays', () async {
      spy.failWhen = (q) => q.collection == 'actions';
      final plans = await records().getAllPlansByUserIdStream(_me).first;
      // Give the failed listener a moment: still the arrays, no error.
      final later = await records()
          .getAllPlansByUserIdStream(_me)
          .take(2)
          .last
          .timeout(const Duration(seconds: 5));
      expect(_keys(plans.single.completedDates), _keys([_day(-3)]));
      expect(_keys(later.single.completedDates), _keys([_day(-3)]));
    });

    test('a plan that ended before the window reads no actions', () async {
      await db.doc('plans/aPlan').delete();
      await db
          .doc('plans/aDone')
          .set(_plan(_me, startOffset: -90, endOffset: -62));
      final plans = await records().getAllPlansByUserIdStream(_me).first;
      expect(plans.single.id, 'aDone');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(spy.shapes.where((s) => s.startsWith('actions')), isEmpty);
    });
  });

  group("my partner's plans", () {
    setUp(() async {
      await db.doc('plans/bPlan').set(_plan(_partner, managerId: _me));
      await db.doc('plans/bPlan2').set(_plan(_partner, managerId: _me));
      // Today's done, shared with me — the plan array hasn't caught up.
      await db
          .doc('actions/b1')
          .set(_action(_partner, 'bPlan', _day(0), managerId: _me));
      // Not shared with me (unstamped): never read; the array decides.
      await db.doc('actions/bLegacy').set(_action(_partner, 'bPlan', _day(-1)));
      await db.doc('relations/rAB').set({
        'managerId': _me,
        'executorId': _partner,
      });
    });

    test('one listener for all their plans, shared records only', () async {
      final plans = await _until(
        records().getPlansByUserIdStream(_partner),
        (plans) => plans.any((p) => p.completedDates.isNotEmpty),
      );
      final bPlan = plans.firstWhere((p) => p.id == 'bPlan');
      expect(_keys(bPlan.completedDates), _keys([_day(0)]));
      expect(plans.firstWhere((p) => p.id == 'bPlan2').completedDates, isEmpty);
      expect(spy.shapes.where((s) => s.startsWith('actions')), [
        'actions where userId == bob && managerId == alice && '
            'date >= <time> orderBy date desc',
      ]);
    });

    test('the home card sees the done the array is missing', () async {
      final cards = await _until(
        records().getHomeCardStatesStream(),
        (cards) => cards.any(
          (c) =>
              c.state == HomeCardState.partnerAction ||
              c.state == HomeCardState.partnerTodayComplete,
        ),
      );
      final card = cards.firstWhere(
        (c) =>
            c.state == HomeCardState.partnerAction ||
            c.state == HomeCardState.partnerTodayComplete,
      );
      expect(card.plan!.id, 'bPlan');
      expect(spy.shapes.toSet(), {
        'plans where userId == alice || managerId == alice',
        'relations where executorId == alice || managerId == alice',
        'actions where userId == bob && managerId == alice && '
            'date >= <time> orderBy date desc',
      });
    });
  });
}
