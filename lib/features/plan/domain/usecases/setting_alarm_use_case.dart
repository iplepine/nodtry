import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../services/notification_service.dart';
import '../../../../utils/context_free_l10n.dart';
import '../workout_template.dart';

/// The deadline reminder's title for [plan] (spec §4.6): the check-in
/// question for a workout promise ("오늘 🏃 러닝 했어?"); the promise line
/// itself for a plan from before the pivot (no workout type).
String planReminderTitle(AppLocalizations l10n, Plan plan) {
  final title = plan.items.firstOrNull?.title.trim() ?? '';
  final display = workoutDisplayFor(l10n, plan.workoutType);
  if (display == null) {
    return title.isEmpty ? l10n.promiseUntitledFallback : title;
  }
  return display.isWorkout
      ? l10n.nowHeroQuestion(display.emoji, display.name)
      : l10n.nowHeroQuestionDiet(display.emoji, display.name);
}

/// The deadline reminder's body for [plan], or null for the default text.
///
/// A promise with a partner says the partner will hear about a missing record
/// ("기록이 없으면 곧 {짝꿍}한테 알려져요") — never an exact number of minutes:
/// the server's missed-workout pass runs on a schedule, 30–60 minutes after
/// the deadline.
String? planReminderBody(
  AppLocalizations l10n,
  Plan plan, {
  String? partnerLabel,
}) {
  if (plan.managerId == null) return null;
  final label = partnerLabel?.trim();
  return l10n.notifReminderBodyWithPartner(
    (label == null || label.isEmpty) ? l10n.partnerFallbackLabel : label,
  );
}

/// What the partner of [plan] is called in its reminder (nickname, display
/// name), or null for the generic 짝꿍.
typedef ReminderPartnerLabel = String? Function(Plan plan);

/// True when the partner list has loaded and nobody is connected: a stale
/// `managerId` (the server clears it on unlink) must not promise a partner
/// notice nobody will send.
typedef ReminderPartnerAbsent = bool Function();

class SettingAlarmUseCase {
  // Keep in sync with `_planNotificationIdModulo` in
  // `lib/services/notification_service.dart` — the cancel/schedule pair derives
  // the same id from the plan seed.
  static const int _planNotificationIdModulo = 10000000;
  final PlanReminderScheduler _notificationService;
  final ReminderPartnerLabel? _partnerLabelFor;
  final ReminderPartnerAbsent? _partnerAbsent;
  final Future<void> Function()? _afterPermissionRequest;
  final AppLocalizations Function() _l10n;

  /// [afterPermissionRequest] runs after the OS permission prompt (e.g. to
  /// register the push token right away when it was granted).
  SettingAlarmUseCase(
    this._notificationService, {
    ReminderPartnerLabel? partnerLabelFor,
    ReminderPartnerAbsent? partnerAbsent,
    Future<void> Function()? afterPermissionRequest,
    AppLocalizations Function()? l10n,
  }) : _partnerLabelFor = partnerLabelFor,
       _partnerAbsent = partnerAbsent,
       _afterPermissionRequest = afterPermissionRequest,
       _l10n = l10n ?? contextFreeL10n;

  Future<void> execute(Plan plan, {bool skipToday = false}) async {
    final item = plan.items.firstOrNull;
    if (item == null) return;

    final planNotificationId = _notificationBaseIdForPlan(plan);
    await _notificationService.cancelPlanReminders(planNotificationId);

    if (!_shouldSchedule(item)) {
      return;
    }

    await _notificationService.requestPermissions();
    final afterPermission = _afterPermissionRequest;
    if (afterPermission != null) {
      try {
        await afterPermission();
      } catch (e) {
        debugPrint('[SettingAlarmUseCase] after-permission hook failed: $e');
      }
    }
    final notificationTime = item.notificationTime!;
    final l10n = _l10n();
    var partnerAbsent = false;
    try {
      partnerAbsent = _partnerAbsent?.call() ?? false;
    } catch (_) {}
    final hasPartnerLine = plan.managerId != null && !partnerAbsent;

    await _notificationService.schedulePlanReminder(
      planId: planNotificationId,
      planIdentifier: plan.id,
      title: planReminderTitle(l10n, plan),
      body: hasPartnerLine
          ? planReminderBody(
              l10n,
              plan,
              partnerLabel: _partnerLabelFor?.call(plan),
            )
          : null,
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

/// Whether [plan] already has a record (done, skipped, rested or rescued) on
/// [day] — its reminder for that day must not fire ("기록이 없으면 곧 …"
/// would be wrong).
bool planHasRecordOn(Plan plan, DateTime day) {
  bool has(List<DateTime> dates) => dates.any(
    (d) => d.year == day.year && d.month == day.month && d.day == day.day,
  );
  return has(plan.completedDates) ||
      has(plan.skippedDates) ||
      has(plan.restedDates) ||
      has(plan.rescuedDates);
}
