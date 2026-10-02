import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/domain/duo_stats.dart';
import 'package:nod_try/models/plan_model.dart';

// 2026-09-28 is a Monday.
DateTime d(int month, int day, [int hour = 0]) =>
    DateTime(2026, month, day, hour);

final mon = d(9, 28);
final tue = d(9, 29);
final wed = d(9, 30);
final thu = d(10, 1);
final fri = d(10, 2);
final sat = d(10, 3);
final sun = d(10, 4);

Plan plan({
  String id = 'p',
  String userId = 'a',
  String? managerId = 'b',
  required List<int> days,
  DateTime? start,
  DateTime? end,
  PlanState state = PlanState.active,
  List<DateTime> completed = const [],
  List<DateTime> rested = const [],
  List<DateTime> rescued = const [],
  List<DateTime> verified = const [],
  List<DateTime> skipped = const [],
  String? workoutType,
}) {
  final s = start ?? d(9, 1);
  return Plan(
    id: id,
    userId: userId,
    managerId: managerId,
    startDate: s,
    endDate: end ?? DateTime(s.year, s.month, s.day + 60, 23, 59, 59),
    state: state,
    items: [PlanItem(title: '운동', days: days, count: days.length)],
    createdAt: s,
    // Records are stored with a time of day, like the real app.
    completedDates: [
      for (final x in completed) x.add(const Duration(hours: 19)),
    ],
    restedDates: [for (final x in rested) x.add(const Duration(hours: 20))],
    rescuedDates: [for (final x in rescued) x.add(const Duration(hours: 9))],
    verifiedDates: [for (final x in verified) x.add(const Duration(hours: 21))],
    skippedDates: [for (final x in skipped) x.add(const Duration(hours: 22))],
    workoutType: workoutType,
  );
}

const monWedFri = [1, 3, 5];
const tueThu = [2, 4];

