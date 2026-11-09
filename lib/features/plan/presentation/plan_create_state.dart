import '../../../models/plan_model.dart';
import '../domain/workout_template.dart';

const _unset = Object();

/// What is still missing before a promise can be saved.
enum PlanCreateMissing {
  /// The one-line promise is empty.
  action,

  /// No weekday picked (fixed-weekday mode only). There is no "no day means
  /// every day" rule any more.
  days,

  /// No deadline. Every new promise needs one: it is the reminder time and the
  /// cut-off after which the partner hears about a missed workout.
  deadline,
}

class PlanCreateState {
  final String action;
  final String description;

  /// Weekdays, 0 = Monday … 6 = Sunday. At least one is required unless
  /// [weeklyTarget] is set.
  final Set<int> selectedDays;

  /// 주 N회 자유롭게: workouts a week (1–6) on any days, or null for the
  /// fixed weekdays in [selectedDays] (요일 정하기).
  final int? weeklyTarget;

  /// The deadline. Never `type: 'none'` once initialized.
  final NotificationTime notificationTime;

  /// The selected workout tile. Null only for a legacy plan without one that
  /// is being edited, or before any tile is picked.
  final WorkoutType? workoutType;

  /// The tile whose defaults were applied last, for analytics.
  final WorkoutTemplate? appliedTemplate;

  /// Days or deadline were changed by hand after [appliedTemplate] was applied.
  final bool editedAfterTemplate;

  /// The days came from somewhere other than a tile default (the user, the
  /// partner's plan, or the plan being edited), so picking a tile keeps them.
  final bool daysLocked;

  /// Same as [daysLocked], for the deadline.
  final bool deadlineLocked;

  /// The partner's weekdays when they were offered as the default, so the
  /// screen can say so while they are still selected.
  final Set<int>? partnerSuggestedDays;

  final bool isSaving;
  final String? errorMessage;
  final String? existingPlanId;
  final Plan? originalPlan;

  /// The optional D-day goal's title as typed ("제주 여행"); saved only with a
  /// [goalDate].
  final String goalTitle;

  /// The optional D-day goal (a calendar date). Null = no goal.
  final DateTime? goalDate;

  const PlanCreateState({
    this.action = '',
    this.description = '',
    this.selectedDays = const {},
    this.weeklyTarget,
    required this.notificationTime,
    this.workoutType,
    this.appliedTemplate,
    this.editedAfterTemplate = false,
    this.daysLocked = false,
    this.deadlineLocked = false,
    this.partnerSuggestedDays,
    this.isSaving = false,
    this.errorMessage,
    this.existingPlanId,
    this.originalPlan,
    this.goalTitle = '',
    this.goalDate,
  });

  /// Id of the tile last applied (same string as its workoutType), or null.
  String? get selectedTemplateId => appliedTemplate?.id;

  /// The first thing that still blocks saving, or null when it can be saved.
  PlanCreateMissing? get missingField {
    if (action.trim().isEmpty) return PlanCreateMissing.action;
    if (weeklyTarget == null && selectedDays.isEmpty) {
      return PlanCreateMissing.days;
    }
    if (notificationTime.type == 'none') return PlanCreateMissing.deadline;
    return null;
  }

  bool get canSave => missingField == null;

  /// 주 N회 mode is on.
  bool get isWeekly => weeklyTarget != null;

  /// Whether the selected days are still the partner's suggestion.
  bool get showsPartnerDays {
    if (isWeekly) return false;
    final suggested = partnerSuggestedDays;
    return suggested != null &&
        suggested.length == selectedDays.length &&
        suggested.containsAll(selectedDays);
  }

