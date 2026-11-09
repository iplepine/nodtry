import '../../../l10n/app_localizations.dart';
import '../../../models/plan_model.dart';

/// "이번 주 2/3회" for a 주 N회 plan (credits this week / this week's target),
/// or null for a fixed-weekday plan. Credits include a rest pass or rescue.
String? weeklyProgressLabel(AppLocalizations l10n, Plan plan, {DateTime? now}) {
  final progress = plan.weeklyProgress(asOf: now);
  if (progress == null) return null;
  return l10n.weeklyProgressThisWeek(progress.done, progress.target);
}

/// "주 3회 · 이번 주 2/3회" — the schedule of a 주 N회 plan where a fixed plan
/// lists its weekdays; null for a fixed-weekday plan. The week's progress
/// is left out once the plan has ended.
String? weeklyScheduleLabel(AppLocalizations l10n, Plan plan, {DateTime? now}) {
  final target = plan.weeklyTarget;
  if (target == null) return null;
  final label = l10n.planWeeklyTargetLabel(target);
  final at = now ?? DateTime.now();
  if (plan.state != PlanState.active || at.isAfter(plan.endDate)) return label;
  final progress = weeklyProgressLabel(l10n, plan, now: at);
  return progress == null ? label : '$label · $progress';
}
