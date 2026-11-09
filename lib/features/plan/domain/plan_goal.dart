import 'package:flutter/widgets.dart' show StringCharacters;

import '../../../l10n/app_localizations.dart';

// D-day goal on a promise (`plans.goalTitle` / `plans.goalDate`).
//
// Couples often work out toward an event — a trip, a wedding, a body-profile
// shoot. Both fields are optional and additive (pivot spec §9): plans without
// them, and app builds that do not know them, behave exactly as before.
//
// `goalDate` is a calendar date, not an instant: see `Plan.goalDate` for how
// it is stored.

/// Longest goal title, in user-perceived characters (what the text field
/// counts).
const int kPlanGoalTitleMaxLength = 20;

/// Hard cap on the stored title in UTF-16 code units — what firestore.rules'
/// `size()` counts. Twice [kPlanGoalTitleMaxLength], so 20 Hangul or 20
/// simple emoji always fit; only long emoji sequences get trimmed.
const int kPlanGoalTitleMaxUnits = 40;

/// How many days after the goal date the label stays visible ("D+7" is the
/// last one shown).
const int kPlanGoalAfterDays = 7;

/// The date part of [value], as a local midnight `DateTime`.
DateTime planGoalDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// A goal title as it is stored: trimmed, at most [kPlanGoalTitleMaxLength]
/// characters and [kPlanGoalTitleMaxUnits] UTF-16 units (never cutting a
/// character in half), null when empty.
String? normalizePlanGoalTitle(String? raw) {
  if (raw == null) return null;
  var chars = raw.trim().characters.take(kPlanGoalTitleMaxLength);
  while (chars.isNotEmpty && chars.string.length > kPlanGoalTitleMaxUnits) {
    chars = chars.skipLast(1);
  }
  final title = chars.string.trim();
  return title.isEmpty ? null : title;
}

enum PlanGoalPhase {
  /// Still ahead: "D-23".
  before,

  /// The goal is today: "D-day".
  today,

  /// Up to [kPlanGoalAfterDays] days after: "D+3".
  after,
}

/// Where today stands relative to a goal date.
class PlanGoalCountdown {
  final PlanGoalPhase phase;

  /// Whole calendar days between today and the goal date (0 on the day).
  final int days;

  const PlanGoalCountdown(this.phase, this.days);

  @override
  bool operator ==(Object other) =>
      other is PlanGoalCountdown && other.phase == phase && other.days == days;

  @override
  int get hashCode => Object.hash(phase, days);

  @override
  String toString() => 'PlanGoalCountdown($phase, $days)';
}

/// The countdown to [goalDate] as of [now], or null when it should not be
/// shown (no goal, or more than [kPlanGoalAfterDays] days past it).
///
/// Only calendar dates are compared — the time of day of either value never
/// matters — and the difference is taken on UTC dates so a daylight-saving
/// switch in between cannot shave off a day.
PlanGoalCountdown? planGoalCountdown(DateTime? goalDate, DateTime now) {
  if (goalDate == null) return null;
  final goal = DateTime.utc(goalDate.year, goalDate.month, goalDate.day);
  final today = DateTime.utc(now.year, now.month, now.day);
  final days = goal.difference(today).inDays;
  if (days > 0) return PlanGoalCountdown(PlanGoalPhase.before, days);
  if (days == 0) return const PlanGoalCountdown(PlanGoalPhase.today, 0);
  if (-days <= kPlanGoalAfterDays) {
    return PlanGoalCountdown(PlanGoalPhase.after, -days);
  }
  return null;
}

/// The small label shown on promise cards: "D-23 · 제주 여행" / "23 days to
/// Jeju trip", or null when nothing should be shown.
String? planGoalLabel(
  AppLocalizations l10n, {
  required String? title,
  required DateTime? goalDate,
  required DateTime now,
}) {
  final countdown = planGoalCountdown(goalDate, now);
  if (countdown == null) return null;
  final name = normalizePlanGoalTitle(title);
  switch (countdown.phase) {
    case PlanGoalPhase.before:
      return name == null
          ? l10n.planGoalLabelBeforeUntitled(countdown.days)
          : l10n.planGoalLabelBefore(countdown.days, name);
    case PlanGoalPhase.today:
      return name == null
          ? l10n.planGoalLabelTodayUntitled
          : l10n.planGoalLabelToday(name);
    case PlanGoalPhase.after:
      return name == null
          ? l10n.planGoalLabelAfterUntitled(countdown.days)
          : l10n.planGoalLabelAfter(countdown.days, name);
  }
}

/// Preset goal chips on the plan-create screen. [custom] (직접 입력) clears
/// the title and lets the user type one.
enum PlanGoalPreset {
  trip,
  wedding,
  bodyProfile,
  custom;

  /// The title a preset fills in, or null for [custom].
  String? title(AppLocalizations l10n) {
    switch (this) {
      case PlanGoalPreset.trip:
        return l10n.planGoalPresetTrip;
      case PlanGoalPreset.wedding:
        return l10n.planGoalPresetWedding;
      case PlanGoalPreset.bodyProfile:
        return l10n.planGoalPresetBodyProfile;
      case PlanGoalPreset.custom:
        return null;
    }
  }

  String chipLabel(AppLocalizations l10n) =>
      title(l10n) ?? l10n.planGoalPresetCustom;
}
