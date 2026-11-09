import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/weekly_target.dart';

// 2026-09-28 is a Monday.
DateTime d(int month, int day, [int hour = 0, int minute = 0, int s = 0]) =>
    DateTime(2026, month, day, hour, minute, s);

const _allDays = [1, 2, 3, 4, 5, 6, 7];

Plan weeklyPlan({
  int target = 3,
  DateTime? start,
  DateTime? end,
  List<DateTime> completed = const [],
  List<DateTime> rested = const [],
  List<DateTime> rescued = const [],
  List<DateTime> skipped = const [],
  PlanState state = PlanState.active,
}) {
  final s = start ?? d(9, 28);
  final period = Plan.periodStartingOn(s);
  return Plan(
    id: 'w',
    userId: 'me',
    managerId: 'partner',
    startDate: period.start,
    endDate: end ?? period.end,
    state: state,
    items: [PlanItem(title: '러닝', days: _allDays, count: 7)],
    createdAt: s,
    completedDates: [
      for (final x in completed) x.add(const Duration(hours: 19)),
    ],
    restedDates: [for (final x in rested) x.add(const Duration(hours: 20))],
    rescuedDates: [for (final x in rescued) x.add(const Duration(hours: 9))],
    skippedDates: [for (final x in skipped) x.add(const Duration(hours: 22))],
    weeklyTarget: target,
  );
}

List<bool> _flags(String s) => [for (final c in s.split('')) c == '1'];
String _str(List<bool> l) => l.map((b) => b ? '1' : '0').join();