void main() {
  group('the spec example: A 월수금 + B 화목', () {
    final a = plan(
      id: 'a1',
      userId: 'a',
      managerId: 'b',
      days: monWedFri,
      start: mon,
      completed: [mon, wed, fri],
      workoutType: 'running',
    );
    final b = plan(
      id: 'b1',
      userId: 'b',
      managerId: 'a',
      days: tueThu,
      start: mon,
      completed: [tue, thu],
      workoutType: 'gym',
    );

    test('both done on their own days → a 5-day streak', () {
      final stats = computeDuoStats(
        myPlans: [a],
        partnerPlans: [b],
        today: fri.add(const Duration(hours: 20)),
      );
      expect(stats.streak, 5);
      expect(stats.streakStart, mon);
      expect(stats.todayIsDuoDone, isTrue);
      expect(stats.today.me.status, DuoDayStatus.done);
      expect(stats.today.partner.status, DuoDayStatus.off);
      expect(stats.weekDuoDays, 5);
      expect(stats.week.map((day) => day.isDuoDay).toList(), [
        true,
        true,
        true,
        true,
        true,
        false,
        false,
      ]);
    });

    test('the weekend is off for both and does not break the streak', () {
      final stats = computeDuoStats(
        myPlans: [a],
        partnerPlans: [b],
        today: sun.add(const Duration(hours: 10)),
      );
      expect(stats.streak, 5);
      expect(stats.todayIsDuoDone, isFalse);
      expect(stats.today.isOffForBoth, isTrue);
    });

    test('the streak continues into the next week', () {
      final nextMon = d(10, 5);
      final stats = computeDuoStats(
        myPlans: [
          plan(
            id: 'a1',
            userId: 'a',
            days: monWedFri,
            start: mon,
            completed: [mon, wed, fri, nextMon],
          ),
        ],
        partnerPlans: [b],
        today: nextMon.add(const Duration(hours: 21)),
      );
      expect(stats.streak, 6);
      expect(stats.week.first.date, nextMon);
    });

    test('it is the same seen from the other side', () {
      final stats = computeDuoStats(
        myPlans: [b],
        partnerPlans: [a],
        today: fri.add(const Duration(hours: 20)),
      );
      expect(stats.streak, 5);
      expect(stats.today.me.status, DuoDayStatus.off);
      expect(stats.today.partner.status, DuoDayStatus.done);
    });
  });

  group('today', () {
    test('in progress never breaks the streak', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: monWedFri, start: mon, completed: [mon, wed]),
        ],
        partnerPlans: [
          plan(userId: 'b', days: tueThu, start: mon, completed: [tue, thu]),
        ],
        today: fri.add(const Duration(hours: 8)),
      );
      expect(stats.today.me.status, DuoDayStatus.pending);
      expect(stats.todayIsDuoDone, isFalse);
      expect(stats.streak, 4); // Mon–Thu
    });

    test('counts once it becomes a duo day', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: monWedFri, start: mon, completed: [mon, wed, fri]),
        ],
        partnerPlans: [
          plan(userId: 'b', days: tueThu, start: mon, completed: [tue, thu]),
        ],
        today: fri.add(const Duration(hours: 8)),
      );
      expect(stats.todayIsDuoDone, isTrue);
      expect(stats.streak, 5);
    });

    test('waits for the partner when both are scheduled today', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [5], start: mon, completed: [fri]),
        ],
        partnerPlans: [
          plan(userId: 'b', days: [5], start: mon),
        ],
        today: fri.add(const Duration(hours: 12)),
      );
      expect(stats.today.me.status, DuoDayStatus.done);
      expect(stats.today.partner.status, DuoDayStatus.pending);
      expect(stats.todayIsDuoDone, isFalse);
      expect(stats.streak, 0);
    });
  });

  group('misses', () {
    test('a past scheduled day without a record ends the streak', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(
            days: monWedFri,
            start: mon,
            completed: [mon, fri],
          ), // Wed missed
        ],
        partnerPlans: [
          plan(userId: 'b', days: tueThu, start: mon, completed: [tue, thu]),
        ],
        today: fri.add(const Duration(hours: 22)),
      );
      expect(stats.week[2].me.status, DuoDayStatus.missed);
      expect(stats.week[2].isDuoDay, isFalse);
      expect(stats.streak, 2); // Thu, Fri
      expect(stats.streakStart, thu);
    });

    test("the partner's miss breaks it too", () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: monWedFri, start: mon, completed: [mon, wed, fri]),
        ],
        partnerPlans: [
          plan(userId: 'b', days: tueThu, start: mon, completed: [tue]),
        ],
        today: fri.add(const Duration(hours: 22)),
      );
      expect(stats.week[3].partner.status, DuoDayStatus.missed);
      expect(stats.streak, 1);
    });

    test('a skip is a miss', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1, 2], start: mon, completed: [mon], skipped: [tue]),
        ],
        partnerPlans: const [],
        today: tue.add(const Duration(days: 1, hours: 9)),
      );
      expect(stats.week[1].me.status, DuoDayStatus.missed);
      expect(stats.streak, 0);
    });

    test('a done day with a miss on another promise is still a miss', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(id: 'x', days: [1], start: mon, completed: [mon]),
          plan(id: 'y', days: [1], start: mon),
        ],
        partnerPlans: const [],
        today: tue.add(const Duration(hours: 9)),
      );
      expect(stats.week[0].me.status, DuoDayStatus.missed);
      expect(stats.week[0].me.doneWorkoutTypes, hasLength(1));
      expect(stats.streak, 0);
    });
  });

  group('neutral and rest days', () {
    test('days off for both are skipped, not counted', () {
      final lastMon = d(9, 21);
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1], start: lastMon, completed: [lastMon, mon]),
        ],
        partnerPlans: [
          plan(
            userId: 'b',
            days: [1],
            start: lastMon,
            completed: [lastMon, mon],
          ),
        ],
        today: thu.add(const Duration(hours: 9)),
      );
      expect(stats.streak, 2);
      expect(stats.streakStart, lastMon);
    });

    test('a rest pass is no miss, but a rest-only day is not a duo day', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(
            days: monWedFri,
            start: mon,
            completed: [mon, fri],
            rested: [wed],
          ),
        ],
        partnerPlans: [
          plan(userId: 'b', days: tueThu, start: mon, completed: [tue, thu]),
        ],
        today: fri.add(const Duration(hours: 22)),
      );
      expect(stats.week[2].me.status, DuoDayStatus.rested);
      expect(stats.week[2].isDuoDay, isFalse);
      // Mon, Tue, Thu, Fri count; Wed (rest only) is skipped.
      expect(stats.streak, 4);
    });

    test('a rest pass on one side with the other done is a duo day', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [3], start: mon, rested: [wed]),
        ],
        partnerPlans: [
          plan(userId: 'b', days: [3], start: mon, completed: [wed]),
        ],
        today: thu.add(const Duration(hours: 9)),
      );
      expect(stats.week[2].isDuoDay, isTrue);
      expect(stats.streak, 1);
    });

    test('a rescued day is covered', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1, 2], start: mon, completed: [tue], rescued: [mon]),
        ],
        partnerPlans: const [],
        today: tue.add(const Duration(hours: 22)),
      );
      expect(stats.week[0].me.status, DuoDayStatus.rested);
      expect(stats.streak, 1);
    });

    test('a workout on an unscheduled day still counts as done', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1], start: mon, completed: [mon, tue]),
        ],
        partnerPlans: const [],
        today: tue.add(const Duration(hours: 22)),
      );
      expect(stats.week[1].me.status, DuoDayStatus.done);
      expect(stats.streak, 2);
    });
  });

  group('인정 is a bonus', () {
    final mine = plan(
      days: monWedFri,
      start: mon,
      managerId: 'b',
      completed: [mon, wed],
      verified: [mon],
    );

    test('a verified done day carries the ❤️ flag', () {
      final stats = computeDuoStats(
        myPlans: [mine],
        partnerPlans: const [],
        today: wed.add(const Duration(hours: 22)),
      );
      expect(stats.week[0].me.verification, DuoVerification.verified);
      expect(stats.week[0].verified, isTrue);
    });

    test('pending verification shows as waiting and still counts', () {
      final stats = computeDuoStats(
        myPlans: [mine],
        partnerPlans: const [],
        today: wed.add(const Duration(hours: 22)),
      );
      expect(stats.today.me.status, DuoDayStatus.done);
      expect(stats.today.me.verification, DuoVerification.waiting);
      expect(stats.today.isDuoDay, isTrue);
      expect(stats.today.verified, isFalse);
      expect(stats.streak, 2);
    });

    test('a solo promise (no partner to acknowledge) is never waiting', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1], start: mon, managerId: null, completed: [mon]),
        ],
        partnerPlans: const [],
        today: mon.add(const Duration(hours: 20)),
      );
      expect(stats.today.me.verification, DuoVerification.none);
    });

    test('a day is verified only when everyone who worked out got 인정', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1], start: mon, completed: [mon], verified: [mon]),
        ],
        partnerPlans: [
          plan(
            userId: 'b',
            managerId: 'a',
            days: [1],
            start: mon,
            completed: [mon],
          ),
        ],
        today: mon.add(const Duration(hours: 23)),
      );
      expect(stats.today.isDuoDay, isTrue);
      expect(stats.today.partner.verification, DuoVerification.waiting);
      expect(stats.today.verified, isFalse);
    });
  });

  group('which plans make a day scheduled', () {
    test('days outside the period are off', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1, 2, 3, 4, 5, 6, 7], start: wed, completed: [wed]),
        ],
        partnerPlans: const [],
        today: wed.add(const Duration(hours: 20)),
      );
      expect(stats.week[0].me.status, DuoDayStatus.off);
      expect(stats.week[1].me.status, DuoDayStatus.off);
      expect(stats.streak, 1);
    });

    test('a stopped plan never makes a miss, but its records count', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(
            days: [1, 2, 3],
            start: mon,
            state: PlanState.stopped,
            completed: [mon],
          ),
        ],
        partnerPlans: const [],
        today: wed.add(const Duration(hours: 22)),
      );
      expect(stats.week[0].me.status, DuoDayStatus.done);
      expect(stats.week[1].me.status, DuoDayStatus.off);
      expect(stats.streak, 1);
    });

    test('pending-approval and rejected plans are not scheduled', () {
      for (final state in [
        PlanState.pendingApproval,
        PlanState.rejected,
        PlanState.draft,
      ]) {
        final stats = computeDuoStats(
          myPlans: [
            plan(days: [1, 2], start: mon, state: state),
          ],
          partnerPlans: const [],
          today: tue.add(const Duration(hours: 22)),
        );
        expect(stats.week[0].me.status, DuoDayStatus.off, reason: '$state');
      }
    });

    test('a completed plan still counts its scheduled days', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(
            days: [1, 2],
            start: d(9, 1),
            end: DateTime(2026, 9, 29, 23, 59, 59),
            state: PlanState.completed,
            completed: [tue],
          ),
        ],
        partnerPlans: const [],
        today: wed.add(const Duration(hours: 9)),
      );
      expect(stats.week[0].me.status, DuoDayStatus.missed);
      expect(stats.week[1].me.status, DuoDayStatus.done);
      expect(stats.week[2].me.status, DuoDayStatus.off); // after the end
      expect(stats.streak, 1);
    });

    test('an old plan saved without days means every day', () {
      final p = Plan(
        id: 'legacy',
        userId: 'a',
        startDate: mon,
        endDate: d(10, 25),
        state: PlanState.active,
        items: [PlanItem(title: '옛 약속', days: const [], count: 0)],
        createdAt: mon,
      );
      final day = duoPersonDayOf([p], tue, today: wed);
      expect(day.status, DuoDayStatus.missed);
    });
  });

  group('the week', () {
    test('runs Monday to Sunday with future days upcoming or off', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: monWedFri, start: mon, completed: [mon]),
        ],
        partnerPlans: [plan(userId: 'b', days: tueThu, start: mon)],
        today: tue.add(const Duration(hours: 9)),
      );
      expect(stats.week.map((x) => x.date).toList(), [
        mon,
        tue,
        wed,
        thu,
        fri,
        sat,
        sun,
      ]);
      expect(stats.week[1].isToday, isTrue);
      expect(stats.week[1].partner.status, DuoDayStatus.pending);
      expect(stats.week[2].me.status, DuoDayStatus.upcoming);
      expect(stats.week[2].partner.status, DuoDayStatus.off);
      expect(stats.week[2].isFuture, isTrue);
      expect(stats.week[5].isOffForBoth, isTrue);
    });

    test('keeps the done workout types for the share card', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(
            id: 'r',
            days: [1],
            start: mon,
            completed: [mon],
            workoutType: 'running',
          ),
          plan(id: 'l', days: [1], start: mon, completed: [mon]),
        ],
        partnerPlans: const [],
        today: mon.add(const Duration(hours: 22)),
      );
      expect(stats.today.me.doneWorkoutTypes, ['running', null]);
    });
  });

  group('edge cases', () {
    test('no plans: nothing to count', () {
      final stats = computeDuoStats(
        myPlans: const [],
        partnerPlans: const [],
        today: wed,
      );
      expect(stats.streak, 0);
      expect(stats.streakStart, isNull);
      expect(stats.todayIsDuoDone, isFalse);
      expect(stats.week, hasLength(7));
    });

    test('without a partner the partner side is off', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1], start: mon, completed: [mon]),
        ],
        partnerPlans: [
          plan(userId: 'b', days: [1], start: mon),
        ],
        today: mon.add(const Duration(hours: 22)),
        hasPartner: false,
      );
      expect(stats.hasPartner, isFalse);
      expect(stats.today.partner.status, DuoDayStatus.off);
      expect(stats.streak, 1);
    });

    test('the look-back is bounded', () {
      final start = d(1, 5); // a Monday, long ago
      final mondays = <DateTime>[
        for (
          var x = start;
          !x.isAfter(mon);
          x = DateTime(x.year, x.month, x.day + 7)
        )
          x,
      ];
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1], start: start, completed: mondays),
        ],
        partnerPlans: const [],
        today: mon.add(const Duration(hours: 22)),
        lookbackDays: 14,
      );
      expect(stats.streak, 3); // today, 7 and 14 days ago
    });

    test('the streak never reaches before the first plan', () {
      final stats = computeDuoStats(
        myPlans: [
          plan(days: [1, 2, 3, 4, 5, 6, 7], start: tue, completed: [tue, wed]),
        ],
        partnerPlans: const [],
        today: wed.add(const Duration(hours: 22)),
      );
      expect(stats.streak, 2);
      expect(stats.streakStart, tue);
    });
  });

  test('countVerificationsReceived counts one 인정 per day per plan', () {
    expect(
      countVerificationsReceived([
        plan(id: 'x', days: [1], verified: [mon, tue]),
        plan(
          id: 'y',
          days: [1],
          verified: [mon, mon.add(const Duration(hours: 1))],
        ),
      ]),
      3,
    );
    expect(countVerificationsReceived(const []), 0);
  });

  group('only days as a couple count (linkedSince)', () {
    // The inviter sets a promise and works out Mon–Wed alone (spec §4.1: the
    // promise comes first); the partner, with no plans, links on Thursday.
    final inviter = plan(
      id: 'a1',
      userId: 'a',
      managerId: 'b',
      days: [1, 2, 3, 4, 5, 6, 7],
      start: mon,
      completed: [mon, tue, wed],
    );

    test('solo days before the link are not 둘운완 days', () {
      final stats = computeDuoStats(
        myPlans: [inviter],
        partnerPlans: const [],
        today: thu.add(const Duration(hours: 9)),
        linkedSince: thu.add(const Duration(hours: 8, minutes: 30)),
      );
      expect(stats.streak, 0);
      expect(stats.streakStart, isNull);
      // The week view: Mon–Wed are mine, not ours.
      expect(stats.week[0].isDuoDay, isFalse);
      expect(stats.week[0].beforeLink, isTrue);
      expect(stats.week[0].me.isDone, isTrue);
      expect(stats.week[3].beforeLink, isFalse);
    });

    test('the first day as a couple is day 1', () {
      final recordedThu = plan(
        id: 'a1',
        userId: 'a',
        managerId: 'b',
        days: [1, 2, 3, 4, 5, 6, 7],
        start: mon,
        completed: [mon, tue, wed, thu],
      );
      final stats = computeDuoStats(
        myPlans: [recordedThu],
        partnerPlans: const [],
        today: thu.add(const Duration(hours: 21)),
        linkedSince: thu.add(const Duration(hours: 8)),
      );
      expect(stats.streak, 1);
      expect(stats.streakStart, thu);
      expect(stats.todayIsDuoDone, isTrue);
    });

    test('without the link date the old rule applies (inflated)', () {
      final stats = computeDuoStats(
        myPlans: [inviter],
        partnerPlans: const [],
        today: thu.add(const Duration(hours: 9)),
      );
      expect(stats.streak, 3);
    });

    test('a link date in the future (clock skew) is today', () {
      final stats = computeDuoStats(
        myPlans: [inviter],
        partnerPlans: const [],
        today: wed.add(const Duration(hours: 21)),
        linkedSince: fri,
      );
      expect(stats.streak, 1);
      expect(stats.streakStart, wed);
    });

    test('a solo user keeps their own streak', () {
      final stats = computeDuoStats(
        myPlans: [inviter],
        partnerPlans: const [],
        today: thu.add(const Duration(hours: 9)),
        hasPartner: false,
        linkedSince: thu,
      );
      expect(stats.streak, 3);
    });
  });
}
