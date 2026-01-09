import '../../../models/plan_model.dart';

// part 'plan_create_state.freezed.dart'; // Removed

class PlanCreateState {
  final int currentStep;
  final String action;
  final String description;
  final Set<int> selectedDays;
  final NotificationTime notificationTime;
  final bool isSaving;
  final String? errorMessage;
  final String? existingPlanId;
  final Plan? originalPlan;

  const PlanCreateState({
    this.currentStep = 1,
    this.action = '',
    this.description = '',
    this.selectedDays = const {},
    required this.notificationTime,
    this.isSaving = false,
    this.errorMessage,
    this.existingPlanId,
    this.originalPlan,
  });

  PlanCreateState copyWith({
    int? currentStep,
    String? action,
    String? description,
    Set<int>? selectedDays,
    NotificationTime? notificationTime,
    bool? isSaving,
    String? errorMessage,
    String? existingPlanId,
    Plan? originalPlan,
  }) {
    return PlanCreateState(
      currentStep: currentStep ?? this.currentStep,
      action: action ?? this.action,
      description: description ?? this.description,
      selectedDays: selectedDays ?? this.selectedDays,
      notificationTime: notificationTime ?? this.notificationTime,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      existingPlanId: existingPlanId ?? this.existingPlanId,
      originalPlan: originalPlan ?? this.originalPlan,
    );
  }
}

sealed class PlanCreateIntent {
  const PlanCreateIntent();
}

class InitializePlanIntent extends PlanCreateIntent {
  final Plan plan;
  const InitializePlanIntent(this.plan);
}

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

class UpdateNotificationTimeIntent extends PlanCreateIntent {
  final NotificationTime notificationTime;
  const UpdateNotificationTimeIntent(this.notificationTime);
}

class NextStepIntent extends PlanCreateIntent {
  const NextStepIntent();
}

class PrevStepIntent extends PlanCreateIntent {
  const PrevStepIntent();
}

class SavePlanIntent extends PlanCreateIntent {
  const SavePlanIntent();
}

class ResetIntent extends PlanCreateIntent {
  const ResetIntent();
}
