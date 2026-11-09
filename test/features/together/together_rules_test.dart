import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/application/notification_routing.dart';
import 'package:nod_try/features/together/domain/together_rules.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/services/notification_quick_actions.dart';
import 'package:nod_try/services/notification_service.dart';

const _me = 'me';
const _partner = 'partner';

// Wednesday.
final _now = DateTime(2026, 11, 11, 19, 30);

Plan _plan({
  required String id,
  required String userId,
  String? managerId,
  String? workoutType = 'gym',
  List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  int? weeklyTarget,
  PlanState state = PlanState.active,
  List<DateTime> completed = const [],
  List<DateTime> skipped = const [],
  String? lastActionId,
  TogetherMark? lastTogether,
  DateTime? createdAt,
}) {
  return Plan(
    id: id,
    userId: userId,
    managerId: managerId,
    startDate: DateTime(2026, 11, 2),
    endDate: DateTime(2026, 11, 29, 23, 59, 59),
    state: state,
    items: [PlanItem(title: '헬스', days: days, count: days.length)],
    createdAt: createdAt ?? DateTime(2026, 11, 1),
    completedDates: completed,
    skippedDates: skipped,
    workoutType: workoutType,
    weeklyTarget: weeklyTarget,
    lastActionId: lastActionId,
    lastTogether: lastTogether,
  );
}

TogetherTag? _target({
  Plan? myPlan,
  Iterable<Plan>? partnerPlans,
  int? partnerBuild = 88,
  DateTime? now,
}) {
  return togetherTargetFor(
    myPlan: myPlan ?? _plan(id: 'mine', userId: _me, managerId: _partner),
    myUid: _me,
    partnerUid: _partner,
    partnerClientBuild: partnerBuild,
    partnerPlans:
        partnerPlans ?? [_plan(id: 'theirs', userId: _partner, managerId: _me)],
    now: now ?? _now,
  );
}

