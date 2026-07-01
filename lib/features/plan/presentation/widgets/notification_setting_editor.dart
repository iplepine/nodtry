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
    final isHourly = notificationTime.isHourly;

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
                  // Preserve any existing config (incl. hourly window) and just
                  // flip the alarm on. Fall back to a sane default time when the
                  // stored value was never a real time.
                  final restored = notificationTime.type == 'none'
                      ? notificationTime.copyWith(type: 'custom')
                      : notificationTime;
                  onTimeChanged(
                    restored.hour == 0 && restored.minute == 0 && !isHourly
                        ? NotificationTime.custom(21, 0)
                        : restored.copyWith(type: 'custom'),
                  );
                } else {
                  onTimeChanged(notificationTime.copyWith(type: 'none'));
                }
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),

        if (isAlarmOn) ...[
          const SizedBox(height: 24),
          _buildRepeatModeSelector(context, l10n, isHourly, targetHour,
              targetMinute),
          const SizedBox(height: 24),
          if (isHourly)
            _buildHourlySettings(context, l10n)
          else
            _buildDailySettings(
              context,
              l10n,
              currentAlertOffset,
              targetHour,
              targetMinute,
            ),
        ],
      ],
    );
  }

  // 반복 방식 선택: 하루 한 번 / 시간마다
  Widget _buildRepeatModeSelector(
    BuildContext context,
    AppLocalizations l10n,
    bool isHourly,
    int targetHour,
    int targetMinute,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notifyEditorRepeatModeLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _modeChip(
                label: l10n.notifyEditorRepeatDaily,
                selected: !isHourly,
                onTap: () {
                  if (!isHourly) return;
                  onTimeChanged(
                    NotificationTime.custom(targetHour, targetMinute),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _modeChip(
                label: l10n.notifyEditorRepeatHourly,
                selected: isHourly,
                onTap: () {
                  if (isHourly) return;
                  onTimeChanged(
                    NotificationTime.hourly(
                      intervalHours: 1,
                      startHour: 9,
                      endHour: 21,
                      minute: 0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ── 하루 한 번(기존 동작): 단일 시간 + 미리 알림 ─────────────────────────
  Widget _buildDailySettings(
    BuildContext context,
    AppLocalizations l10n,
    int currentAlertOffset,
    int targetHour,
    int targetMinute,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            final picked = await _pickTime(
              context,
              TimeOfDay(hour: targetHour, minute: targetMinute),
            );
            if (picked != null) {
              final newTargetTotal = picked.hour * 60 + picked.minute;
              final newTriggerTotal = newTargetTotal - currentAlertOffset;
              final normalizedTriggerTotal = (newTriggerTotal + 1440) % 1440;
              onTimeChanged(
                NotificationTime.custom(
                  normalizedTriggerTotal ~/ 60,
                  normalizedTriggerTotal % 60,
                  alertOffset: currentAlertOffset,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: _fieldBox(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.primary,
            text: _formatTimeOfDay(
              TimeOfDay(hour: targetHour, minute: targetMinute),
              context,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.notifyEditorDefaultTimeHint,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
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
              _buildOffsetChip(0, l10n.notifyEditorOnTime, currentAlertOffset,
                  targetHour, targetMinute),
              const SizedBox(width: 8),
              _buildOffsetChip(5, l10n.notifyEditor5MinBefore,
                  currentAlertOffset, targetHour, targetMinute),
              const SizedBox(width: 8),
              _buildOffsetChip(10, l10n.notifyEditor10MinBefore,
                  currentAlertOffset, targetHour, targetMinute),
              const SizedBox(width: 8),
              _buildOffsetChip(30, l10n.notifyEditor30MinBefore,
                  currentAlertOffset, targetHour, targetMinute),
              const SizedBox(width: 8),
              _buildOffsetChip(60, l10n.notifyEditor1HourBefore,
                  currentAlertOffset, targetHour, targetMinute),
            ],
          ),
        ),
      ],
    );
  }

  // ── 시간마다: 간격 + 시작/종료 시각 ──────────────────────────────────────
  Widget _buildHourlySettings(BuildContext context, AppLocalizations l10n) {
    final interval = notificationTime.intervalHours < 1
        ? 1
        : notificationTime.intervalHours;
    final startHour = notificationTime.startHour.clamp(0, 23);
    final endHour = notificationTime.endHour.clamp(0, 23);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notifyEditorIntervalLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [1, 2, 3, 4, 6].map((h) {
            final selected = interval == h;
            return ChoiceChip(
              label: Text(l10n.notifyEditorIntervalHours(h)),
              selected: selected,
              onSelected: (_) {
                onTimeChanged(
                  notificationTime.copyWith(intervalHours: h),
                );
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildHourField(
                context,
                label: l10n.notifyEditorWindowStart,
                hour: startHour,
                onPicked: (h) {
                  // 시작이 종료보다 뒤면 종료도 함께 밀어준다.
                  final newEnd = h > endHour ? h : endHour;
                  onTimeChanged(
                    notificationTime.copyWith(startHour: h, endHour: newEnd),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHourField(
                context,
                label: l10n.notifyEditorWindowEnd,
                hour: endHour,
                onPicked: (h) {
                  final newStart = h < startHour ? h : startHour;
                  onTimeChanged(
                    notificationTime.copyWith(startHour: newStart, endHour: h),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.notifyEditorHourlyHint(interval, startHour, endHour),
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildHourField(
    BuildContext context, {
    required String label,
    required int hour,
    required ValueChanged<int> onPicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await _pickTime(
              context,
              TimeOfDay(hour: hour, minute: 0),
            );
            if (picked != null) {
              onPicked(picked.hour);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: _fieldBox(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.primary,
            text: _formatTimeOfDay(
              TimeOfDay(hour: hour, minute: 0),
              context,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldBox({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
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
    );
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
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
  }

  Widget _buildOffsetChip(
    int offset,
    String label,
    int currentOffset,
    int targetHour,
    int targetMinute,
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
          onTimeChanged(
            NotificationTime.custom(
              normalizedTriggerTotal ~/ 60,
              normalizedTriggerTotal % 60,
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
