import '../../../l10n/app_localizations.dart';
import '../../../models/plan_model.dart';

/// Legacy plan-category ids. Plan creation has no categories any more, but the
/// strings keep their meaning for anything that stored or logged them.
const planCategoryExercise = 'exercise';
const planCategoryCustom = 'custom';

/// What a workout promise is about.
///
/// [id] is the value stored in `plans.workoutType` (pivot spec §9) and read by
/// Cloud Functions for push copy — never rename one. The emoji match the
/// server's push copy (`functions/src/copy.ts`).
enum WorkoutType {
  gym('gym', '🏋️'),
  running('running', '🏃'),
  homeTraining('home_training', '🏠'),
  walking('walking', '🚶'),
  pilates('pilates', '🧘‍♀️'),
  yoga('yoga', '🧘'),
  stretching('stretching', '🤸'),
  swimming('swimming', '🏊'),
  climbing('climbing', '🧗'),
  cycling('cycling', '🚴'),
  hiking('hiking', '⛰️'),
  strength('strength', '💪'),

  /// 식단·야식 참기 — a promise, but not a workout: never call it 운동.
  diet('diet', '🥗'),

  /// The free-form tile (직접 입력): the plan title says what it is.
  other('other', '💪');

  const WorkoutType(this.id, this.emoji);

  /// Stored value of `plans.workoutType`.
  final String id;

  /// Emoji shown next to the workout's name.
  final String emoji;

  /// Emoji on the plan-create tile; the free-form tile shows a pencil.
  String get tileEmoji => this == WorkoutType.other ? '✏️' : emoji;

  /// False for [diet], which must not be worded as a workout (운동/오운완).
  bool get isWorkout => this != WorkoutType.diet;

  /// Parses a stored `workoutType`.
  ///
  /// Null or empty (plans from before the pivot) gives null, so callers can
  /// fall back to neutral 약속 copy. A value this build does not know (written
  /// by a newer build) is treated as [other].
  static WorkoutType? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final type in values) {
      if (type.id == id) return type;
    }
    return WorkoutType.other;
  }
}

/// The tile label: 헬스, 러닝, …, 식단·야식 참기, 직접 입력.
String workoutTypeLabel(AppLocalizations l10n, WorkoutType type) {
  switch (type) {
    case WorkoutType.gym:
      return l10n.workoutTypeGymLabel;
    case WorkoutType.running:
      return l10n.workoutTypeRunningLabel;
    case WorkoutType.homeTraining:
      return l10n.workoutTypeHomeTrainingLabel;
    case WorkoutType.walking:
      return l10n.workoutTypeWalkingLabel;
    case WorkoutType.pilates:
      return l10n.workoutTypePilatesLabel;
    case WorkoutType.yoga:
      return l10n.workoutTypeYogaLabel;
    case WorkoutType.stretching:
      return l10n.workoutTypeStretchingLabel;
    case WorkoutType.swimming:
      return l10n.workoutTypeSwimmingLabel;
    case WorkoutType.climbing:
      return l10n.workoutTypeClimbingLabel;
    case WorkoutType.cycling:
      return l10n.workoutTypeCyclingLabel;
    case WorkoutType.hiking:
      return l10n.workoutTypeHikingLabel;
    case WorkoutType.strength:
      return l10n.workoutTypeStrengthLabel;
    case WorkoutType.diet:
      return l10n.workoutTypeDietLabel;
    case WorkoutType.other:
      return l10n.workoutTypeOtherLabel;
  }
}

/// The workout as a word inside a sentence, e.g. `오늘 {name} 했어?`.
///
/// Same as the tile label except where the label doesn't fit `{name} 했어?`:
/// 식단 for [WorkoutType.diet], 운동 for the free-form [WorkoutType.other]
/// tile, 자전거 타기 for [WorkoutType.cycling] (자전거 takes 타다, not 하다)
/// and "Strength training" for [WorkoutType.strength].
String workoutTypeName(AppLocalizations l10n, WorkoutType type) {
  switch (type) {
    case WorkoutType.diet:
      return l10n.workoutTypeDietName;
    case WorkoutType.other:
      return l10n.workoutTypeOtherName;
    case WorkoutType.cycling:
      return l10n.workoutTypeCyclingName;
    case WorkoutType.strength:
      return l10n.workoutTypeStrengthName;
    default:
      return workoutTypeLabel(l10n, type);
  }
}

