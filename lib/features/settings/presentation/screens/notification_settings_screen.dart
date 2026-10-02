import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../utils/time_formatter.dart';
import '../../../connect/application/partner_label_provider.dart';
import '../../../plan/presentation/widgets/notification_setting_editor.dart'
    show confirmPartneredReminderOff;

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(authStateChangesProvider).value;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    final plansAsync = ref.watch(
      getPlansByUserIdStreamProvider(currentUser.uid),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.notificationSettingsTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: plansAsync.when(
          data: (plans) {
            // Filter only Active or Pending plans (though stream usually does this, safe to check)
            // And also check if they have valid items
            final activePlans = plans.where((p) => p.items.isNotEmpty).toList();

            if (activePlans.isEmpty) {
              return Center(
                child: Text(
                  l10n.noActiveAlarms,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: activePlans.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final plan = activePlans[index];
                return _buildPlanSwitchTile(context, ref, plan);
              },
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error loading plans',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSwitchTile(BuildContext context, WidgetRef ref, Plan plan) {
    if (plan.items.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final item = plan.items.first;
    final notificationTime = item.notificationTime;

    // Determine if alarm is effectively "ON"
    final isAlarmOn =
        notificationTime != null && notificationTime.type != 'none';

    // Display Time String
    String timeString = l10n.notificationSettingsNoAlarm;
    if (notificationTime != null) {
      if (notificationTime.isHourly) {
        timeString = l10n.planTimeHourlyRange(
          notificationTime.startHour,
          notificationTime.endHour,
          notificationTime.intervalHours,
        );
      } else {
        final dt = DateTime(
          2020,
          1,
          1,
          notificationTime.targetHour,
          notificationTime.targetMinute,
        );
        timeString = TimeFormatter.formatExactTime(dt);
      }
    }

    // If Alarm is OFF, subtext might say "OFF" or the scheduled time but grayed out.
    // Spec says: Subtitle: Alarm Time or "No Alarm"
    final subtitle = isAlarmOn ? timeString : l10n.notificationSettingsAlarmOff(timeString);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppColors.primary,
      title: Text(
        item.title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isAlarmOn ? AppColors.textSecondary : AppColors.textDisabled,
          fontSize: 14,
        ),
      ),
      value: isAlarmOn,
      onChanged: (bool value) async {
        await _toggleAlarm(context, ref, plan, value);
      },
    );
  }

  Future<void> _toggleAlarm(
    BuildContext context,
    WidgetRef ref,
    Plan plan,
    bool value,
  ) async {
    final item = plan.items.first;
    var currentTime = item.notificationTime ?? NotificationTime.none();

    NotificationTime newTime;
    if (value) {
      // Turning ON: keep the stored time, but a reminder that was never set
      // (00:00 from NotificationTime.none()) gets the editor's 밤 9시 default —
      // a 00:00 deadline told the partner about a "miss" every night at 00:30.
      final restored = currentTime.copyWith(type: 'custom');
      newTime =
          restored.hour == 0 && restored.minute == 0 && !restored.isHourly
          ? NotificationTime.custom(21, 0)
          : restored;
    } else {
      // Turning OFF a promise with a partner also drops its deadline: say so.
      if (plan.managerId != null) {
        final ok = await confirmPartneredReminderOff(
          context,
          partnerName: ref
              .read(partnerLabelProvider)
              .resolve(AppLocalizations.of(context)!),
        );
        if (!ok || !context.mounted) return;
      }
      newTime = currentTime.copyWith(type: 'none');
    }

    // Update PlanItem
    // PlanItem is immutable and no copyWith in snippet, construct manually
    final newItem = PlanItem(
      title: item.title,
      days: item.days,
      count: item.count,
      description: item.description,
      notificationTime: newTime,
    );

    final newItems = List<PlanItem>.from(plan.items);
    newItems[0] = newItem;

    final updatedPlan = plan.copyWith(items: newItems);
    final repository = ref.read(recordRepositoryProvider);
    final settingAlarmUseCase = ref.read(settingAlarmUseCaseProvider);

    if (plan.id == null) return;
    try {
      // Only the items, stamped as mine (see RecordRepository.updatePlanItems).
      await repository.updatePlanItems(plan.id!, newItems);
      await settingAlarmUseCase.execute(updatedPlan);
    } catch (e) {
      try {
        await repository.updatePlanItems(plan.id!, plan.items);
        await settingAlarmUseCase.execute(plan);
      } catch (rollbackError) {
        debugPrint(
          '[NotificationSettingsScreen] Failed to rollback alarm change: $rollbackError',
        );
      }

      debugPrint('Failed to toggle alarm: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notificationSettingsSaveFailed)),
        );
      }
    }
  }
}