void main() {
  group('togetherTargetFor (the toggle)', () {
    test("offers the partner's workout due today that they haven't logged", () {
      final tag = _target();
      expect(tag?.partnerUid, _partner);
      expect(tag?.partnerPlanId, 'theirs');
    });

    test('fixed weekdays: only on a scheduled day', () {
      // Mon/Fri only; today is Wednesday.
      final off = _plan(id: 'theirs', userId: _partner, days: [1, 5]);
      expect(_target(partnerPlans: [off]), isNull);
      final on = _plan(id: 'theirs', userId: _partner, days: [3]);
      expect(_target(partnerPlans: [on])?.partnerPlanId, 'theirs');
    });

    test('주 N회: while this week is short of its target', () {
      final short = _plan(
        id: 'theirs',
        userId: _partner,
        weeklyTarget: 3,
        completed: [DateTime(2026, 11, 9, 8)],
      );
      expect(_target(partnerPlans: [short])?.partnerPlanId, 'theirs');
      final met = _plan(
        id: 'theirs',
        userId: _partner,
        weeklyTarget: 2,
        completed: [DateTime(2026, 11, 9, 8), DateTime(2026, 11, 10, 8)],
      );
      expect(_target(partnerPlans: [met]), isNull);
    });

    test('not when the partner already logged (or skipped) today', () {
      final done = _plan(
        id: 'theirs',
        userId: _partner,
        completed: [DateTime(2026, 11, 11, 7)],
      );
      final skipped = _plan(
        id: 'theirs',
        userId: _partner,
        skipped: [DateTime(2026, 11, 11, 7)],
      );
      expect(_target(partnerPlans: [done]), isNull);
      expect(_target(partnerPlans: [skipped]), isNull);
      // Yesterday's record doesn't count.
      final yesterday = _plan(
        id: 'theirs',
        userId: _partner,
        completed: [DateTime(2026, 11, 10, 7)],
      );
      expect(_target(partnerPlans: [yesterday])?.partnerPlanId, 'theirs');
    });

    test('only running workout promises, inside their period', () {
      for (final plan in [
        _plan(id: 'p', userId: _partner, workoutType: null),
        _plan(id: 'p', userId: _partner, workoutType: 'diet'),
        _plan(id: 'p', userId: _partner, state: PlanState.completed),
        _plan(id: 'p', userId: _partner, state: PlanState.pendingApproval),
      ]) {
        expect(_target(partnerPlans: [plan]), isNull);
      }
      expect(_target(now: DateTime(2026, 11, 30, 9)), isNull);
      // A plan of someone else in the list is never offered.
      expect(
        _target(
          partnerPlans: [_plan(id: 'x', userId: 'carol')],
        ),
        isNull,
      );
    });

    test('my side: my running workout plan, managed by the partner', () {
      expect(
        _target(
          myPlan: _plan(id: 'mine', userId: _me, managerId: null),
        ),
        isNull,
        reason: 'the partner reads my record as its manager',
      );
      expect(
        _target(
          myPlan: _plan(
            id: 'mine',
            userId: _me,
            managerId: _partner,
            workoutType: 'diet',
          ),
        ),
        isNull,
      );
      expect(
        _target(
          myPlan: _plan(id: 'mine', userId: _partner, managerId: _me),
        ),
        isNull,
      );
    });

    test('not for a partner on a build that cannot confirm', () {
      expect(_target(partnerBuild: 87), isNull);
      expect(_target(partnerBuild: null), isNull);
      expect(_target(partnerBuild: kTogetherBuild), isNotNull);
    });

    test('prefers the same workout, then the oldest plan', () {
      final running = _plan(
        id: 'run',
        userId: _partner,
        workoutType: 'running',
        createdAt: DateTime(2026, 10, 1),
      );
      final gymNew = _plan(
        id: 'gym-new',
        userId: _partner,
        createdAt: DateTime(2026, 11, 3),
      );
      final gymOld = _plan(
        id: 'gym-old',
        userId: _partner,
        createdAt: DateTime(2026, 11, 2),
      );
      expect(
        _target(partnerPlans: [running, gymNew, gymOld])?.partnerPlanId,
        'gym-old',
      );
    });
  });

  group('pendingTogetherClaims (the 나도 했어 card)', () {
    TogetherMark mark({
      String actionId = 'a1',
      String withUid = _me,
      String planId = 'mine',
      DateTime? at,
    }) => TogetherMark(
      actionId: actionId,
      withUid: withUid,
      planId: planId,
      at: at ?? DateTime(2026, 11, 11, 18),
    );

    List<TogetherClaim> claims({
      TogetherMark? lastTogether,
      String lastActionId = 'a1',
      Plan? mine,
      Set<String> dismissed = const {},
    }) => pendingTogetherClaims(
      partnerPlans: [
        _plan(
          id: 'theirs',
          userId: _partner,
          lastActionId: lastActionId,
          lastTogether: lastTogether ?? mark(),
        ),
      ],
      myPlans: [mine ?? _plan(id: 'mine', userId: _me)],
      myUid: _me,
      now: _now,
      dismissedActionIds: dismissed,
    );

    test("shows today's claim for my plan", () {
      final list = claims();
      expect(list, hasLength(1));
      expect(list.single.sourceActionId, 'a1');
      expect(list.single.myPlan.id, 'mine');
      expect(list.single.sourcePlan.id, 'theirs');
    });

    test('gone once a later record replaced it, or on another day', () {
      expect(claims(lastActionId: 'a2'), isEmpty);
      expect(
        claims(lastTogether: mark(at: DateTime(2026, 11, 10, 18))),
        isEmpty,
      );
    });

    test('only claims naming me and one of my running plans', () {
      expect(claims(lastTogether: mark(withUid: 'carol')), isEmpty);
      expect(claims(lastTogether: mark(planId: 'nope')), isEmpty);
      expect(
        claims(
          mine: _plan(id: 'mine', userId: _me, state: PlanState.stopped),
        ),
        isEmpty,
      );
    });

    test('gone once I logged that plan today, or put the card away', () {
      expect(
        claims(
          mine: _plan(
            id: 'mine',
            userId: _me,
            completed: [DateTime(2026, 11, 11, 18, 5)],
          ),
        ),
        isEmpty,
      );
      expect(claims(dismissed: {'a1'}), isEmpty);
    });
  });

  group('data contract', () {
    test('plans.lastTogether round-trips and is optional', () {
      final plan = _plan(
        id: 'p',
        userId: _me,
        lastTogether: TogetherMark(
          actionId: 'a1',
          withUid: _partner,
          planId: 'theirs',
          at: DateTime(2026, 11, 11, 18),
        ),
      );
      final back = Plan.fromMap(plan.toMap(), 'p');
      expect(back.lastTogether?.actionId, 'a1');
      expect(back.lastTogether?.withUid, _partner);
      expect(back.lastTogether?.planId, 'theirs');
      expect(back.lastTogether?.at, DateTime(2026, 11, 11, 18));
      expect(back.copyWith(lastActionId: 'x').lastTogether?.actionId, 'a1');

      final legacy = _plan(id: 'p', userId: _me).toMap();
      expect(legacy.containsKey('lastTogether'), isFalse);
      expect(Plan.fromMap(legacy, 'p').lastTogether, isNull);
      expect(
        Plan.fromMap({...legacy, 'lastTogether': 'garbage'}, 'p').lastTogether,
        isNull,
      );
      expect(TogetherMark.fromMap({'actionId': 'a1'}), isNull);
    });

    test(
      'actions keep their type and proofSource; the new fields are extra',
      () {
        final item = HistoryItem.fromMap({
          'userId': _partner,
          'planId': 'theirs',
          'type': 'done',
          'date': Timestamp.fromDate(_now),
          'proofPhotoPath': 'proofs/me/mine/a1.jpg',
          'proofSource': 'camera',
          'sharedProofFromUid': _me,
          'togetherActionId': 'a1',
        }, 'b1');
        expect(item.status, HistoryStatus.done);
        expect(item.proofSource, 'camera');
        expect(item.sharedProofFromUid, _me);
        expect(item.hasSharedProof, isTrue);

        final mine = HistoryItem.fromMap({
          'userId': _me,
          'type': 'done',
          'togetherWithUid': _partner,
        }, 'a1');
        expect(mine.togetherWithUid, _partner);
        expect(mine.hasSharedProof, isFalse);
      },
    );
  });

  group('the together_log push', () {
    test('has the 나도 했어 button and opens the Now tab', () {
      expect(quickActionsForCategory('together_log'), [
        NotificationQuickAction.togetherDone,
      ]);
      final request = NotificationOpenRequest.fromData({
        'type': 'together_log',
        'planId': 'mine',
        'actionId': 'a1',
        'actionDate': '${DateTime.now().millisecondsSinceEpoch}',
      }, actionId: 'quick_together_done');
      expect(request?.quickAction, NotificationQuickAction.togetherDone);
      expect(request?.actionId, 'a1');
      expect(
        notificationOpenTargetForRequest(request!),
        NotificationOpenTarget.now,
      );
      // Never run on a card: the home screen logs it.
      for (final area in NowCardArea.values) {
        expect(
          quickActionFitsArea(NotificationQuickAction.togetherDone, area),
          isFalse,
        );
      }
    });

    test('an unknown future type still opens nothing', () {
      expect(
        notificationOpenTargetFor('together_log_v2'),
        NotificationOpenTarget.none,
      );
    });
  });
}
