import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/error_reporter.dart';
import '../../domain/plan_goal.dart';
import 'plan_goal_editor.dart';

/// Plan-detail info row for the D-day goal.
///
/// The owner ([editable]) can add, change or remove it in a sheet; the partner
/// just sees it. Without a goal the partner sees nothing.
class PlanGoalDetailRow extends ConsumerWidget {
  final Plan plan;
  final bool editable;

  /// Space added above the row when it is shown.
  final double topSpacing;

  const PlanGoalDetailRow({
    super.key,
    required this.plan,
    required this.editable,
    this.topSpacing = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final goalDate = plan.goalDate;
    if (goalDate == null && !editable) return const SizedBox.shrink();
    if (plan.id == null) return const SizedBox.shrink();

    final String label;
    if (goalDate == null) {
      label = l10n.planGoalDetailAdd;
    } else {
      // Past the D+7 window the countdown is gone; the date still says what
      // the goal was.
      label =
          planGoalLabel(
            l10n,
            title: plan.goalTitle,
            goalDate: goalDate,
            now: DateTime.now(),
          ) ??
          [
            MaterialLocalizations.of(context).formatMediumDate(goalDate),
            ?normalizePlanGoalTitle(plan.goalTitle),
          ].join(' · ');
    }

    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: InkWell(
        key: const ValueKey('plan-goal-detail-row'),
        onTap: editable ? () => showPlanGoalSheet(context, ref, plan) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 24,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: goalDate == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (editable) ...[
                const SizedBox(width: 8),
                Icon(
                  goalDate == null ? Icons.add : Icons.edit,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the goal sheet for [plan] and saves what the owner picks.
Future<void> showPlanGoalSheet(
  BuildContext context,
  WidgetRef ref,
  Plan plan,
) async {
  final planId = plan.id;
  if (planId == null) return;
  final result = await showModalBottomSheet<_GoalResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PlanGoalSheet(plan: plan),
  );
  if (result == null || !context.mounted) return;
  final unchanged =
      result.date == plan.goalDate &&
      result.title == normalizePlanGoalTitle(plan.goalTitle);
  if (unchanged) return;

  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  try {
    await ref
        .read(recordRepositoryProvider)
        .updatePlanGoal(planId, goalTitle: result.title, goalDate: result.date);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.date == null ? l10n.planGoalRemoved : l10n.planGoalSaved,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e, stack) {
    ErrorReporter.record(e, stack, reason: 'updatePlanGoal');
    messenger.showSnackBar(SnackBar(content: Text(l10n.planGoalSaveError)));
  }
}

class _GoalResult {
  final String? title;
  final DateTime? date;
  const _GoalResult(this.title, this.date);
}

class _PlanGoalSheet extends StatefulWidget {
  final Plan plan;
  const _PlanGoalSheet({required this.plan});

  @override
  State<_PlanGoalSheet> createState() => _PlanGoalSheetState();
}

class _PlanGoalSheetState extends State<_PlanGoalSheet> {
  late String _title = widget.plan.goalTitle ?? '';
  late DateTime? _date = widget.plan.goalDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final systemNav = MediaQuery.viewPaddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom + systemNav),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.planGoalSheetTitle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          PlanGoalEditor(
            title: _title,
            date: _date,
            collapsible: false,
            onTitleChanged: (value) => setState(() => _title = value),
            onDateChanged: (value) => setState(() => _date = value),
            onClear: () => setState(() {
              _title = '';
              _date = null;
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('plan-goal-sheet-save'),
              onPressed: () {
                final date = _date;
                Navigator.of(context).pop(
                  _GoalResult(
                    date == null ? null : normalizePlanGoalTitle(_title),
                    date,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.planGoalSave),
            ),
          ),
        ],
      ),
    );
  }
}
