import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import 'notification_setting_editor.dart';

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

        NotificationSettingEditor(
          notificationTime: notificationTime,
          onTimeChanged: onTimeChanged,
        ),
        const SizedBox(height: 32),
      ],
    );
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
