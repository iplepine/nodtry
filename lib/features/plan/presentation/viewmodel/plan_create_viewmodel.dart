import 'dart:async';
// Removed unused foundation import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../plan_create_state.dart';
import '../../../../models/plan_model.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../providers/home_provider.dart';
import '../../../../services/notification_service.dart';

final planCreateViewModelProvider =
    AsyncNotifierProvider<PlanCreateViewModel, PlanCreateState>(
      PlanCreateViewModel.new,
    );

class PlanCreateViewModel extends AsyncNotifier<PlanCreateState> {
  @override
  FutureOr<PlanCreateState> build() {
    return PlanCreateState(notificationTime: NotificationTime.preset('dinner'));
  }

  Future<void> dispatch(PlanCreateIntent intent) async {
    final prevState = state.value!;

    if (intent is UpdateActionIntent) {
      state = AsyncValue.data(prevState.copyWith(action: intent.action));
    } else if (intent is UpdateFrequencyIntent) {
      state = AsyncValue.data(
        prevState.copyWith(selectedFrequency: intent.frequency),
      );
    } else if (intent is UpdateDescriptionIntent) {
      state = AsyncValue.data(
        prevState.copyWith(description: intent.description),
      );
    } else if (intent is ToggleDayIntent) {
      final newDays = Set<int>.from(prevState.selectedDays);
      if (newDays.contains(intent.dayIndex)) {
        newDays.remove(intent.dayIndex);
      } else {
        newDays.add(intent.dayIndex);
      }
      state = AsyncValue.data(prevState.copyWith(selectedDays: newDays));
    } else if (intent is UpdateNotificationTimeIntent) {
      state = AsyncValue.data(
        prevState.copyWith(notificationTime: intent.notificationTime),
      );
    } else if (intent is NextStepIntent) {
      if (prevState.currentStep < 4) {
        state = AsyncValue.data(
          prevState.copyWith(currentStep: prevState.currentStep + 1),
        );
      }
    } else if (intent is PrevStepIntent) {
      if (prevState.currentStep > 1) {
        state = AsyncValue.data(
          prevState.copyWith(currentStep: prevState.currentStep - 1),
        );
      }
    } else if (intent is SavePlanIntent) {
      await _savePlan();
    }
  }

  Future<void> _savePlan() async {
    final prevState = state.value!;
    if (prevState.action.trim().isEmpty) return;

    state = AsyncValue.data(
      prevState.copyWith(isSaving: true, errorMessage: null),
    );

    try {
      final userState = ref.read(myProfileProvider);
      final userId = userState.asData?.value?.uid;

      if (userId == null) {
        throw Exception("사용자 정보를 찾을 수 없습니다.");
      }

      final planItem = PlanItem(
        title: prevState.action,
        count: prevState.selectedFrequency,
        days: prevState.selectedDays.map((d) => d + 1).toList(),
        notificationTime: prevState.notificationTime,
      );

      final plan = Plan(
        userId: userId,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        state: PlanState.pendingApproval,
        items: [planItem],
        createdAt: DateTime.now(),
      );

      await ref.read(createNewPlanUseCaseProvider).execute(plan);

      // Provider 갱신
      ref.invalidate(homeCardStateProvider);

      // 알림 설정
      if (prevState.selectedDays.isNotEmpty ||
          prevState.notificationTime.type != 'none') {
        await NotificationService().requestPermissions();
        await NotificationService().schedulePlanReminder(
          planId: plan.createdAt.millisecondsSinceEpoch ~/ 1000,
          title: planItem.title,
          hour: prevState.notificationTime.hour,
          minute: prevState.notificationTime.minute,
          days: planItem.days,
        );
      }

      state = AsyncValue.data(prevState.copyWith(isSaving: false));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      state = AsyncValue.data(
        prevState.copyWith(isSaving: false, errorMessage: e.toString()),
      );
      rethrow;
    }
  }
}
