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
                  isAlarmOn ? "똑똑이 살아날 시간을 정해요." : "알림 없이 기록만 할게요.",
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
          '파트너에게 보일 약속 시간',
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
          '기본 저녁 9시는 하루가 묻히기 전에 파트너가 확인하기 좋은 시간이에요.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        if (isAlarmOn) ...[
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