/// The one-line promise a tile pre-fills. Empty for [WorkoutType.other].
String workoutTypeDefaultAction(AppLocalizations l10n, WorkoutType type) {
  switch (type) {
    case WorkoutType.gym:
      return l10n.workoutTypeGymAction;
    case WorkoutType.running:
      return l10n.workoutTypeRunningAction;
    case WorkoutType.homeTraining:
      return l10n.workoutTypeHomeTrainingAction;
    case WorkoutType.walking:
      return l10n.workoutTypeWalkingAction;
    case WorkoutType.pilates:
      return l10n.workoutTypePilatesAction;
    case WorkoutType.yoga:
      return l10n.workoutTypeYogaAction;
    case WorkoutType.stretching:
      return l10n.workoutTypeStretchingAction;
    case WorkoutType.swimming:
      return l10n.workoutTypeSwimmingAction;
    case WorkoutType.climbing:
      return l10n.workoutTypeClimbingAction;
    case WorkoutType.cycling:
      return l10n.workoutTypeCyclingAction;
    case WorkoutType.hiking:
      return l10n.workoutTypeHikingAction;
    case WorkoutType.strength:
      return l10n.workoutTypeStrengthAction;
    case WorkoutType.diet:
      return l10n.workoutTypeDietAction;
    case WorkoutType.other:
      return '';
  }
}

/// How a plan's workout is shown in copy (cards, prompts, share text).
class WorkoutDisplay {
  final WorkoutType type;

  /// Emoji for the workout (💪 for the free-form tile).
  final String emoji;

  /// Word for use inside a sentence; see [workoutTypeName].
  final String name;

  const WorkoutDisplay({
    required this.type,
    required this.emoji,
    required this.name,
  });

  /// False for diet: use 식단/약속 wording instead of 운동/오운완.
  bool get isWorkout => type.isWorkout;
}

/// Label and emoji for a plan's stored `workoutType`, e.g. to build
/// `오늘 {name} 했어?`.
///
/// Returns null for plans without a workoutType (created before the pivot,
/// possibly not a workout at all): show neutral 약속 copy with the plan title.
WorkoutDisplay? workoutDisplayFor(AppLocalizations l10n, String? workoutType) {
  final type = WorkoutType.fromId(workoutType);
  if (type == null) return null;
  return WorkoutDisplay(
    type: type,
    emoji: type.emoji,
    name: workoutTypeName(l10n, type),
  );
}

/// A workout tile on the plan-create screen and the values it pre-fills.
class WorkoutTemplate {
  final WorkoutType type;

  /// Tile label.
  final String label;

  /// Pre-filled one-line promise (editable). Empty for the free-form tile.
  final String action;

  /// Default weekdays, 0 = Monday … 6 = Sunday.
  final Set<int> selectedDayIndexes;

  /// Default deadline (the reminder time and the partner's missed-workout
  /// cut-off). Always one of [workoutDeadlinePresets].
  final NotificationTime deadline;

  const WorkoutTemplate({
    required this.type,
    required this.label,
    required this.action,
    required this.selectedDayIndexes,
    required this.deadline,
  });

  /// Template id used in analytics; the same string as [WorkoutType.id].
  String get id => type.id;

  String get emoji => type.tileEmoji;

  /// Legacy category id ('exercise', or 'custom' for the free-form tile).
  String get categoryId =>
      type == WorkoutType.other ? planCategoryCustom : planCategoryExercise;

  int get weeklyCount => selectedDayIndexes.length;
}

const _monWedFri = {0, 2, 4};
const _tueThu = {1, 3};
const _tueFri = {1, 4};
const _weekdays = {0, 1, 2, 3, 4};
const _weekend = {5, 6};
const _everyDay = {0, 1, 2, 3, 4, 5, 6};

/// Default deadline hour when nothing else applies (밤 9시).
const kDefaultDeadlineHour = 21;

