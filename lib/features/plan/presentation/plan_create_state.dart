import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../models/plan_model.dart';

part 'plan_create_state.freezed.dart';

@freezed
abstract class PlanCreateState with _$PlanCreateState {
  const factory PlanCreateState({
    @Default(1) int currentStep,
    @Default('') String action,
    @Default(3) int selectedFrequency,
    @Default('') String description,
    @Default({}) Set<int> selectedDays,
    required NotificationTime notificationTime,
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = _PlanCreateState;
}

sealed class PlanCreateIntent {
  const PlanCreateIntent();
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
