import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/services/notification_service.dart';
import 'package:nod_try/utils/context_free_l10n.dart';

class _FakePlanReminderScheduler implements PlanReminderScheduler {
  final List<String> calls = [];
  int? canceledPlanId;
  int? scheduledPlanId;
  String? scheduledPlanIdentifier;
  String? scheduledTitle;
  String? scheduledBody;
  int? scheduledHour;
  int? scheduledMinute;
  List<int>? scheduledDays;
  bool? scheduledSkipToday;
  int? scheduledIntervalHours;
  int? scheduledStartHour;
  int? scheduledEndHour;

  @override
  Future<void> cancelPlanReminders(int planId) async {
    canceledPlanId = planId;
    calls.add('cancel:$planId');
  }

  @override
  Future<void> requestPermissions() async {
    calls.add('permissions');
  }

  @override
  Future<void> schedulePlanReminder({
    required int planId,
    String? planIdentifier,
    required String title,
    String? body,
    required int hour,
    required int minute,
    required List<int> days,
    bool skipToday = false,
    int intervalHours = 0,
    int startHour = 0,
    int endHour = 0,
  }) async {
    scheduledPlanId = planId;
    scheduledPlanIdentifier = planIdentifier;
    scheduledTitle = title;
    scheduledBody = body;
    scheduledHour = hour;
    scheduledMinute = minute;
    scheduledDays = days;
    scheduledSkipToday = skipToday;
    scheduledIntervalHours = intervalHours;
    scheduledStartHour = startHour;
    scheduledEndHour = endHour;
    calls.add('schedule:$planId');
  }
}

Plan _buildPlan({
  required String id,
  required List<int> days,
  required NotificationTime? notificationTime,
  String? managerId = 'manager',
  String? workoutType,
}) {
  return Plan(
    id: id,
    userId: 'executor',
    managerId: managerId,
    workoutType: workoutType,
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 14),
    state: PlanState.pendingApproval,
    items: [
      PlanItem(
        title: '물 마시기',
        days: days,
        count: days.length,
        notificationTime: notificationTime,
      ),
    ],
    createdAt: DateTime(2026, 5, 1),
  );
}

