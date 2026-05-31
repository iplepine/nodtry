import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/services/notification_service.dart';

class _FakePlanReminderScheduler implements PlanReminderScheduler {
  final List<String> calls = [];
  int? canceledPlanId;
  int? scheduledPlanId;
  String? scheduledPlanIdentifier;
  String? scheduledTitle;
  int? scheduledHour;
  int? scheduledMinute;
  List<int>? scheduledDays;
  bool? scheduledSkipToday;

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
    required int hour,
    required int minute,
    required List<int> days,
    bool skipToday = false,
  }) async {
    scheduledPlanId = planId;
    scheduledPlanIdentifier = planIdentifier;
    scheduledTitle = title;
    scheduledHour = hour;
    scheduledMinute = minute;
    scheduledDays = days;
    scheduledSkipToday = skipToday;
    calls.add('schedule:$planId');
  }
}

Plan _buildPlan({
  required String id,
  required List<int> days,
  required NotificationTime? notificationTime,
}) {
  return Plan(
    id: id,
    userId: 'executor',
    managerId: 'manager',
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
