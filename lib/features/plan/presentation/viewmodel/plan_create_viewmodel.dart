import 'dart:async';
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
    return _initialState();
  }

  PlanCreateState _initialState() {
    return PlanCreateState(notificationTime: NotificationTime.preset('dinner'));
  }

  Future<void> dispatch(PlanCreateIntent intent) async {
    final prevState = state.value!;

    if (intent is ResetIntent) {
      state = AsyncValue.data(_initialState());
    } else if (intent is UpdateActionIntent) {
      state = AsyncValue.data(prevState.copyWith(action: intent.action));
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
      if (prevState.currentStep < 3) {
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
          selectedDays: item.days.map((d) => d - 1).toSet(), // 1-7 -> 0-6
          notificationTime:
              item.notificationTime ?? NotificationTime.preset('dinner'),
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
        count: finalDays.length, // Frequency is now determined by dayscount
        days: finalDays,
        notificationTime: prevState.notificationTime,
        description: prevState.description,
      );

      final connectedProfiles = ref.read(connectedProfilesProvider).value;
      final managerId = connectedProfiles?.firstOrNull?.user.uid;

      final plan = Plan(
        id: prevState.existingPlanId, // null for restart/new
        userId: userId,
        managerId: managerId,
        startDate: DateTime.now(), // Always reset start date for new/restart
        endDate: DateTime.now().add(const Duration(days: 14)),
        state: PlanState
            .pendingApproval, // Always reset to pendingApproval on save, even if editing
        items: [planItem],
        createdAt: DateTime.now(), // Reset created
        completedDates: prevState.existingPlanId != null
            ? (prevState.originalPlan?.completedDates ?? [])
            : [], // Reset history
        verifiedDates: prevState.existingPlanId != null
            ? (prevState.originalPlan?.verifiedDates ?? [])
            : [], // Reset history
        lastCheerMessage: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastCheerMessage
            : null,
        lastCheerType: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastCheerType
            : null,
        lastCheerAt: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastCheerAt
            : null,
      );

      String planId;
      if (prevState.existingPlanId != null) {
        await ref.read(recordRepositoryProvider).updatePlan(plan);
        planId = prevState.existingPlanId!;
      } else {
        planId = await ref.read(createNewPlanUseCaseProvider).execute(plan);
      }

      ref.invalidate(homeCardStateProvider);
      // 생성된 ID가 반영된 Plan 객체로 알람 설정
      await ref
          .read(settingAlarmUseCaseProvider)
          .execute(plan.copyWith(id: planId));

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
