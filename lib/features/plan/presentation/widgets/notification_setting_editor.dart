import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.notifyEditorTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAlarmOn ? l10n.notifyEditorSubtitleOn : l10n.notifyEditorSubtitleOff,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Switch(
              value: isAlarmOn,
              onChanged: (value) {
                if (value) {
                  onTimeChanged(
                    NotificationTime.custom(
                      targetHour,
                      targetMinute,
                      alertOffset: 0,
                    ),
                  );
                } else {
                  onTimeChanged(
                    NotificationTime.custom(
                      targetHour,
                      targetMinute,
                      alertOffset: 0,
                    ).copyWith(type: 'none'),
                  );
                }
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text(
          l10n.notifyEditorPromiseTime,
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
              final effectiveOffset = isAlarmOn ? currentAlertOffset : 0;

              final newTargetTotal = picked.hour * 60 + picked.minute;
              final newTriggerTotal = newTargetTotal - effectiveOffset;
              final normalizedTriggerTotal = (newTriggerTotal + 1440) % 1440;
              final newTriggerHour = normalizedTriggerTotal ~/ 60;
              final newTriggerMinute = normalizedTriggerTotal % 60;

              final newType = isAlarmOn ? 'custom' : 'none';

              onTimeChanged(
                NotificationTime(
                  type: newType,
                  value: isAlarmOn
                      ? '$newTriggerHour:$newTriggerMinute'
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
                      : AppColors.textSecondary,
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
        const SizedBox(height: 8),
        Text(
          l10n.notifyEditorDefaultTimeHint,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        if (isAlarmOn) ...[
          Text(
            l10n.notifyEditorPrealert,
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
                  l10n.notifyEditorOnTime,
                  currentAlertOffset,
                  targetHour,
                  targetMinute,
                  onTimeChanged,
                ),
                const SizedBox(width: 8),
                _buildOffsetChip(
                  5,
                  l10n.notifyEditor5MinBefore,
                  currentAlertOffset,
                  targetHour,
                  targetMinute,
                  onTimeChanged,
                ),
                const SizedBox(width: 8),
                _buildOffsetChip(
                  10,
                  l10n.notifyEditor10MinBefore,
                  currentAlertOffset,
                  targetHour,
                  targetMinute,
                  onTimeChanged,
                ),
                const SizedBox(width: 8),
                _buildOffsetChip(
                  30,
                  l10n.notifyEditor30MinBefore,
                  currentAlertOffset,
                  targetHour,
                  targetMinute,
                  onTimeChanged,
                ),
                const SizedBox(width: 8),
                _buildOffsetChip(
                  60,
                  l10n.notifyEditor1HourBefore,
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
