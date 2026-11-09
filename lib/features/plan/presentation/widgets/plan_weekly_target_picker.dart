import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/weekly_target.dart';
import '../../../../theme/app_colors.dart';

/// 요일 정하기 | 주 N회 자유롭게 — the two ways to schedule a promise.
class PlanScheduleModeToggle extends StatelessWidget {
  const PlanScheduleModeToggle({
    super.key,
    required this.weekly,
    required this.onChanged,
  });

  /// 주 N회 자유롭게 is selected.
  final bool weekly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _Segment(
            key: const ValueKey('schedule-mode-fixed'),
            label: l10n.planScheduleModeFixed,
            selected: !weekly,
            onTap: () => onChanged(false),
          ),
          _Segment(
            key: const ValueKey('schedule-mode-weekly'),
            label: l10n.planScheduleModeWeekly,
            selected: weekly,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: onTap,
            child: SizedBox(
              height: 40,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
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

/// The 주 N회 stepper: − 주 3회 + (1–6), with a line on how it works.
class PlanWeeklyTargetStepper extends StatelessWidget {
  const PlanWeeklyTargetStepper({
    super.key,
    required this.target,
    required this.onChanged,
  });

  final int target;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canDecrease = target > kWeeklyTargetMin;
    final canIncrease = target < kWeeklyTargetMax;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('weekly-target-minus'),
                tooltip: l10n.planWeeklyTargetDecrease,
                onPressed: canDecrease ? () => onChanged(target - 1) : null,
                icon: const Icon(Icons.remove_rounded),
                color: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  l10n.planWeeklyTargetLabel(target),
                  key: const ValueKey('weekly-target-value'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('weekly-target-plus'),
                tooltip: l10n.planWeeklyTargetIncrease,
                onPressed: canIncrease ? () => onChanged(target + 1) : null,
                icon: const Icon(Icons.add_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l10n.planWeeklyHint,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
