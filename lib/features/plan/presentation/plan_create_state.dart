import '../../../models/plan_model.dart';
import '../domain/workout_template.dart';

const _unset = Object();

/// What is still missing before a promise can be saved.
enum PlanCreateMissing {
  /// The one-line promise is empty.
  action,

  /// No weekday picked. There is no "no day means every day" rule any more.
  days,

  /// No deadline. Every new promise needs one: it is the reminder time and the
  /// cut-off after which the partner hears about a missed workout.
  deadline,
}

class PlanCreateState {
  final String action;
  final String description;

  /// Weekdays, 0 = Monday … 6 = Sunday. At least one is required.
  final Set<int> selectedDays;

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

  const PlanCreateState({
    this.action = '',
    this.description = '',
    this.selectedDays = const {},
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
  });

  /// Id of the tile last applied (same string as its workoutType), or null.
  String? get selectedTemplateId => appliedTemplate?.id;

  /// The first thing that still blocks saving, or null when it can be saved.
  PlanCreateMissing? get missingField {
    if (action.trim().isEmpty) return PlanCreateMissing.action;
    if (selectedDays.isEmpty) return PlanCreateMissing.days;
    if (notificationTime.type == 'none') return PlanCreateMissing.deadline;
    return null;
  }

  bool get canSave => missingField == null;

  /// Whether the selected days are still the partner's suggestion.
  bool get showsPartnerDays {
    final suggested = partnerSuggestedDays;
    return suggested != null &&
        suggested.length == selectedDays.length &&
        suggested.containsAll(selectedDays);
  }

  PlanCreateState copyWith({
    String? action,
    String? description,
    Set<int>? selectedDays,
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
  }) {
    return PlanCreateState(
      action: action ?? this.action,
      description: description ?? this.description,
      selectedDays: selectedDays ?? this.selectedDays,
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

class SavePlanIntent extends PlanCreateIntent {
  const SavePlanIntent();
}

class ResetIntent extends PlanCreateIntent {
  const ResetIntent();
}
