import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/domain/duo_recap.dart';
import 'package:nod_try/features/duo/domain/duo_stats.dart';
import 'package:nod_try/models/plan_model.dart';

// November 2026: the 1st is a Sunday, the 2nd a Monday.
DateTime nov(int day) => DateTime(2026, 11, day);

Plan plan({
  String id = 'p',
  String userId = 'a',
  String? managerId = 'b',
  required List<int> days,
  DateTime? start,
  DateTime? end,
  List<DateTime> completed = const [],
  List<DateTime> rested = const [],
  String? workoutType,
}) {
  final s = start ?? DateTime(2026, 10, 1);
  return Plan(
    id: id,
    userId: userId,
    managerId: managerId,
    startDate: s,
    endDate: end ?? DateTime(2026, 12, 31, 23, 59, 59),
    state: PlanState.active,
    items: [PlanItem(title: '운동', days: days, count: days.length)],
    createdAt: s,
    completedDates: [
      for (final x in completed) x.add(const Duration(hours: 19)),
    ],
    restedDates: [for (final x in rested) x.add(const Duration(hours: 20))],
    workoutType: workoutType,
  );
}

const monWedFri = [1, 3, 5];
const everyDay = [1, 2, 3, 4, 5, 6, 7];

void main() {
  group('computeDuoDays', () {
    test('covers the range inclusively, in order', () {
      final days = computeDuoDays(
        myPlans: const [],
        partnerPlans: const [],
        from: nov(1),
        to: nov(30),
        today: nov(21),
      );
      expect(days, hasLength(30));
      expect(days.first.date, nov(1));
      expect(days.last.date, nov(30));
      expect(days[20].isToday, isTrue);
      expect(days.where((d) => d.isToday), hasLength(1));
    });

    test('is empty when the range is backwards', () {
      expect(
        computeDuoDays(
          myPlans: const [],
          partnerPlans: const [],
          from: nov(5),
          to: nov(4),
          today: nov(21),
        ),
        isEmpty,
      );
    });
  });

  group('a couple', () {
    // Me 월수금, partner 월수금. Week of the 2nd: both did Mon and Wed; on
    // Fri only I did (the partner missed). Week of the 9th: both all three.
    final mine = plan(
      id: 'a1',
      days: monWedFri,
      completed: [nov(2), nov(4), nov(6), nov(9), nov(11), nov(13)],
      workoutType: 'running',
    );
    final theirs = plan(
      id: 'b1',
      userId: 'b',
      managerId: 'a',
      days: monWedFri,
      completed: [nov(2), nov(4), nov(9), nov(11), nov(13)],
      workoutType: 'yoga',
    );

    DuoRecap recap({DateTime? today, DateTime? linkedSince}) => computeDuoRecap(
      myPlans: [mine],
      partnerPlans: [theirs],
      month: nov(15),
      today: today ?? nov(14),
      linkedSince: linkedSince,
    );

    test('counts duo days, each person and the top workouts', () {
      final r = recap();
      expect(r.month, nov(1));
      expect(r.days, hasLength(30));
      expect(r.hasPartner, isTrue);
      expect(r.isCurrentMonth, isTrue);
      expect(r.duoDays, 5);
      expect(r.headlineDays, 5);
      expect(r.myDoneDays, 6);
      expect(r.partnerDoneDays, 5);
      expect(r.myTopWorkout, 'running');
      expect(r.partnerTopWorkout, 'yoga');
      expect(r.isEmpty, isFalse);
    });

    test('a miss ends the run; off days in between are skipped', () {
      // 2, 4 are duo days; the 6th has the partner's miss; then 9, 11, 13.
      expect(recap().bestStreak, 3);
    });

    test('days after today are not counted', () {
      final r = recap(today: nov(4));
      expect(r.duoDays, 2);
      expect(r.myDoneDays, 2);
      expect(r.bestStreak, 2);
    });

    test('a finished month is not the current one', () {
      final r = recap(today: DateTime(2026, 12, 3));
      expect(r.isCurrentMonth, isFalse);
      expect(r.duoDays, 5);
    });

    test('days before the couple linked are not duo days', () {
      final r = recap(linkedSince: nov(9));
      expect(r.duoDays, 3);
      expect(r.partnerDoneDays, 3, reason: 'theirs from before the link');
      expect(r.myDoneDays, 6, reason: 'mine are still mine');
      expect(r.bestStreak, 3);
    });

    test('today still open does not end the run', () {
      // Monday the 16th, nothing recorded yet.
      final r = recap(today: nov(16));
      expect(r.bestStreak, 3);
      expect(r.duoDays, 5);
    });
  });

  group('solo', () {
    final mine = plan(
      days: everyDay,
      managerId: null,
      start: nov(1),
      completed: [nov(1), nov(2), nov(3), nov(5), nov(6)],
      workoutType: 'gym',
    );

    test('the headline is my workout days; a missed day ends the run', () {
      final r = computeDuoRecap(
        myPlans: [mine],
        partnerPlans: const [],
        month: nov(1),
        today: nov(7),
        hasPartner: false,
      );
      expect(r.hasPartner, isFalse);
      expect(r.duoDays, 0);
      expect(r.headlineDays, 5);
      expect(r.partnerDoneDays, 0);
      expect(r.bestStreak, 3, reason: 'the 4th was missed');
      expect(r.myTopWorkout, 'gym');
      expect(r.partnerTopWorkout, isNull);
    });

    test('nothing recorded is empty', () {
      final r = computeDuoRecap(
        myPlans: [plan(days: everyDay, managerId: null, start: nov(1))],
        partnerPlans: const [],
        month: nov(1),
        today: nov(7),
        hasPartner: false,
      );
      expect(r.isEmpty, isTrue);
      expect(r.bestStreak, 0);
    });
  });

  test('the top workout is the one done on the most days', () {
    final r = computeDuoRecap(
      myPlans: [
        plan(
          id: 'run',
          days: const [7, 1],
          managerId: null,
          start: nov(1),
          completed: [nov(1), nov(2)],
          workoutType: 'running',
        ),
        plan(
          id: 'gym',
          days: const [1, 2, 3],
          managerId: null,
          start: nov(1),
          completed: [nov(2), nov(3), nov(4)],
          workoutType: 'gym',
        ),
      ],
      partnerPlans: const [],
      month: nov(1),
      today: nov(4),
      hasPartner: false,
    );
    expect(r.myTopWorkout, 'gym');
  });

  group('recapMonthsOf', () {
    test('this month back to my first plan, newest first', () {
      final months = recapMonthsOf([
        plan(days: monWedFri, start: DateTime(2026, 9, 20)),
      ], today: nov(21));
      expect(months, [
        DateTime(2026, 11),
        DateTime(2026, 10),
        DateTime(2026, 9),
      ]);
    });

    test('at most a year, and this month without plans', () {
      expect(
        recapMonthsOf([
          plan(days: monWedFri, start: DateTime(2024, 1, 1)),
        ], today: nov(21)),
        hasLength(kDuoRecapMonthsBack),
      );
      expect(recapMonthsOf(const [], today: nov(21)), [DateTime(2026, 11)]);
    });

    test('January goes back into the year before', () {
      final months = recapMonthsOf([
        plan(days: monWedFri, start: DateTime(2026, 11, 20)),
      ], today: DateTime(2027, 1, 3));
      expect(months, [
        DateTime(2027, 1),
        DateTime(2026, 12),
        DateTime(2026, 11),
      ]);
    });
  });

  group('shouldOfferRecap', () {
    DuoRecap last({required int duoDays}) => DuoRecap(
      month: DateTime(2026, 11),
      days: const [],
      hasPartner: true,
      isCurrentMonth: false,
      duoDays: duoDays,
      myDoneDays: duoDays,
      partnerDoneDays: duoDays,
      bestStreak: duoDays,
    );

    test('on the first days of the next month, once', () {
      expect(
        shouldOfferRecap(
          lastMonth: last(duoDays: 3),
          today: DateTime(2026, 12, 1),
          offeredMonthKey: null,
        ),
        isTrue,
      );
      expect(
        shouldOfferRecap(
          lastMonth: last(duoDays: 3),
          today: DateTime(2026, 12, 7),
          offeredMonthKey: '2026-10',
        ),
        isTrue,
      );
      expect(
        shouldOfferRecap(
          lastMonth: last(duoDays: 3),
          today: DateTime(2026, 12, 2),
          offeredMonthKey: '2026-11',
        ),
        isFalse,
      );
    });

    test('not later in the month, and not for a thin month', () {
      expect(
        shouldOfferRecap(
          lastMonth: last(duoDays: 10),
          today: DateTime(2026, 12, 8),
          offeredMonthKey: null,
        ),
        isFalse,
      );
      expect(
        shouldOfferRecap(
          lastMonth: last(duoDays: 2),
          today: DateTime(2026, 12, 1),
          offeredMonthKey: null,
        ),
        isFalse,
      );
    });

    test('only for the month right before today', () {
      expect(
        shouldOfferRecap(
          lastMonth: last(duoDays: 10),
          today: DateTime(2027, 1, 2),
          offeredMonthKey: null,
        ),
        isFalse,
      );
    });
  });

  test('recapMonthKey pads the month', () {
    expect(recapMonthKey(DateTime(2026, 3)), '2026-03');
    expect(
      recapMonthOf(DateTime(2027, 1, 15), monthsAgo: 1),
      DateTime(2026, 12),
    );
  });
}
