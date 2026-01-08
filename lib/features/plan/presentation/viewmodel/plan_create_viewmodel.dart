import 'dart:async';
// Removed unused foundation import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../plan_create_state.dart';
import '../../../../models/plan_model.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../providers/home_provider.dart';

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
    } else if (intent is InitializePlanIntent) {
      final plan = intent.plan;
      final item = plan.items.first;
      state = AsyncValue.data(
        prevState.copyWith(
          existingPlanId: plan.id,
          originalPlan: plan,
          action: item.title,
          description: item.description ?? '',
          selectedFrequency: item.count,
          selectedDays: item.days.map((d) => d - 1).toSet(), // 1-7 -> 0-6
          notificationTime:
              item.notificationTime ?? NotificationTime.preset('dinner'),
          // Skip step 1 if data exists? Or let user review? Let's stay on step 1 but filled.
        ),
      );
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

      final finalDays = prevState.selectedDays.isEmpty
          ? [1, 2, 3, 4, 5, 6, 7]
          : prevState.selectedDays.map((d) => d + 1).toList();

      final planItem = PlanItem(
        title: prevState.action,
        count: prevState.selectedFrequency,
        days: finalDays,
        notificationTime: prevState.notificationTime,
        description: prevState.description, // Ensure description is saved
      );

      // 연결된 파트너 확인 (매니저 자동 지정)
      final connectedProfiles = ref.read(connectedProfilesProvider).value;
      final managerId = connectedProfiles?.firstOrNull?.user.uid;

      // Create new plan object
      final plan = Plan(
        id: prevState.existingPlanId, // Preserves ID if editing
        userId: userId,
        managerId: managerId, // 파트너가 있다면 매니저로 지정
        startDate: prevState.originalPlan?.startDate ?? DateTime.now(),
        endDate:
            prevState.originalPlan?.endDate ??
            DateTime.now().add(const Duration(days: 30)),
        state: prevState.originalPlan?.state ?? PlanState.pendingApproval,
        items: [planItem],
        createdAt: prevState.originalPlan?.createdAt ?? DateTime.now(),
        completedDates: prevState.originalPlan?.completedDates ?? [],
        verifiedDates: prevState.originalPlan?.verifiedDates ?? [],
        lastCheerMessage: prevState.originalPlan?.lastCheerMessage,
        lastCheerType: prevState.originalPlan?.lastCheerType,
        lastCheerAt: prevState.originalPlan?.lastCheerAt,
      );

      // If updating, call updatePlan.
      if (prevState.existingPlanId != null) {
        await ref.read(recordRepositoryProvider).updatePlan(plan);
      } else {
        await ref.read(createNewPlanUseCaseProvider).execute(plan);
      }

      // Provider 갱신
      ref.invalidate(homeCardStateProvider);

      // 알림 설정 (Regardlessly of create/update, reschedule)
      await ref.read(settingAlarmUseCaseProvider).execute(plan);

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