void main() {
  group('shared vectors (same file as functions/test/weekly.test.js)', () {
    final json =
        jsonDecode(
              File(
                'test/fixtures/weekly_target_vectors.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final cases = (json['cases'] as List).cast<Map<String, dynamic>>();

    test('there are vectors', () => expect(cases.length, greaterThan(10)));

    for (final c in cases) {
      test(c['name'], () {
        final week = evaluateWeeklyWeek(
          weeklyTarget: c['target'] as int,
          inPeriod: _flags(c['inPeriod'] as String),
          credited: _flags(c['credited'] as String),
        );
        expect(week.target, c['weekTarget']);
        expect(week.credited, c['creditedCount']);
        expect(_str(week.mustDo), c['mustDo']);
      });
    }
  });

  group('parseWeeklyTarget', () {
    test('ints 1–6 only; anything else reads as fixed weekdays', () {
      expect(parseWeeklyTarget(1), 1);
      expect(parseWeeklyTarget(6), 6);
      expect(parseWeeklyTarget(3.0), 3);
      for (final bad in [0, 7, 2.5, '3', null, true]) {
        expect(parseWeeklyTarget(bad), isNull, reason: '$bad');
      }
    });

    test('round-trips through toMap / fromMap and is absent otherwise', () {
      final plan = weeklyPlan(target: 4);
      final map = plan.toMap();
      expect(map['weeklyTarget'], 4);
      expect(map['items'][0]['days'], _allDays);
      final back = Plan.fromMap(map, 'w');
      expect(back.weeklyTarget, 4);
      expect(back.isWeekly, isTrue);

      final fixed = back.copyWith(clearWeeklyTarget: true);
      expect(fixed.isWeekly, isFalse);
      expect(fixed.toMap().containsKey('weeklyTarget'), isFalse);
      expect(back.asRestartTemplate().weeklyTarget, 4);

      final malformed = Map<String, dynamic>.from(map)..['weeklyTarget'] = 9;
      expect(Plan.fromMap(malformed, 'w').weeklyTarget, isNull);
    });
  });

  group('must-do days and week boundaries', () {
    test('nothing logged: Fri–Sun are must-do, Mon–Thu neutral', () {
      final plan = weeklyPlan();
      expect(plan.isDueOn(d(9, 28)), isFalse);
      expect(plan.isDueOn(d(10, 1)), isFalse);
      expect(plan.isDueOn(d(10, 2)), isTrue);
      expect(plan.isDueOn(d(10, 4, 23, 30)), isTrue);
    });

    test('a new week starts over on Monday', () {
      final plan = weeklyPlan(completed: [d(9, 28), d(9, 29), d(9, 30)]);
      expect(plan.isWeeklyGoalMet(asOf: d(10, 4)), isTrue);
      expect(plan.isWeeklyGoalMet(asOf: d(10, 5)), isFalse);
      expect(plan.weeklyProgress(asOf: d(10, 4)), (done: 3, target: 3));
      expect(plan.weeklyProgress(asOf: d(10, 5)), (done: 0, target: 3));
      expect(plan.isDueOn(d(10, 4)), isFalse);
      expect(plan.isDueOn(d(10, 9)), isTrue);
    });

    test('rest passes and rescues credit the week; skips do not', () {
      final rested = weeklyPlan(
        target: 2,
        completed: [d(9, 28)],
        rested: [d(9, 30)],
      );
      expect(rested.isWeeklyGoalMet(asOf: d(10, 1)), isTrue);
      expect(rested.isDueOn(d(10, 4)), isFalse);

      final rescued = weeklyPlan(target: 1, rescued: [d(9, 29)]);
      expect(rescued.isWeeklyGoalMet(asOf: d(9, 29)), isTrue);

      final skipped = weeklyPlan(target: 1, skipped: [d(9, 28)]);
      expect(skipped.weeklyProgress(asOf: d(9, 28))!.done, 0);
      expect(skipped.isDueOn(d(10, 4)), isTrue);
    });

    test('a record stored as a UTC instant counts on its local day', () {
      final lateNight = d(9, 30, 23, 30).toUtc();
      final plan = Plan(
        id: 'w',
        userId: 'me',
        startDate: d(9, 28),
        endDate: d(10, 25, 23, 59, 59),
        state: PlanState.active,
        items: [PlanItem(title: '러닝', days: _allDays, count: 7)],
        createdAt: d(9, 28),
        completedDates: [lateNight],
        weeklyTarget: 1,
      );
      final week = plan.weeklyWeekOf(d(9, 30))!;
      expect(week.creditedDays[2], isTrue); // Wednesday
      expect(week.isMet, isTrue);
    });

    test('a partial first week asks for a prorated target', () {
      // Starts Saturday Oct 3: Sat–Sun, three full weeks, Mon–Fri.
      final plan = weeklyPlan(start: d(10, 3));
      expect(plan.weeklyProgress(asOf: d(10, 3))!.target, 1);
      expect(plan.isDueOn(d(10, 3)), isFalse);
      expect(plan.isDueOn(d(10, 4)), isTrue);
      expect(plan.scheduledDayCount, 1 + 9 + 3);
    });
  });

  group('4-week math', () {
    // Week 1: Mon+Tue done → only Sunday 10/4 must-do (missed).
    // Week 2: Saturday only → Fri 10/9 and Sun 10/11 missed.
    final plan = weeklyPlan(completed: [d(9, 28), d(9, 29), d(10, 10)]);

    test('scheduled = the weekly targets of the period', () {
      expect(plan.scheduledDayCount, 12);
      expect(plan.promiseTargetDaysLimit, 12);
    });

    test('failed = missed must-do days only', () {
      expect(plan.failedDayCount(asOf: d(10, 3)), 0);
      expect(plan.failedDayCount(asOf: d(10, 5)), 1);
      expect(plan.failedDayCount(asOf: d(10, 12)), 3);
      // Same numbers as functions/test/weekly.test.js "weekly 내기 tally".
      expect(plan.failedDayCount(asOf: d(10, 26)), 9);
      expect(plan.completedDayCount(asOf: d(10, 26)), 3);
    });

    test('remaining = what each open week still needs', () {
      expect(plan.remainingScheduledDayCount(asOf: d(10, 12)), 6);
      // Sat 10/10: week 2 still needs 2 but only Sunday is left open.
      expect(plan.remainingScheduledDayCount(asOf: d(10, 10)), 1 + 6);
      expect(plan.completedDayCount(asOf: d(10, 12)), 3);
      expect(
        plan.rewardTargetDaysLimit(asOf: d(10, 12)),
        plan.completedDayCount(asOf: d(10, 12)) + 6,
      );
    });

    test('extra days beyond the target still count as successes', () {
      final extra = weeklyPlan(
        target: 1,
        completed: [d(9, 28), d(9, 29), d(9, 30)],
      );
      expect(extra.completedDayCount(asOf: d(10, 4)), 3);
      expect(extra.failedDayCount(asOf: d(10, 5)), 0);
    });
  });

  group('rate success (capped per week)', () {
    // 주 3회 done Mon–Thu (4×) every week of the 4-week period.
    final fourAWeek = weeklyPlan(
      state: PlanState.completed,
      completed: [
        for (final monday in [d(9, 28), d(10, 5), d(10, 12), d(10, 19)])
          for (var i = 0; i < 4; i++)
            DateTime(monday.year, monday.month, monday.day + i),
      ],
    );

    test('extra workouts do not push the rate above the targets', () {
      expect(fourAWeek.scheduledDayCount, 12);
      expect(fourAWeek.completedDayCount(asOf: d(10, 26)), 16);
      expect(fourAWeek.rateSuccessDayCount(asOf: d(10, 26)), 12);
    });

    test('a short week is not covered by an extra-heavy one', () {
      // Week 1: 4 done (counts 3); week 2: 2 done (counts 2).
      final plan = weeklyPlan(
        completed: [d(9, 28), d(9, 29), d(9, 30), d(10, 1), d(10, 5), d(10, 6)],
      );
      expect(plan.completedDayCount(asOf: d(10, 12)), 6);
      expect(plan.rateSuccessDayCount(asOf: d(10, 12)), 5);
      // asOf cuts the count like completedDayCount.
      expect(plan.rateSuccessDayCount(asOf: d(9, 29)), 2);
    });

    test('a prorated first week caps at its prorated target', () {
      // Saturday start: the first weekend asks for 1 of 주 3회.
      final plan = weeklyPlan(start: d(10, 3), completed: [d(10, 3), d(10, 4)]);
      expect(plan.completedDayCount(asOf: d(10, 5)), 2);
      expect(plan.rateSuccessDayCount(asOf: d(10, 5)), 1);
    });

    test('fixed-weekday plans use the plain done count', () {
      final plan = Plan(
        id: 'f',
        userId: 'me',
        managerId: 'partner',
        startDate: d(9, 28),
        endDate: d(10, 25),
        state: PlanState.active,
        items: [
          PlanItem(title: '러닝', days: const [1, 3, 5], count: 3),
        ],
        createdAt: d(9, 28),
        completedDates: [d(9, 28, 19), d(9, 29, 19), d(9, 30, 19)],
      );
      expect(plan.rateSuccessDayCount(asOf: d(10, 1)), 3);
      expect(plan.completedDayCount(asOf: d(10, 1)), 3);
    });
  });

  group('plan streak (relative to today)', () {
    final now = DateTime.now();
    final thisMonday = weeklyWeekStartOf(now);
    DateTime weeksAgo(int w, int weekday) => DateTime(
      thisMonday.year,
      thisMonday.month,
      thisMonday.day - 7 * w + (weekday - 1),
    );

    test('done days count, neutral days are skipped', () {
      final plan = weeklyPlan(
        target: 1,
        start: weeksAgo(2, 1),
        completed: [weeksAgo(2, 1), weeksAgo(1, 7)],
      );
      // This week only Sunday is must-do: earlier days are neutral and today
      // is still open whatever weekday it is.
      expect(plan.currentStreak, 2);
    });

    test('a missed must-do day ends it', () {
      final plan = weeklyPlan(
        target: 1,
        start: weeksAgo(2, 1),
        completed: [weeksAgo(2, 1)],
      );
      expect(plan.currentStreak, 0);
    });

    test('a rest pass is spent once the week is met', () {
      final met = weeklyPlan(
        target: 1,
        start: weeksAgo(1, 1),
        completed: [DateTime(now.year, now.month, now.day)],
      );
      expect(met.canUseRestToday, isFalse);
      final open = weeklyPlan(target: 1, start: weeksAgo(1, 1));
      expect(open.canUseRestToday, isTrue);
    });
  });

  test('fixed-weekday plans are unchanged', () {
    final plan = Plan(
      userId: 'me',
      startDate: d(9, 28),
      endDate: d(10, 25, 23, 59, 59),
      state: PlanState.active,
      items: [
        PlanItem(title: '러닝', days: const [1, 3, 5], count: 3),
      ],
      createdAt: d(9, 28),
    );
    expect(plan.isWeekly, isFalse);
    expect(plan.weeklyProgress(), isNull);
    expect(plan.isDueOn(d(9, 28)), isTrue);
    expect(plan.isDueOn(d(9, 29)), isFalse);
    expect(plan.scheduledDayCount, 12);
    expect(plan.toMap().containsKey('weeklyTarget'), isFalse);
    // A Firestore Timestamp in the stored map parses like any other field.
    expect(
      Plan.fromMap({
        ...plan.toMap(),
        'weeklyTarget': 2,
        'startDate': Timestamp.fromDate(d(9, 28)),
      }, 'x').weeklyTarget,
      2,
    );
  });
}