  PlanCreateState copyWith({
    String? action,
    String? description,
    Set<int>? selectedDays,
    Object? weeklyTarget = _unset,
    NotificationTime? notificationTime,
    Object? workoutType = _unset,
    Object? appliedTemplate = _unset,
    bool? editedAfterTemplate,
    bool? daysLocked,
    bool? deadlineLocked,
    Object? partnerSuggestedDays = _unset,
    bool? isSaving,
    String? errorMessage,
    // Sentinel rather than `String?`: initializing from an id-less template (the
    // "continue after settlement" flow copies a finished plan as a template)
    // must be able to clear the id left over from the previous save. With plain
    // null-coalescing that null was ignored and the follow-up plan saved on top
    // of the finished one.
    Object? existingPlanId = _unset,
    Plan? originalPlan,
    String? goalTitle,
    Object? goalDate = _unset,
  }) {
    return PlanCreateState(
      action: action ?? this.action,
      description: description ?? this.description,
      selectedDays: selectedDays ?? this.selectedDays,
      weeklyTarget: weeklyTarget == _unset
          ? this.weeklyTarget
          : weeklyTarget as int?,
      notificationTime: notificationTime ?? this.notificationTime,
      workoutType: workoutType == _unset
          ? this.workoutType
          : workoutType as WorkoutType?,
      appliedTemplate: appliedTemplate == _unset
          ? this.appliedTemplate
          : appliedTemplate as WorkoutTemplate?,
      editedAfterTemplate: editedAfterTemplate ?? this.editedAfterTemplate,
      daysLocked: daysLocked ?? this.daysLocked,
      deadlineLocked: deadlineLocked ?? this.deadlineLocked,
      partnerSuggestedDays: partnerSuggestedDays == _unset
          ? this.partnerSuggestedDays
          : partnerSuggestedDays as Set<int>?,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      existingPlanId: existingPlanId == _unset
          ? this.existingPlanId
          : existingPlanId as String?,
      originalPlan: originalPlan ?? this.originalPlan,
      goalTitle: goalTitle ?? this.goalTitle,
      goalDate: goalDate == _unset ? this.goalDate : goalDate as DateTime?,
    );
  }
}

sealed class PlanCreateIntent {
  const PlanCreateIntent();
}

/// Fill the screen from an existing plan (edit) or an id-less copy of one
/// (restart / continue after settlement).
class InitializePlanIntent extends PlanCreateIntent {
  final Plan plan;
  const InitializePlanIntent(this.plan);
}

/// The one-line promise was edited by hand.
class UpdateActionIntent extends PlanCreateIntent {
  final String action;
  const UpdateActionIntent(this.action);
}

class UpdateDescriptionIntent extends PlanCreateIntent {
  final String description;
  const UpdateDescriptionIntent(this.description);
}

class ToggleDayIntent extends PlanCreateIntent {
  final int dayIndex;
  const ToggleDayIntent(this.dayIndex);
}

class UpdateSelectedDaysIntent extends PlanCreateIntent {
  final Set<int> selectedDays;
  const UpdateSelectedDaysIntent(this.selectedDays);
}

/// 요일 정하기 ([weekly] false) or 주 N회 자유롭게 ([weekly] true).
class SetWeeklyModeIntent extends PlanCreateIntent {
  final bool weekly;
  const SetWeeklyModeIntent(this.weekly);
}

/// The 주 N회 stepper changed (clamped to 1–6).
class UpdateWeeklyTargetIntent extends PlanCreateIntent {
  final int target;
  const UpdateWeeklyTargetIntent(this.target);
}

class UpdateNotificationTimeIntent extends PlanCreateIntent {
  final NotificationTime notificationTime;
  const UpdateNotificationTimeIntent(this.notificationTime);
}

/// A workout tile was tapped: select it and apply its defaults.
class SelectWorkoutIntent extends PlanCreateIntent {
  final WorkoutTemplate template;
  const SelectWorkoutIntent(this.template);
}

/// Offer the partner's weekdays as the default for a new promise.
class PrefillPartnerDaysIntent extends PlanCreateIntent {
  const PrefillPartnerDaysIntent();
}

/// The D-day goal's title was typed or picked from a preset chip.
class UpdateGoalTitleIntent extends PlanCreateIntent {
  final String title;
  const UpdateGoalTitleIntent(this.title);
}

/// A D-day goal date was picked (only the calendar date is kept).
class UpdateGoalDateIntent extends PlanCreateIntent {
  final DateTime date;
  const UpdateGoalDateIntent(this.date);
}

/// The D-day goal was removed.
class ClearGoalIntent extends PlanCreateIntent {
  const ClearGoalIntent();
}

class SavePlanIntent extends PlanCreateIntent {
  const SavePlanIntent();
}

class ResetIntent extends PlanCreateIntent {
  const ResetIntent();
}
