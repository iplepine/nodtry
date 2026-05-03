import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../plan_create_state.dart';
import '../../../../models/plan_model.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../providers/home_provider.dart';
import '../../domain/study_plan_template.dart';

final planCreateViewModelProvider =
    AsyncNotifierProvider<PlanCreateViewModel, PlanCreateState>(
      PlanCreateViewModel.new,
    );

class PlanCreateViewModel extends AsyncNotifier<PlanCreateState> {
  static const _defaultSelectedDays = {0, 2, 4};
  static const _studySprintDurationDays = 28;

  @override
  FutureOr<PlanCreateState> build() {
    return _initialState();
  }

  PlanCreateState _initialState() {
    return PlanCreateState(
      selectedDays: _defaultSelectedDays,
      notificationTime: _defaultNotificationTime(),
    );
  }

  NotificationTime _defaultNotificationTime() {
    return NotificationTime.custom(21, 0);
  }

  Future<void> dispatch(PlanCreateIntent intent) async {
    final prevState = state.value!;

    if (intent is ResetIntent) {
      state = AsyncValue.data(_initialState());
    } else if (intent is UpdateActionIntent) {
      state = AsyncValue.data(
        prevState.copyWith(
          action: intent.action,
          selectedCategoryId: planCategoryCustom,
          selectedTemplateId: null,
        ),
      );
    } else if (intent is UpdateDescriptionIntent) {
      state = AsyncValue.data(
        prevState.copyWith(
          description: intent.description,
          selectedCategoryId: planCategoryCustom,
          selectedTemplateId: null,
        ),
      );
    } else if (intent is ToggleDayIntent) {
      final newDays = Set<int>.from(prevState.selectedDays);
      if (newDays.contains(intent.dayIndex)) {
        newDays.remove(intent.dayIndex);
      } else {
        newDays.add(intent.dayIndex);
      }
      state = AsyncValue.data(
        prevState.copyWith(
          selectedDays: newDays,
          selectedCategoryId: planCategoryCustom,
          selectedTemplateId: null,
        ),
      );
    } else if (intent is UpdateNotificationTimeIntent) {
      state = AsyncValue.data(
        prevState.copyWith(
          notificationTime: intent.notificationTime,
          selectedCategoryId: planCategoryCustom,
          selectedTemplateId: null,
        ),
      );
    } else if (intent is ApplyStudyTemplateIntent) {
      state = AsyncValue.data(
        prevState.copyWith(
          action: intent.template.action,
          description: intent.template.description,
          selectedDays: Set<int>.from(intent.template.selectedDayIndexes),
          notificationTime: intent.template.notificationTime,
          selectedCategoryId: intent.template.categoryId,
          selectedTemplateId: intent.template.id,
        ),
      );
    } else if (intent is SelectPlanCategoryIntent) {
      if (intent.category.id == planCategoryCustom) {
        state = AsyncValue.data(
          prevState.copyWith(
            action: '',
            description: '',
            selectedDays: _defaultSelectedDays,
            notificationTime: _defaultNotificationTime(),
            selectedCategoryId: planCategoryCustom,
            selectedTemplateId: null,
          ),
        );
      } else {
        state = AsyncValue.data(
          prevState.copyWith(
            action: '',
            description: '',
            selectedDays: _defaultSelectedDays,
            notificationTime: _defaultNotificationTime(),
            selectedCategoryId: intent.category.id,
            selectedTemplateId: null,
          ),
        );
      }
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
      final matchingTemplate = studyPlanTemplates
          .where((template) => template.action == item.title)
          .firstOrNull;
      state = AsyncValue.data(
        prevState.copyWith(
          existingPlanId: plan.id,
          originalPlan: plan,
          action: item.title,
          description: item.description ?? '',
          selectedDays: item.days.map((d) => d - 1).toSet(), // 1-7 -> 0-6
          notificationTime: item.notificationTime ?? _defaultNotificationTime(),
          selectedCategoryId:
              matchingTemplate?.categoryId ?? planCategoryCustom,
          selectedTemplateId: matchingTemplate?.id,
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
      finalDays.sort();

      final now = DateTime.now();
      final endOfStartDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

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
        startDate: now, // Always reset start date for new/restart
        endDate: endOfStartDay.add(
          const Duration(days: _studySprintDurationDays - 1),
        ),
        state: PlanState
            .pendingApproval, // Always reset to pendingApproval on save, even if editing
        items: [planItem],
        createdAt: now, // Reset created
        completedDates: prevState.existingPlanId != null
            ? (prevState.originalPlan?.completedDates ?? [])
            : [], // Reset history
        skippedDates: prevState.existingPlanId != null
            ? (prevState.originalPlan?.skippedDates ?? [])
            : [],
        verifiedDates: prevState.existingPlanId != null
            ? (prevState.originalPlan?.verifiedDates ?? [])
            : [], // Reset history
        rescuedDates: prevState.existingPlanId != null
            ? (prevState.originalPlan?.rescuedDates ?? [])
            : [],
        restedDates: prevState.existingPlanId != null
            ? (prevState.originalPlan?.restedDates ?? [])
            : [],
        lastCheerMessage: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastCheerMessage
            : null,
        lastCheerType: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastCheerType
            : null,
        lastCheerAt: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastCheerAt
            : null,
        lastPokeMessage: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastPokeMessage
            : null,
        lastPokeAt: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastPokeAt
            : null,
        lastPokeAcknowledgedAt: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastPokeAcknowledgedAt
            : null,
        lastActionNote: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastActionNote
            : null,
        lastComment: prevState.existingPlanId != null
            ? prevState.originalPlan?.lastComment
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
