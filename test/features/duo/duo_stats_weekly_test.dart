import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/domain/duo_stats.dart';
import 'package:nod_try/features/widget_sync/domain/duo_widget_snapshot.dart';
import 'package:nod_try/l10n/app_localizations_ko.dart';
import 'package:nod_try/models/plan_model.dart';

// 2026-09-28 is a Monday; 9/21–9/27 the week before.
DateTime d(int month, int day) => DateTime(2026, month, day);

Plan weekly({
  String id = 'w',
  String userId = 'me',
  int target = 3,
  DateTime? start,
  List<DateTime> completed = const [],
  List<DateTime> rested = const [],
  List<DateTime> skipped = const [],
}) {
  final s = start ?? d(9, 21);
  return Plan(
    id: id,
    userId: userId,
    managerId: userId == 'me' ? 'partner' : 'me',
    startDate: s,
    endDate: DateTime(s.year, s.month, s.day + 27, 23, 59, 59),
    state: PlanState.active,
    items: [
      PlanItem(title: '러닝', days: const [1, 2, 3, 4, 5, 6, 7], count: 7),
    ],
    createdAt: s,
    completedDates: [
      for (final x in completed) x.add(const Duration(hours: 19)),
    ],
    restedDates: [for (final x in rested) x.add(const Duration(hours: 20))],
    skippedDates: [for (final x in skipped) x.add(const Duration(hours: 22))],
    weeklyTarget: target,
    workoutType: 'running',
  );
}

Plan fixed({
  String userId = 'partner',
  required List<int> days,
  List<DateTime> completed = const [],
}) {
  final s = d(9, 21);
  return Plan(
    id: 'f',
    userId: userId,
    managerId: 'me',
    startDate: s,
    endDate: DateTime(s.year, s.month, s.day + 27, 23, 59, 59),
    state: PlanState.active,
    items: [PlanItem(title: '요가', days: days, count: days.length)],
    createdAt: s,
    completedDates: [
      for (final x in completed) x.add(const Duration(hours: 8)),
    ],
  );
}

void main() {
  group('a weekly plan in the 둘운완 stats', () {
    test('unlogged days are neutral while the week can still be met', () {
      // 주 3회, nothing logged; today is Wednesday.
      final plans = [weekly(start: d(9, 28))];
      DuoDayStatus at(DateTime day) =>
          duoPersonDayOf(plans, day, today: d(9, 30)).status;
      expect(at(d(9, 28)), DuoDayStatus.off);
      expect(at(d(9, 29)), DuoDayStatus.off);
      expect(at(d(9, 30)), DuoDayStatus.off); // today, not must-do
      expect(at(d(10, 1)), DuoDayStatus.off);
      // Predicted must-do days if nothing else is logged.
      expect(at(d(10, 2)), DuoDayStatus.upcoming);
      expect(at(d(10, 4)), DuoDayStatus.upcoming);
    });

    test('done days are duo days and neutral days do not break the streak', () {
      // 주 2회 done Tue + Thu; last week (from 9/21) nothing, so its Sat/Sun
      // were must-do misses. Partner: no plans (off every day).
      final stats = computeDuoStats(
        myPlans: [
          weekly(target: 2, completed: [d(9, 29), d(10, 1)]),
        ],
        partnerPlans: const [],
        today: d(10, 4),
      );
      expect(stats.today.me.status, DuoDayStatus.off);
      expect(stats.week[1].isDuoDay, isTrue); // Tue
      expect(stats.week[3].isDuoDay, isTrue); // Thu
      expect(stats.week[4].me.status, DuoDayStatus.off); // Fri: neutral
      expect(stats.streak, 2);
      expect(stats.streakStart, d(9, 29));
      expect(
        duoPersonDayOf(
          [
            weekly(target: 2, completed: [d(9, 29)]),
          ],
          d(9, 27),
          today: d(10, 4),
        ).status,
        DuoDayStatus.missed,
      );
    });

    test('a missed must-do day ends the streak', () {
      // 주 3회, only Thursday done: Sat is must-do and missed; today Sunday.
      final plans = [
        weekly(start: d(9, 28), completed: [d(10, 1)]),
      ];
      final stats = computeDuoStats(
        myPlans: plans,
        partnerPlans: const [],
        today: d(10, 4),
      );
      expect(stats.week[5].me.status, DuoDayStatus.missed); // Sat
      expect(stats.week[4].me.status, DuoDayStatus.off); // Fri
      expect(stats.today.me.status, DuoDayStatus.pending); // Sun, must-do
      expect(stats.streak, 0);
    });

    test('a rest pass on a must-do day keeps the run going', () {
      final stats = computeDuoStats(
        myPlans: [
          weekly(
            target: 2,
            start: d(9, 28),
            completed: [d(10, 1)],
            rested: [d(10, 4)],
          ),
        ],
        partnerPlans: const [],
        today: d(10, 5),
      );
      expect(
        duoPersonDayOf(
          [
            weekly(
              target: 2,
              start: d(9, 28),
              completed: [d(10, 1)],
              rested: [d(10, 4)],
            ),
          ],
          d(10, 4),
          today: d(10, 5),
        ).status,
        DuoDayStatus.rested,
      );
      expect(stats.streak, 1); // Thu; Sun rested is skipped, not a break
    });

    test('a skip on a neutral day is not a miss, on a must-do day it is', () {
      final neutral = weekly(start: d(9, 28), skipped: [d(9, 28)]);
      expect(
        duoPersonDayOf([neutral], d(9, 28), today: d(9, 30)).status,
        DuoDayStatus.off,
      );
      final mustDo = weekly(start: d(9, 28), skipped: [d(10, 2)]);
      expect(
        duoPersonDayOf([mustDo], d(10, 2), today: d(10, 3)).status,
        DuoDayStatus.missed,
      );
    });

    test('weekly me + fixed partner: duo days need both settled', () {
      final stats = computeDuoStats(
        myPlans: [
          weekly(target: 1, start: d(9, 28), completed: [d(9, 29)]),
        ],
        partnerPlans: [
          fixed(days: const [1, 3], completed: [d(9, 28), d(9, 30)]),
        ],
        today: d(9, 30),
      );
      expect(stats.week[0].isDuoDay, isTrue); // partner done, me neutral
      expect(stats.week[1].isDuoDay, isTrue); // me done, partner off
      expect(stats.today.isDuoDay, isTrue);
      expect(stats.streak, 3);
    });
  });

  group('home widget snapshot', () {
    test('an open weekly week reads 이번 주 1/3회 instead of 쉬는 날', () {
      final l10n = AppLocalizationsKo();
      final mine = [
        weekly(start: d(9, 28), completed: [d(9, 28)]),
      ];
      final partner = [
        weekly(
          id: 'p',
          userId: 'partner',
          target: 1,
          start: d(9, 28),
          completed: [d(9, 29)],
        ),
      ];
      final stats = computeDuoStats(
        myPlans: mine,
        partnerPlans: partner,
        today: d(9, 30),
      );
      final snapshot = buildDuoWidgetSnapshot(
        stats: stats,
        myPlans: mine,
        partnerPlans: partner,
        partnerName: '짝꿍',
        l10n: l10n,
      )!;
      expect(snapshot.me.status, DuoWidgetPersonStatus.pending);
      expect(snapshot.me.statusText, '이번 주 1/3회');
      // The partner already met 주 1회: a plain day off.
      expect(snapshot.partner.status, DuoWidgetPersonStatus.notScheduled);
      expect(snapshot.partner.statusText, l10n.homeWidgetStatusOff);
    });
  });
}