void main() {
  setUp(() => setContextFreeLocaleCode('ko'));
  tearDown(() => setContextFreeLocaleCode(null));

  group('reminder copy (spec §4.6)', () {
    test('a workout promise asks the check-in question', () async {
      final scheduler = _FakePlanReminderScheduler();
      await SettingAlarmUseCase(scheduler).execute(
        _buildPlan(
          id: 'run',
          days: [1],
          notificationTime: NotificationTime.custom(21, 0),
          workoutType: 'running',
        ),
      );
      expect(scheduler.scheduledTitle, '오늘 🏃 러닝 했어?');
    });

    test('a diet promise asks whether it was kept', () async {
      final scheduler = _FakePlanReminderScheduler();
      await SettingAlarmUseCase(scheduler).execute(
        _buildPlan(
          id: 'diet',
          days: [1],
          notificationTime: NotificationTime.custom(21, 0),
          workoutType: 'diet',
        ),
      );
      expect(scheduler.scheduledTitle, contains('지켰어?'));
    });

    test('with a partner: the partner hears about a missing record', () async {
      final scheduler = _FakePlanReminderScheduler();
      await SettingAlarmUseCase(
        scheduler,
        partnerLabelFor: (_) => '자기',
      ).execute(
        _buildPlan(
          id: 'p',
          days: [1],
          notificationTime: NotificationTime.custom(21, 0),
        ),
      );
      expect(scheduler.scheduledBody, '기록이 없으면 곧 자기한테 알려져요');
      // Never an exact number of minutes.
      expect(scheduler.scheduledBody, isNot(matches(RegExp(r'\d+\s*분'))));
    });

    test('with a partner but no label yet: 짝꿍', () async {
      final scheduler = _FakePlanReminderScheduler();
      await SettingAlarmUseCase(scheduler).execute(
        _buildPlan(
          id: 'p',
          days: [1],
          notificationTime: NotificationTime.custom(21, 0),
        ),
      );
      expect(scheduler.scheduledBody, '기록이 없으면 곧 짝꿍한테 알려져요');
    });

    test('solo: the default body (null) and no partner lookup', () async {
      final scheduler = _FakePlanReminderScheduler();
      var asked = false;
      await SettingAlarmUseCase(
        scheduler,
        partnerLabelFor: (_) {
          asked = true;
          return '자기';
        },
      ).execute(
        _buildPlan(
          id: 'solo',
          days: [1],
          notificationTime: NotificationTime.custom(21, 0),
          managerId: null,
        ),
      );
      expect(scheduler.scheduledBody, isNull);
      expect(asked, isFalse);
    });

    test('planHasRecordOn sees done, skipped, rested and rescued days', () {
      final day = DateTime(2026, 10, 3);
      final base = _buildPlan(
        id: 'x',
        days: [6],
        notificationTime: NotificationTime.custom(21, 0),
      );
      expect(planHasRecordOn(base, day), isFalse);
      for (final plan in [
        base.copyWith(completedDates: [DateTime(2026, 10, 3, 20)]),
        base.copyWith(skippedDates: [DateTime(2026, 10, 3, 20)]),
        base.copyWith(restedDates: [DateTime(2026, 10, 3, 20)]),
        base.copyWith(rescuedDates: [DateTime(2026, 10, 3, 20)]),
      ]) {
        expect(planHasRecordOn(plan, day), isTrue);
      }
      expect(
        planHasRecordOn(
          base.copyWith(completedDates: [DateTime(2026, 10, 2, 20)]),
          day,
        ),
        isFalse,
      );
    });
  });

  test('execute only cancels when alarm is off', () async {
    final scheduler = _FakePlanReminderScheduler();
    final useCase = SettingAlarmUseCase(scheduler);
    final plan = _buildPlan(
      id: 'plan-off',
      days: [1, 3, 5],
      notificationTime: NotificationTime.custom(9, 0).copyWith(type: 'none'),
    );

    await useCase.execute(plan);

    final expectedId = SettingAlarmUseCase.notificationBaseIdFromSeed(
      'plan-off',
    );
    expect(scheduler.canceledPlanId, expectedId);
    expect(scheduler.scheduledPlanId, isNull);
    expect(scheduler.calls, ['cancel:$expectedId']);
  });

  test('execute cancels first and reschedules active reminders', () async {
    final scheduler = _FakePlanReminderScheduler();
    final useCase = SettingAlarmUseCase(scheduler);
    final plan = _buildPlan(
      id: 'plan-on',
      days: [2, 4],
      notificationTime: NotificationTime.custom(7, 30, alertOffset: -15),
    );

    await useCase.execute(plan, skipToday: true);

    final expectedId = SettingAlarmUseCase.notificationBaseIdFromSeed(
      'plan-on',
    );
    expect(scheduler.calls, [
      'cancel:$expectedId',
      'permissions',
      'schedule:$expectedId',
    ]);
    expect(scheduler.scheduledTitle, '물 마시기');
    expect(scheduler.scheduledPlanIdentifier, 'plan-on');
    expect(scheduler.scheduledHour, 7);
    expect(scheduler.scheduledMinute, 30);
    expect(scheduler.scheduledDays, [2, 4]);
    expect(scheduler.scheduledSkipToday, isTrue);
  });

  test('execute forwards hourly recurrence settings to the scheduler', () async {
    final scheduler = _FakePlanReminderScheduler();
    final useCase = SettingAlarmUseCase(scheduler);
    final plan = _buildPlan(
      id: 'plan-hourly',
      days: [1, 2, 3],
      notificationTime: NotificationTime.hourly(
        intervalHours: 2,
        startHour: 9,
        endHour: 21,
      ),
    );

    await useCase.execute(plan);

    expect(scheduler.scheduledIntervalHours, 2);
    expect(scheduler.scheduledStartHour, 9);
    expect(scheduler.scheduledEndHour, 21);
    expect(scheduler.scheduledDays, [1, 2, 3]);
  });

  test('cancelById uses a stable positive notification id', () async {
    final scheduler = _FakePlanReminderScheduler();
    final useCase = SettingAlarmUseCase(scheduler);

    await useCase.cancelById('plan-123');

    final expectedId = SettingAlarmUseCase.notificationBaseIdFromSeed(
      'plan-123',
    );
    expect(expectedId, inInclusiveRange(0, 9999999));
    expect(scheduler.canceledPlanId, expectedId);
    expect(scheduler.calls, ['cancel:$expectedId']);
  });
}
