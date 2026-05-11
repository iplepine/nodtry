import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/plan_model.dart';

Plan _plan({
  required DateTime startDate,
  required List<int> days,
  int durationDays = 28,
  List<DateTime> completedDates = const [],
}) {
  return Plan(
    id: 'plan-test',
    userId: 'user-test',
    managerId: 'manager-test',
    startDate: startDate,
    endDate: startDate.add(Duration(days: durationDays - 1)),
    state: PlanState.active,
    items: [PlanItem(title: '공부하기', days: days, count: 1)],
    createdAt: startDate,
    completedDates: completedDates,
  );
}

void main() {
  group('Plan promise day bounds', () {
    test('counts selected weekdays inside the inclusive plan period', () {
      final plan = _plan(
        startDate: DateTime(2026, 1, 5),
        days: const [DateTime.monday, DateTime.wednesday, DateTime.friday],
      );

      expect(plan.calendarDurationDays, 28);
      expect(plan.scheduledDayCount, 12);
      expect(plan.promiseTargetDaysLimit, 12);
    });

    test('uses all calendar days for daily plans', () {
      final plan = _plan(
        startDate: DateTime(2026, 1, 5),
        days: const [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
      );

      expect(plan.calendarDurationDays, 28);
      expect(plan.scheduledDayCount, 28);
      expect(plan.promiseTargetDaysLimit, 28);
    });

    test('falls back to duration when weekday data is missing', () {
      final plan = _plan(startDate: DateTime(2026, 1, 5), days: const []);

      expect(plan.calendarDurationDays, 28);
      expect(plan.scheduledDayCount, 28);
      expect(plan.promiseTargetDaysLimit, 28);
    });

    test('limits reward target to current successes plus remaining days', () {
      final startDate = DateTime(2026, 1, 1);
      final plan = _plan(
        startDate: startDate,
        durationDays: 30,
        days: const [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
        completedDates: List.generate(
          5,
          (index) => startDate.add(Duration(days: index)),
        ),
      );

      final asOf = startDate.add(const Duration(days: 20));

      expect(plan.completedDayCount(asOf: asOf), 5);
      expect(plan.failedDayCount(asOf: asOf), 15);
      expect(plan.remainingScheduledDayCount(asOf: asOf), 10);
      expect(plan.rewardTargetDaysLimit(asOf: asOf), 15);
      expect(plan.penaltyTargetDaysLimit(asOf: asOf), 25);
    });
  });
}
