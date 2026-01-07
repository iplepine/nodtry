import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';

class PlanDaySelectionStep extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onDayToggle;
  final NotificationTime notificationTime;
  final ValueChanged<NotificationTime> onTimeChanged;

  const PlanDaySelectionStep({
    super.key,
    required this.selectedDays,
    required this.onDayToggle,
    required this.notificationTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final dayNames = [
      l10n.dayMonday,
      l10n.dayTuesday,
      l10n.dayWednesday,
      l10n.dayThursday,
      l10n.dayFriday,
      l10n.daySaturday,
      l10n.daySunday,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planDayTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedDays.isEmpty
              ? "요일을 선택하지 않으면 매일 하는 약속이 돼요."
              : l10n.planDaySubtitle,
          style: TextStyle(
            fontSize: 14,
            color: selectedDays.isEmpty
                ? AppColors.primary
                : AppColors.textSecondary,
            fontWeight: selectedDays.isEmpty
                ? FontWeight.w500
                : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final isSelected = selectedDays.contains(index);
            return _buildDayChip(context, index, dayNames[index], isSelected);
          }),
        ),
        const SizedBox(height: 48),
        Text(
          l10n.planNotificationTimeOptional,
          style: TextStyle(
            fontSize: 18, // Slightly smaller than main title
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "제 시간에 못 해도 괜찮아요. 오늘 안에만 하면 돼요.", // Warm copy - Keep hardcoded for now or add new key? Sticking to plan.
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: InkWell(
            onTap: () async {
              final initialTime = TimeOfDay(
                hour: notificationTime.hour,
                minute: notificationTime.minute,
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
                onTimeChanged(
                  NotificationTime.custom(picked.hour, picked.minute),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeOfDay(
                      TimeOfDay(
                        hour: notificationTime.hour,
                        minute: notificationTime.minute,
                      ),
                      context,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay time, BuildContext context) {
    // Basic formatting or use TimeFormatter if available.
    // Localized formatting:
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  Widget _buildDayChip(
    BuildContext context,
    int dayIndex,
    String dayName,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDayToggle(dayIndex),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            dayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
