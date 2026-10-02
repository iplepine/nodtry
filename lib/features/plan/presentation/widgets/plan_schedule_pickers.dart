import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/workout_template.dart';

/// "매일", "평일" or "주 N일" for weekday indexes (0 = Monday).
String planDaysLabel(AppLocalizations l10n, Set<int> selectedDays) {
  if (selectedDays.length == 7) return l10n.planDayEveryDay;
  if (selectedDays.length == 5 && selectedDays.containsAll({0, 1, 2, 3, 4})) {
    return l10n.planDayWeekdays;
  }
  return l10n.planDayCountFormat(selectedDays.length);
}

/// "오후 9시" / "오후 8시 30분" (or the hourly range of an older plan) for the
/// time a reminder fires.
String planTimeLabel(AppLocalizations l10n, NotificationTime time) {
  if (time.isHourly) {
    return l10n.planTimeHourlyRange(
      time.startHour,
      time.endHour,
      time.intervalHours,
    );
  }
  final hour = time.targetHour;
  final minute = time.targetMinute;
  final period = hour < 12 ? l10n.planTimeAM : l10n.planTimePM;
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  if (minute == 0) return l10n.planTimeFormatNoMinute(period, displayHour);
  return l10n.planTimeFormatWithMinute(
    period,
    displayHour,
    minute.toString().padLeft(2, '0'),
  );
}

/// The deadline as the chips name it ("밤 9시") when it is one of
/// [workoutDeadlinePresets], so the summary under the chips says the same
/// thing; [planTimeLabel] otherwise.
String planDeadlineLabel(AppLocalizations l10n, NotificationTime time) {
  for (final preset in workoutDeadlinePresets(l10n)) {
    if (preset.matches(time)) return preset.label;
  }
  return planTimeLabel(l10n, time);
}

ChoiceChip _choiceChip({
  Key? key,
  required String label,
  required bool selected,
  required VoidCallback onSelected,
  Widget? avatar,
}) {
  return ChoiceChip(
    key: key,
    selected: selected,
    showCheckmark: false,
    avatar: avatar,
    onSelected: (_) => onSelected(),
    label: Text(label),
    selectedColor: AppColors.primarySoft,
    backgroundColor: AppColors.surface,
    labelStyle: TextStyle(
      color: selected ? AppColors.primary : AppColors.textPrimary,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
    side: BorderSide(
      color: selected ? AppColors.primary : AppColors.divider,
      width: selected ? 1.5 : 1,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );
}

/// Frequency shortcuts and the seven weekday chips.
class PlanWeekdayPicker extends StatelessWidget {
  final Set<int> selectedDays;
  final List<PlanDayPreset> presets;
  final ValueChanged<int> onDayToggle;
  final ValueChanged<Set<int>> onPresetSelected;

  const PlanWeekdayPicker({
    super.key,
    required this.selectedDays,
    required this.presets,
    required this.onDayToggle,
    required this.onPresetSelected,
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in presets)
              _choiceChip(
                key: ValueKey('frequency-${preset.id}'),
                label: preset.label,
                selected:
                    selectedDays.length == preset.selectedDayIndexes.length &&
                    selectedDays.containsAll(preset.selectedDayIndexes),
                onSelected: () => onPresetSelected(preset.selectedDayIndexes),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < 7; index++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _DayChip(
                    key: ValueKey('weekday-$index'),
                    label: dayNames[index],
                    isSelected: selectedDays.contains(index),
                    onTap: () => onDayToggle(index),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deadline chips (아침 7시 … 밤 10시) plus a "직접" chip with a time picker.
///
/// There is deliberately no "no reminder" and no hourly option here: every
/// promise has a deadline. Plan detail and notification settings keep the full
/// NotificationSettingEditor.
class PlanDeadlinePicker extends StatelessWidget {
  final NotificationTime value;
  final List<DeadlinePreset> presets;
  final ValueChanged<NotificationTime> onChanged;

  const PlanDeadlinePicker({
    super.key,
    required this.value,
    required this.presets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matchesPreset = presets.any((preset) => preset.matches(value));
    final isCustom = !matchesPreset && value.type != 'none';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final preset in presets)
          _choiceChip(
            key: ValueKey('deadline-${preset.id}'),
            label: preset.label,
            selected: preset.matches(value),
            onSelected: () => onChanged(preset.time),
          ),
        _choiceChip(
          key: const ValueKey('deadline-custom'),
          label: isCustom
              ? planTimeLabel(l10n, value)
              : l10n.planDeadlineCustom,
          selected: isCustom,
          avatar: Icon(
            Icons.schedule_rounded,
            size: 16,
            color: isCustom ? AppColors.primary : AppColors.textSecondary,
          ),
          onSelected: () => _pickCustomTime(context),
        ),
      ],
    );
  }

  Future<void> _pickCustomTime(BuildContext context) async {
    final initial = value.type == 'none'
        ? const TimeOfDay(hour: kDefaultDeadlineHour, minute: 0)
        : TimeOfDay(hour: value.targetHour, minute: value.targetMinute);
    final picked = await showTimePicker(
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
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onChanged(NotificationTime.custom(picked.hour, picked.minute));
    }
  }
}