/// The tile for [type] with its default promise, weekdays and deadline.
WorkoutTemplate workoutTemplateFor(AppLocalizations l10n, WorkoutType type) {
  final (Set<int> days, int hour) = switch (type) {
    WorkoutType.gym => (_monWedFri, 22),
    WorkoutType.running => ({1, 3, 5}, 21),
    WorkoutType.homeTraining => (_weekdays, 22),
    WorkoutType.walking => (_everyDay, 21),
    WorkoutType.pilates => (_tueThu, 22),
    WorkoutType.yoga => (_monWedFri, 21),
    WorkoutType.stretching => (_everyDay, 22),
    WorkoutType.swimming => (_monWedFri, 21),
    WorkoutType.climbing => (_tueFri, 22),
    WorkoutType.cycling => (_weekend, 19),
    WorkoutType.hiking => (const {5}, 19),
    WorkoutType.strength => (_tueFri, 21),
    WorkoutType.diet => (_everyDay, 22),
    WorkoutType.other => (_monWedFri, kDefaultDeadlineHour),
  };
  return WorkoutTemplate(
    type: type,
    label: workoutTypeLabel(l10n, type),
    action: workoutTypeDefaultAction(l10n, type),
    selectedDayIndexes: days,
    deadline: NotificationTime.custom(hour, 0),
  );
}

/// Every tile, in grid order (the free-form tile last).
List<WorkoutTemplate> workoutTemplatesFor(AppLocalizations l10n) {
  return [
    for (final type in WorkoutType.values) workoutTemplateFor(l10n, type),
  ];
}

/// A frequency shortcut above the weekday chips.
class PlanDayPreset {
  final String id;
  final String label;

  /// 0 = Monday … 6 = Sunday.
  final Set<int> selectedDayIndexes;

  const PlanDayPreset({
    required this.id,
    required this.label,
    required this.selectedDayIndexes,
  });
}

List<PlanDayPreset> workoutFrequencyPresets(AppLocalizations l10n) {
  return [
    PlanDayPreset(
      id: 'two_days',
      label: l10n.planDayPresetTwoDaysLabel,
      selectedDayIndexes: _tueThu,
    ),
    PlanDayPreset(
      id: 'three_days',
      label: l10n.planDayPresetThreeDaysLabel,
      selectedDayIndexes: _monWedFri,
    ),
    PlanDayPreset(
      id: 'weekdays',
      label: l10n.planDayPresetWeekdaysLabel,
      selectedDayIndexes: _weekdays,
    ),
    PlanDayPreset(
      id: 'weekend',
      label: l10n.planDayPresetWeekendLabel,
      selectedDayIndexes: _weekend,
    ),
    PlanDayPreset(
      id: 'every_day',
      label: l10n.planDayPresetEveryDayLabel,
      selectedDayIndexes: _everyDay,
    ),
  ];
}

/// A deadline chip (아침 7시 … 밤 10시). The "직접" chip is not a preset.
class DeadlinePreset {
  final String id;
  final String label;
  final int hour;
  final int minute;

  const DeadlinePreset({
    required this.id,
    required this.label,
    required this.hour,
    this.minute = 0,
  });

  NotificationTime get time => NotificationTime.custom(hour, minute);

  /// Whether [time] is exactly this chip: once a day at [hour]:[minute] with
  /// no early alert. Hourly or offset reminders from older plans only match
  /// the "직접" chip.
  bool matches(NotificationTime time) {
    return time.type != 'none' &&
        !time.isHourly &&
        time.alertOffset == 0 &&
        time.hour == hour &&
        time.minute == minute;
  }
}

List<DeadlinePreset> workoutDeadlinePresets(AppLocalizations l10n) {
  return [
    DeadlinePreset(id: 'morning', label: l10n.planDeadlineMorning, hour: 7),
    DeadlinePreset(id: 'noon', label: l10n.planDeadlineNoon, hour: 12),
    DeadlinePreset(id: 'evening', label: l10n.planDeadlineEvening, hour: 19),
    DeadlinePreset(id: 'night', label: l10n.planDeadlineNight, hour: 21),
    DeadlinePreset(
      id: 'late_night',
      label: l10n.planDeadlineLateNight,
      hour: 22,
    ),
  ];
}
