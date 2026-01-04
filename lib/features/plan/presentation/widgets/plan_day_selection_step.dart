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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildNotificationChip(
                context,
                l10n,
                'morning',
                l10n.vagueTimeMorning,
              ),
              const SizedBox(width: 8),
              _buildNotificationChip(
                context,
                l10n,
                'lunch',
                l10n.vagueTimeLunch,
              ),
              const SizedBox(width: 8),
              _buildNotificationChip(
                context,
                l10n,
                'dinner',
                l10n.vagueTimeDinner,
              ),
              const SizedBox(width: 8),
              _buildNotificationChip(
                context,
                l10n,
                'bedtime',
                l10n.vagueTimeBedtime,
              ),
              const SizedBox(width: 8),
              _buildCustomTimeChip(context, l10n),
            ],
          ),
        ),
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
                ? AppColors.primary.withOpacity(0.1)
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

  Widget _buildNotificationChip(
    BuildContext context,
    AppLocalizations l10n,
    String value,
    String label,
  ) {
    final isSelected =
        notificationTime.type == 'preset' && notificationTime.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (isSelected) {
          // 이미 선택된 상태에서 다시 누르면 선택 해제 (toggle off)
          onTimeChanged(NotificationTime.none());
        } else {
          onTimeChanged(NotificationTime.preset(value));
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.1),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
    );
  }

  Widget _buildCustomTimeChip(BuildContext context, AppLocalizations l10n) {
    final isCustom = notificationTime.type == 'custom';
    final label = isCustom
        ? "${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}"
        : "직접 설정";

    return ChoiceChip(
      label: Text(label),
      selected: isCustom,
      onSelected: (selected) async {
        if (selected) {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: notificationTime.hour,
              minute: notificationTime.minute,
            ),
          );
          if (picked != null) {
            onTimeChanged(NotificationTime.custom(picked.hour, picked.minute));
          }
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.1),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isCustom ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isCustom ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: isCustom ? AppColors.primary : AppColors.divider),
    );
  }
}
