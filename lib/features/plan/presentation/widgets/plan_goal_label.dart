import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/plan_goal.dart';

/// The small D-day pill on a promise card: "🎯 D-23 · 제주 여행".
///
/// Shows nothing (zero size) when the plan has no goal, is not running, or the
/// goal is more than a week past. The same label is shown to the owner and to
/// their partner. [topSpacing] is added above it only when it is shown, so
/// call sites need no extra conditional spacing.
class PlanGoalLabel extends StatelessWidget {
  final Plan plan;
  final double topSpacing;

  /// "Today" for tests; the device clock otherwise.
  final DateTime? now;

  const PlanGoalLabel({
    super.key,
    required this.plan,
    this.topSpacing = 8,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.state != PlanState.active) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final text = planGoalLabel(
      l10n,
      title: plan.goalTitle,
      goalDate: plan.goalDate,
      now: now ?? DateTime.now(),
    );
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          key: const ValueKey('plan-goal-label'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
