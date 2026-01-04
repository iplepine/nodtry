import 'package:flutter/foundation.dart';
import '../../../models/plan_model.dart';

// part 'plan_create_state.freezed.dart'; // Removed

class PlanCreateState {
  final int currentStep;
  final String action;
  final int selectedFrequency;
  final String description;
  final Set<int> selectedDays;
  final NotificationTime notificationTime;
  final bool isSaving;
  final String? errorMessage;
  final String? existingPlanId;

  const PlanCreateState({
    this.currentStep = 1,
    this.action = '',
    this.selectedFrequency = 3,
    this.description = '',
    this.selectedDays = const {},
    required this.notificationTime,
    this.isSaving = false,
    this.errorMessage,
    this.existingPlanId,
  });

  PlanCreateState copyWith({
    int? currentStep,
    String? action,
    int? selectedFrequency,
    String? description,
    Set<int>? selectedDays,
    NotificationTime? notificationTime,
    bool? isSaving,
    String? errorMessage,
    String? existingPlanId,
  }) {
    return PlanCreateState(
      currentStep: currentStep ?? this.currentStep,
      action: action ?? this.action,
      selectedFrequency: selectedFrequency ?? this.selectedFrequency,
      description: description ?? this.description,
      selectedDays: selectedDays ?? this.selectedDays,
      notificationTime: notificationTime ?? this.notificationTime,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      existingPlanId: existingPlanId ?? this.existingPlanId,
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

class UpdateFrequencyIntent extends PlanCreateIntent {
  final int frequency;
  const UpdateFrequencyIntent(this.frequency);
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
