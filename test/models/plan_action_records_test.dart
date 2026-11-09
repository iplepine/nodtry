// plans 기록 배열 → actions (REMAINING_IMPROVEMENTS.md §3, 1단계): a plan's
// record days read from its actions must equal the ones its arrays give —
// whatever mix of the two a plan has — and every derived state (streak,
// counts, 주 N회 progress, 같이 했어, reminders, 둘운완 stats) must follow.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/domain/duo_stats.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/features/together/domain/together_rules.dart';
import 'package:nod_try/models/plan_action_records.dart';
import 'package:nod_try/models/plan_model.dart';

const _me = 'owner';
const _partner = 'partner';

final DateTime _now = DateTime.now();
final DateTime _today = DateTime(_now.year, _now.month, _now.day);

/// Noon of the day [offset] days from today (negative: past).
DateTime _day(int offset, {int hour = 12}) =>
    DateTime(_today.year, _today.month, _today.day + offset, hour);

/// One record of a scenario: an array entry and the action that mirrors it.
class _Rec {
  const _Rec(this.type, this.offset, {this.verified = false, this.hour = 12});

  final ActionRecordType type;
  final int offset;
  final bool verified;
  final int hour;

  DateTime get date => _day(offset, hour: hour);
}

Plan _plan({
  String id = 'p1',
  String userId = _me,
  int? weeklyTarget,
  List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  List<_Rec> arrays = const [],
}) {
  List<DateTime> of(ActionRecordType type) => [
    for (final r in arrays)
      if (r.type == type) r.date,
  ];
  return Plan(
    id: id,
    userId: userId,
    managerId: userId == _me ? _partner : _me,
    startDate: _day(-12, hour: 0),
    endDate: DateTime(_today.year, _today.month, _today.day + 15, 23, 59, 59),
    state: PlanState.active,
    createdAt: _day(-12, hour: 0),
    items: [PlanItem(title: '헬스장 가기', days: days, count: days.length)],
    weeklyTarget: weeklyTarget,
    workoutType: 'gym',
    completedDates: of(ActionRecordType.done),
    skippedDates: of(ActionRecordType.skipped),
    restedDates: of(ActionRecordType.rested),
    rescuedDates: of(ActionRecordType.rescued),
    verifiedDates: [
      for (final r in arrays)
        if (r.verified) r.date,
    ],
  );
}

List<PlanActionRecord> _actions(
  List<_Rec> recs, {
  String planId = 'p1',
  String userId = _me,
}) => [
  for (final (i, r) in recs.indexed)
    PlanActionRecord(
      id: '$planId-a$i',
      planId: planId,
      userId: userId,
      type: r.type,
      date: r.date,
      verified: r.verified,
    ),
];

Set<int> _keys(List<DateTime> dates) => {
  for (final d in dates) d.year * 10000 + d.month * 100 + d.day,
};

/// Everything the app derives from a plan's record days.
Map<String, Object?> _derived(Plan plan) {
  final days = [for (var i = -14; i <= 2; i++) _day(i)];
  return {
    'completed': _keys(plan.completedDates),
    'skipped': _keys(plan.skippedDates),
    'rested': _keys(plan.restedDates),
    'rescued': _keys(plan.rescuedDates),
    'verified': _keys(plan.verifiedDates),
    'streak': plan.currentStreak,
    'completedDayCount': plan.completedDayCount(),
    'rateSuccessDayCount': plan.rateSuccessDayCount(),
    'failedDayCount': plan.failedDayCount(),
    'remaining': plan.remainingScheduledDayCount(),
    'canUseRestToday': plan.canUseRestToday,
    'weeklyProgress': plan.weeklyProgress()?.toString(),
    'weeklyGoalMet': plan.isWeeklyGoalMet(),
    'dueOn': [for (final d in days) plan.isDueOn(d)],
    'togetherHasRecord': [for (final d in days) hasRecordOn(plan, d)],
    'togetherDueToday': isTogetherDueToday(plan, _now),
    'reminderSkip': [for (final d in days) planHasRecordOn(plan, d)],
  };
}

String _duo(Plan mine, Plan theirs) {
  final stats = computeDuoStats(
    myPlans: [mine],
    partnerPlans: [theirs],
    today: _today,
  );
  return [
    stats.streak,
    stats.today,
    for (final d in stats.week) d,
    countVerificationsReceived([mine]),
  ].join('|');
}

