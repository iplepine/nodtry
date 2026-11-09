import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/presentation/cards/check_in_question.dart';
import 'package:nod_try/features/now/presentation/cards/now_card_rules.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';

/// Wednesday 2026-09-30, 09:00 (2026-09-28 is a Monday).
final _wed = DateTime(2026, 9, 30, 9);

Plan _weekly({List<DateTime> completed = const [], int target = 3}) => Plan(
  id: 'plan-1',
  userId: 'me',
  managerId: 'partner',
  startDate: DateTime(2026, 9, 28),
  endDate: DateTime(2026, 10, 25, 23, 59, 59),
  state: PlanState.active,
  createdAt: DateTime(2026, 9, 28),
  workoutType: 'running',
  completedDates: completed,
  items: [
    PlanItem(
      title: '러닝 30분',
      days: const [1, 2, 3, 4, 5, 6, 7],
      count: 7,
      notificationTime: NotificationTime.custom(21, 0),
    ),
  ],
  weeklyTarget: target,
);

void main() {
  late AppLocalizations ko;
  late AppLocalizations en;
  setUpAll(() async {
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('the hero shows every day of a weekly plan until recorded', () {
    final plan = _weekly(completed: [DateTime(2026, 9, 28, 19)]);
    expect(
      showsTodayCheckInHero(HomeCardState.nextAction, plan, now: _wed),
      isTrue,
    );
    expect(todayCheckInHeadline(ko, plan, now: _wed), '오늘 🏃 러닝 했어?');
    expect(todayCheckInWeeklyLine(ko, plan, now: _wed), '이번 주 1/3회');
    expect(todayCheckInWeeklyLine(en, plan, now: _wed), 'This week 1/3');
  });

  test('once the week is met: 목표 달성 headline, extra logging allowed', () {
    final plan = _weekly(
      target: 2,
      completed: [DateTime(2026, 9, 28, 19), DateTime(2026, 9, 29, 19)],
    );
    expect(todayCheckInHeadline(ko, plan, now: _wed), '이번 주 목표 달성 🎉');
    expect(todayCheckInWeeklyLine(ko, plan, now: _wed), '더 하면 연속 기록에 더해져요');
    // Still the check-in hero (photo / 사진 없이 했어 stay).
    expect(
      showsTodayCheckInHero(HomeCardState.nextAction, plan, now: _wed),
      isTrue,
    );
  });

  test('partner views read 주 3회 · 이번 주 2/3회', () {
    final plan = _weekly(
      completed: [DateTime(2026, 9, 28, 19), DateTime(2026, 9, 29, 19)],
    );
    expect(weeklyScheduleLabel(ko, plan, now: _wed), '주 3회 · 이번 주 2/3회');
    expect(
      weeklyScheduleLabel(en, plan, now: _wed),
      '3x a week · This week 2/3',
    );
    // Ended: just the target.
    expect(weeklyScheduleLabel(ko, plan, now: DateTime(2026, 11, 2)), '주 3회');
  });

  test('fixed-weekday plans keep their copy', () {
    final plan = Plan(
      id: 'p',
      userId: 'me',
      startDate: DateTime(2026, 9, 28),
      endDate: DateTime(2026, 10, 25, 23, 59, 59),
      state: PlanState.active,
      createdAt: DateTime(2026, 9, 28),
      workoutType: 'running',
      items: [
        PlanItem(title: '러닝', days: const [3], count: 1),
      ],
    );
    expect(todayCheckInHeadline(ko, plan, now: _wed), '오늘 🏃 러닝 했어?');
    expect(todayCheckInWeeklyLine(ko, plan, now: _wed), isNull);
    expect(weeklyScheduleLabel(ko, plan), isNull);
  });
}
