import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../plan/domain/workout_template.dart';

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
