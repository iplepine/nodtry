import 'package:flutter/foundation.dart';

import '../../../../models/plan_model.dart';
import '../../../../services/notification_service.dart';

class SettingAlarmUseCase {
  // Keep in sync with `_planNotificationIdModulo` in
  // `lib/services/notification_service.dart` — the cancel/schedule pair derives
  // the same id from the plan seed.
  static const int _planNotificationIdModulo = 10000000;
  final PlanReminderScheduler _notificationService;

  SettingAlarmUseCase(this._notificationService);

  Future<void> execute(Plan plan, {bool skipToday = false}) async {
    final item = plan.items.firstOrNull;
    if (item == null) return;

    final planNotificationId = _notificationBaseIdForPlan(plan);
    await _notificationService.cancelPlanReminders(planNotificationId);

    if (!_shouldSchedule(item)) {
      return;
    }

    await _notificationService.requestPermissions();
    final notificationTime = item.notificationTime!;

    await _notificationService.schedulePlanReminder(
      planId: planNotificationId,
      planIdentifier: plan.id,
      title: item.title,
      hour: notificationTime.hour,
      minute: notificationTime.minute,
      days: item.days,
      skipToday: skipToday,
      intervalHours: notificationTime.intervalHours,
      startHour: notificationTime.startHour,
      endHour: notificationTime.endHour,
    );
  }

  Future<void> cancel(Plan plan) async {
    await _notificationService.cancelPlanReminders(
      _notificationBaseIdForPlan(plan),
    );
  }

  Future<void> cancelById(String planId) async {
    await _notificationService.cancelPlanReminders(
      notificationBaseIdFromSeed(planId),
    );
  }

  @visibleForTesting
  static int notificationBaseIdFromSeed(String seed) {
    var hash = 0;
    for (final codeUnit in seed.codeUnits) {
      hash = ((hash * 31) + codeUnit) % _planNotificationIdModulo;
    }
    return hash;
  }

  int _notificationBaseIdForPlan(Plan plan) {
    final seed = plan.id ?? plan.createdAt.millisecondsSinceEpoch.toString();
    return notificationBaseIdFromSeed(seed);
  }

  bool _shouldSchedule(PlanItem item) {
    final notificationTime = item.notificationTime;
    return item.days.isNotEmpty &&
        notificationTime != null &&
        notificationTime.type != 'none';
  }
}