// A fixed-weekday scenario: done, a 휴식권, a skip, a partner's 실천 인정, an
// 인정, two records on one day, today done.
const _fixed = [
  _Rec(ActionRecordType.done, -9, verified: true),
  _Rec(ActionRecordType.skipped, -8),
  _Rec(ActionRecordType.done, -7),
  _Rec(ActionRecordType.rescued, -6),
  _Rec(ActionRecordType.rested, -5),
  _Rec(ActionRecordType.done, -4, verified: true),
  _Rec(ActionRecordType.done, -3),
  _Rec(ActionRecordType.done, -2, verified: true),
  _Rec(ActionRecordType.done, -1),
  _Rec(ActionRecordType.done, 0),
];

// 주 3회: credits spread over this week and the last two.
const _weekly = [
  _Rec(ActionRecordType.done, -11),
  _Rec(ActionRecordType.done, -9),
  _Rec(ActionRecordType.rested, -8),
  _Rec(ActionRecordType.done, -6, verified: true),
  _Rec(ActionRecordType.done, -4),
  _Rec(ActionRecordType.rescued, -3),
  _Rec(ActionRecordType.done, -2),
  _Rec(ActionRecordType.skipped, -1),
  _Rec(ActionRecordType.done, 0),
];

void main() {
  group('derivation equivalence', () {
    for (final (name, recs, weeklyTarget) in [
      ('fixed weekdays', _fixed, null),
      ('주 3회', _weekly, 3),
    ]) {
      group(name, () {
        final fromArrays = _plan(arrays: recs, weeklyTarget: weeklyTarget);
        final expected = _derived(fromArrays);

        test('arrays only: unchanged, the very same plan', () {
          expect(fromArrays.withActionRecords(const []), same(fromArrays));
          expect(_derived(fromArrays), expected);
        });

        test('actions only: the same days and the same state', () {
          final merged = _plan(
            weeklyTarget: weeklyTarget,
          ).withActionRecords(_actions(recs));
          expect(_derived(merged), expected);
          expect(
            _duo(merged, _plan(userId: _partner, id: 'p2')),
            _duo(fromArrays, _plan(userId: _partner, id: 'p2')),
          );
        });

        test('mixed: half in each (and some in both) — the union', () {
          final arrays = [
            for (final (i, r) in recs.indexed)
              if (i.isEven) r,
          ];
          final actions = [
            for (final (i, r) in recs.indexed)
              if (i.isOdd || i % 4 == 0) r,
          ];
          final merged = _plan(
            arrays: arrays,
            weeklyTarget: weeklyTarget,
          ).withActionRecords(_actions(actions));
          expect(_derived(merged), expected);
        });

        test('arrays and actions agree: the very same plan', () {
          expect(
            fromArrays.withActionRecords(_actions(recs)),
            same(fromArrays),
          );
        });

        test('derived state equals PlanRecordDates.fromActions', () {
          final fromActions = PlanRecordDates.fromActions(_actions(recs));
          final merged = _plan(
            weeklyTarget: weeklyTarget,
          ).withActionRecords(_actions(recs));
          expect(_keys(merged.completedDates), _keys(fromActions.completed));
          expect(_keys(merged.skippedDates), _keys(fromActions.skipped));
          expect(_keys(merged.restedDates), _keys(fromActions.rested));
          expect(_keys(merged.rescuedDates), _keys(fromActions.rescued));
          expect(_keys(merged.verifiedDates), _keys(fromActions.verified));
        });
      });
    }

    test('no day disappears: an array day without an action stays', () {
      final plan = _plan(
        arrays: const [_Rec(ActionRecordType.done, -3)],
      ).withActionRecords(_actions(const [_Rec(ActionRecordType.skipped, -2)]));
      expect(_keys(plan.completedDates), _keys([_day(-3)]));
      expect(_keys(plan.skippedDates), _keys([_day(-2)]));
    });

    test('a day already in the array keeps its stored moments', () {
      final stored = _day(-1, hour: 7);
      final plan = _plan(
        arrays: const [
          _Rec(ActionRecordType.done, -1, hour: 7),
          _Rec(ActionRecordType.done, -1, hour: 7, verified: true),
        ],
      );
      final merged = plan.withActionRecords(
        _actions(const [
          _Rec(ActionRecordType.done, -1, hour: 21, verified: true),
          _Rec(ActionRecordType.done, -3, hour: 8),
          _Rec(ActionRecordType.done, -3, hour: 9),
        ]),
      );
      // The array's own entries first and untouched; one entry for the new
      // day (its latest record), in time order.
      expect(merged.completedDates, [_day(-3, hour: 9), stored, stored]);
      expect(merged.verifiedDates, [stored]);
    });
  });

  group('which records count', () {
    test("only this plan's records by its owner", () {
      final plan = _plan();
      final merged = plan.withActionRecords([
        // Another plan of mine.
        ..._actions(const [_Rec(ActionRecordType.done, -1)], planId: 'other'),
        // The partner's "같이 했어" names my plan but is theirs.
        ..._actions(
          const [_Rec(ActionRecordType.done, 0)],
          planId: 'p1',
          userId: _partner,
        ),
      ]);
      expect(merged, same(plan));
    });

    test('a 같이 했어 claim never logs my plan; my own 나도 했어 does', () {
      final mine = _plan();
      final claim = _actions(
        const [_Rec(ActionRecordType.done, 0)],
        planId: 'theirs',
        userId: _partner,
      );
      final beforeConfirm = mergePlanActionRecords([mine], claim).single;
      expect(hasRecordOn(beforeConfirm, _today), isFalse);
      expect(isTogetherDueToday(beforeConfirm, _now), isTrue);

      final confirm = _actions(const [_Rec(ActionRecordType.done, 0)]);
      final after = mergePlanActionRecords(
        [mine],
        [...claim, ...confirm],
      ).single;
      expect(hasRecordOn(after, _today), isTrue);
      expect(planHasRecordOn(after, _today), isTrue);
    });

    test('a 주 N회 week met through actions closes the 같이 했어 offer', () {
      final plan = _plan(weeklyTarget: 1);
      expect(isTogetherDueToday(plan, _now), isTrue);
      final merged = plan.withActionRecords(
        _actions(const [_Rec(ActionRecordType.done, 0)]),
      );
      expect(merged.isWeeklyGoalMet(), isTrue);
      expect(isTogetherDueToday(merged, _now), isFalse);
      expect(merged.weeklyProgress()!.done, 1);
    });

    test('parses only documents that stand for a plan record', () {
      final date = Timestamp.fromDate(_day(-1));
      Map<String, dynamic> doc(Map<String, dynamic> extra) => {
        'planId': 'p1',
        'userId': _me,
        'type': 'done',
        'date': date,
        ...extra,
      };
      final ok = PlanActionRecord.fromMap(doc({'verifiedBy': _partner}), 'a');
      expect(ok!.type, ActionRecordType.done);
      expect(ok.verified, isTrue);
      expect(ok.date, _day(-1));
      expect(
        PlanActionRecord.fromMap(doc({'verifiedBy': ''}), 'a')!.verified,
        isFalse,
      );
      for (final type in ['skipped', 'rested', 'rescued']) {
        expect(
          PlanActionRecord.fromMap(doc({'type': type}), 'a')!.type.id,
          type,
        );
      }
      expect(PlanActionRecord.fromMap(doc({'type': 'cheer'}), 'a'), isNull);
      expect(PlanActionRecord.fromMap(doc({'date': null}), 'a'), isNull);
      expect(PlanActionRecord.fromMap(doc({'planId': ''}), 'a'), isNull);
      expect(PlanActionRecord.fromMap(doc({'userId': null}), 'a'), isNull);
    });
  });

  group('dual write: the arrays written back stay the stored ones', () {
    final plan = _plan(arrays: const [_Rec(ActionRecordType.done, -2)]);
    final merged = plan.withActionRecords(
      _actions(const [
        _Rec(ActionRecordType.done, -1, verified: true),
        _Rec(ActionRecordType.rested, -3),
      ]),
    );

    test('toMap writes the stored arrays, not the merged days', () {
      expect(_keys(merged.completedDates), _keys([_day(-2), _day(-1)]));
      final map = merged.toMap();
      List<DateTime> stored(String field) => [
        for (final t in map[field] as List) (t as Timestamp).toDate(),
      ];
      expect(stored('completedDates'), [_day(-2)]);
      expect(stored('verifiedDates'), isEmpty);
      expect(stored('restedDates'), isEmpty);
      expect(map, plan.toMap());
    });

    test('a copy keeps them; replacing a record list replaces them', () {
      expect(
        merged.copyWith(lastComment: 'x').toMap()['completedDates'],
        plan.toMap()['completedDates'],
      );
      final replaced = merged.copyWith(completedDates: [_day(-5)]);
      expect(replaced.storedRecordDates, isNull);
      expect(
        (replaced.toMap()['completedDates'] as List).single,
        Timestamp.fromDate(_day(-5)),
      );
    });

    test('persistedRecordDates of an unmerged plan are its fields', () {
      expect(plan.storedRecordDates, isNull);
      expect(plan.persistedRecordDates.completed, same(plan.completedDates));
      expect(merged.persistedRecordDates.completed, same(plan.completedDates));
    });
  });
}
