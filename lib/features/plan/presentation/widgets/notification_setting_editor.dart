import 'package:flutter/material.dart';
import '../../../../models/plan_model.dart';
import '../../../../theme/app_colors.dart';

class NotificationSettingEditor extends StatelessWidget {
  final NotificationTime notificationTime;
  final ValueChanged<NotificationTime> onTimeChanged;

  const NotificationSettingEditor({
    super.key,
    required this.notificationTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Target Time (User-facing Plan Time)
    final currentAlertOffset = notificationTime.alertOffset;
    final currentTriggerTotal =
        notificationTime.hour * 60 + notificationTime.minute;
    final targetTotal = currentTriggerTotal + currentAlertOffset;
    final targetTotalMod = targetTotal % 1440;
    final targetHour = targetTotalMod ~/ 60;
    final targetMinute = targetTotalMod % 60;

    final isAlarmOn = notificationTime.type != 'none';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notification Header with Switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림 설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAlarmOn ? "설정한 시간에 알림을 보낼게요." : "알림 없이 기록만 할게요.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Switch(
              value: isAlarmOn,
              onChanged: (value) {
                if (value) {
                  // Turn On: Restore to 'custom' with 0 offset (At time)
                  // Use current target time as the time.
                  onTimeChanged(
                    NotificationTime.custom(
                      targetHour,
                      targetMinute,
                      alertOffset: 0,
                    ),
                  );
                } else {
                  // Turn Off: Set type to 'none' but PRESERVE the Target Time as the hour/minute.
                  // Since offset will be 0, hour/minute should be the target time.
                  onTimeChanged(
                    NotificationTime.custom(
                      targetHour,
                      targetMinute,
                      alertOffset: 0,
                    ).copyWith(type: 'none'),
                  ); // Explicitly set type none but keep time
                  // Note: NotificationTime.none() zeroes out time. We need to use custom+type override or a new factory.
                  // Plan logic check: does 'none' type imply ignore time?
                  // PlanCard uses targetHour. If we set hour=target, offset=0, then targetHour=hour. Correct.
                  // We need to ensure NotificationTime allows type='none' with non-zero hour.
                  // The 'custom' factory sets type='custom'. We need to override it.
                  // Let's rely on copyWith if available or create a specific instance.
                  // NotificationTime doesn't have copyWith in the snippet I saw earlier?
                  // I added copyWith? No, I added getters.
                  // I will implement constructing it manually:
                  // NotificationTime(type: 'none', value: 'none', hour: targetHour, minute: targetMinute, alertOffset: 0)
                }
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 1. Time Picker (Target Time) - ALWAYS VISIBLE
        Text(
          '약속 시간',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final initialTime = TimeOfDay(
              hour: targetHour,
              minute: targetMinute,
            );
            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      onSurface: AppColors.textPrimary,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              // Calculate new Trigger Time based on CURRENT offset (if alarm on) or 0 (if off)
              final effectiveOffset = isAlarmOn ? currentAlertOffset : 0;

              final newTargetTotal = picked.hour * 60 + picked.minute;
              final newTriggerTotal = newTargetTotal - effectiveOffset;
              final normalizedTriggerTotal = (newTriggerTotal + 1440) % 1440;
              final newTriggerHour = normalizedTriggerTotal ~/ 60;
              final newTriggerMinute = normalizedTriggerTotal % 60;

              // Preserve current type
              final newType = isAlarmOn ? 'custom' : 'none';

              // We need a way to construct this.
              // Assuming we can't use copyWith yet (as I didn't see it added),
              // I will use the constructor via a helper in this file or just make sure `NotificationTime` has a constructor.
              // It accepts typical args.
              onTimeChanged(
                NotificationTime(
                  type: newType,
                  value: isAlarmOn
                      ? '${newTriggerHour}:${newTriggerMinute}'
                      : 'none',
                  hour: newTriggerHour,
                  minute: newTriggerMinute,
                  alertOffset: effectiveOffset,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: isAlarmOn
                      ? AppColors.primary
                      : AppColors
                            .textSecondary, // Dim if alarm off? Or keep primary? User said time is set.
                  // Let's keep it primary or neutral. Neutral seems fine.
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimeOfDay(
                    TimeOfDay(hour: targetHour, minute: targetMinute),
                    context,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        if (isAlarmOn) ...[
          // 2. Alert Offset Selection
          Text(
            '알림 미리받기',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildOffsetChip(
                  0,
                  '제 시간에',
                  currentAlertOffset,
                  targetHour,
                  targetMinute,
                  onTimeChanged,
                ),
                const SizedBox(width: 8),
                _buildOffsetChip(
                  5,
                  '5분 전',
                  currentAlertOffset,
                  targetHour,
                  targetMinute,
                  onTimeChanged,
                ),
                const SizedBox(width: 8),
                _buildOffsetChip(
                  10,
                  '10분 전',
                  currentAlertOffset,
                  targetHour,
                  targetMinute,
                  onTimeChanged,
                ),
                const SizedBox(width: 8),
                _buildOffsetChip(
                  30,
                  '30분 전',
                  currentAlertOffset,
                  targetHour,
                  targetMinute,
                  onTimeChanged,
                ),
                const SizedBox(width: 8),
                _buildOffsetChip(
                  60,
                  '1시간 전',
                  currentAlertOffset,
                  targetHour,
                  targetMinute,
                  onTimeChanged,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOffsetChip(
    int offset,
    String label,
    int currentOffset,
    int targetHour,
    int targetMinute,
    ValueChanged<NotificationTime> onChanged,
  ) {
    final isSelected = currentOffset == offset;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          final targetTotal = targetHour * 60 + targetMinute;
          final newTriggerTotal = targetTotal - offset;
          final normalizedTriggerTotal = (newTriggerTotal + 1440) % 1440;
          final newTriggerHour = normalizedTriggerTotal ~/ 60;
          final newTriggerMinute = normalizedTriggerTotal % 60;

          onChanged(
            NotificationTime.custom(
              newTriggerHour,
              newTriggerMinute,
              alertOffset: offset,
            ),
          );
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  String _formatTimeOfDay(TimeOfDay time, BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }
}
