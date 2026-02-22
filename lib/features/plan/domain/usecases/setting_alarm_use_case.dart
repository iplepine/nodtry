import '../../../../models/plan_model.dart';
import '../../../../services/notification_service.dart';

class SettingAlarmUseCase {
  final NotificationService _notificationService;

  SettingAlarmUseCase(this._notificationService);

  Future<void> execute(Plan plan, {bool skipToday = false}) async {
    final item = plan.items.firstOrNull;
    if (item == null) return;

    if (item.days.isEmpty && item.notificationTime?.type == 'none') {
      // Cancel if any
      await _notificationService.cancelPlanReminders(
        (plan.id ?? plan.createdAt.millisecondsSinceEpoch.toString()).hashCode,
      );
      return;
    }

    // Request permissions
    await _notificationService.requestPermissions();

    // Schedule
    await _notificationService.schedulePlanReminder(
      planId: (plan.id ?? plan.createdAt.millisecondsSinceEpoch.toString())
          .hashCode,
      title: item.title,
      hour: item.notificationTime?.hour ?? 20,
      minute: item.notificationTime?.minute ?? 0,
      days: item.days,
      skipToday: skipToday,
    );
  }

  Future<void> cancel(Plan plan) async {
    await _notificationService.cancelPlanReminders(
      (plan.id ?? plan.createdAt.millisecondsSinceEpoch.toString()).hashCode,
    );
  }
}
