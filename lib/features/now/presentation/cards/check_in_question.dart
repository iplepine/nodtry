import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../plan/domain/workout_template.dart';
import '../../../plan/presentation/weekly_labels.dart';

// The Now-tab cards (part files of now_tab_screen.dart) reach the 주 N회
// labels through here.
export '../../../plan/presentation/weekly_labels.dart'
    show weeklyProgressLabel, weeklyScheduleLabel;

/// The check-in hero's question for [plan]:
/// - workout: `오늘 🏃 러닝 했어?`
/// - diet (not a workout): `오늘 🥗 식단 지켰어?`
/// - a promise from before the pivot (no workoutType): `오늘 '{title}' 했어?`
String todayCheckInQuestion(AppLocalizations l10n, Plan plan) {
  final display = workoutDisplayFor(l10n, plan.workoutType);
  if (display == null) {
    final title = plan.items.firstOrNull?.title.trim();
    return l10n.nowHeroQuestionLegacy(
      (title == null || title.isEmpty) ? l10n.promiseUntitledFallback : title,
    );
  }
  return display.isWorkout
      ? l10n.nowHeroQuestion(display.emoji, display.name)
      : l10n.nowHeroQuestionDiet(display.emoji, display.name);
}

/// The check-in hero's headline: [todayCheckInQuestion], or — for a 주 N회
/// plan that already met this week's target — `이번 주 목표 달성 🎉`. The hero
/// stays up (an extra workout still counts toward the streak).
String todayCheckInHeadline(AppLocalizations l10n, Plan plan, {DateTime? now}) {
  if (plan.isWeeklyGoalMet(asOf: now)) return l10n.nowWeeklyGoalMet;
  return todayCheckInQuestion(l10n, plan);
}

/// The hero's 주 N회 line under the promise: `이번 주 2/3회`, or once the
/// target is met `더 하면 연속 기록에 더해져요`. Null for fixed weekdays.
String? todayCheckInWeeklyLine(
  AppLocalizations l10n,
  Plan plan, {
  DateTime? now,
}) {
  if (!plan.isWeekly) return null;
  if (plan.isWeeklyGoalMet(asOf: now)) return l10n.nowWeeklyGoalMetSub;
  return weeklyProgressLabel(l10n, plan, now: now);
}
