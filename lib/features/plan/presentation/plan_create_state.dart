import '../../../models/plan_model.dart';
import '../domain/study_plan_template.dart';

// part 'plan_create_state.freezed.dart'; // Removed

const _unset = Object();

class PlanCreateState {
  final int currentStep;
  final String action;
  final String description;
  final Set<int> selectedDays;
  final NotificationTime notificationTime;
  final String selectedCategoryId;
  final String? selectedTemplateId;
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
    this.selectedCategoryId = planCategoryStudy,
    this.selectedTemplateId,
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
    String? selectedCategoryId,
    Object? selectedTemplateId = _unset,
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
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedTemplateId: selectedTemplateId == _unset
          ? this.selectedTemplateId
          : selectedTemplateId as String?,
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

class ApplyStudyTemplateIntent extends PlanCreateIntent {
  final StudyPlanTemplate template;
  const ApplyStudyTemplateIntent(this.template);
}

class SelectPlanCategoryIntent extends PlanCreateIntent {
  final PlanCategory category;
  const SelectPlanCategoryIntent(this.category);
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
