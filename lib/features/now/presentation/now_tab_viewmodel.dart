import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'now_tab_state.dart';
import 'now_tab_intent.dart';
import '../../../models/plan_model.dart';
import '../../../models/home_state.dart';
import '../../../models/promise_model.dart';
import '../../../providers/repository_provider.dart';
import '../../../widgets/quiet_header.dart';
import '../domain/usecases/feedback_to_partner_use_case.dart';

/// Now Tab의 상태 관리 및 비즈니스 로직을 담당하는 ViewModel
/// MVI 패턴의 'Model' (State Holder) 역할
class NowTabViewModel extends StreamNotifier<NowTabState> {
  final Set<String> _dismissedPartnerPromptKeys = {};

  @override
  Stream<NowTabState> build() {
    // Auth 변경 시 stream을 갈아끼우기 위해 watch.
    // Why: 로그아웃 후 다른 계정으로 다시 로그인할 때 이전 uid로 잠긴 Firestore
    // snapshot listener가 그대로 살아 있어서 새 계정의 plan이 안 보이는 버그가 있었다.
    ref.watch(authStateChangesProvider);
    // 앱 시작 시 기간 만료된 계획 정리
    _completeOverduePlans();
    return _fetchStateStream();
  }

  Future<void> _completeOverduePlans() async {
    try {
      final completedPlanIds = await ref
          .read(recordRepositoryProvider)
          .completeOverduePlans();
      if (!ref.mounted || completedPlanIds.isEmpty) return;

      // 완료된 계획들의 알림 제거
      final notificationService = ref.read(settingAlarmUseCaseProvider);
      for (final planId in completedPlanIds) {
        await notificationService.cancelById(planId);
      }
    } catch (e) {
      debugPrint('[NowTabViewModel] Failed to complete overdue plans: $e');
    }
  }

  /// 데이터 스트림 로드 및 State 변환
  Stream<NowTabState> _fetchStateStream() {
    final useCase = ref.watch(getNowCardsUseCaseProvider);
    final profiles = ref.watch(connectedProfilesProvider).value ?? const [];
    final profileByUid = {
      for (final profile in profiles) profile.user.uid: profile.user,
    };

    return useCase.executeStream().map((models) {
      // 헤더 정보 계산
      HeaderPeriodState periodState = HeaderPeriodState.noPlan;
      final visibleModels = _filterDismissedPartnerPrompts(models);

      // 개별 카드들에 주차 정보 주입 및 헤더 상태 결정
      for (final model in models) {
        if (model.plan != null && model.plan!.state == PlanState.active) {
          periodState = HeaderPeriodState.inProgress;
          break;
        }
      }

      final updatedModels = visibleModels.map((m) {
        int? cWeek;
        int? tWeeks;
        final resolvedPartnerUid =
            m.partnerUid ??
            (m.state.role == CardRole.yours ? m.plan?.userId : null);
        final resolvedPartnerProfile = resolvedPartnerUid == null
            ? null
            : profileByUid[resolvedPartnerUid];

        if (m.plan != null && m.plan!.state == PlanState.active) {
          final plan = m.plan!;
          final now = DateTime.now();
          final diff = now.difference(plan.startDate).inDays;
          cWeek = (diff / 7).floor() + 1;

          final totalDiff = plan.endDate.difference(plan.startDate).inDays;
          tWeeks = (totalDiff / 7).ceil();
          if (tWeeks == 0) tWeeks = 1;
        }

        return HomeCardModel(
          state: m.state,
          plan: m.plan,
          partnerUid: resolvedPartnerUid,
          partnerName:
              _nonBlank(m.partnerName) ??
              _nonBlank(resolvedPartnerProfile?.displayName),
          partnerImageUrl:
              _nonBlank(m.partnerImageUrl) ??
              _nonBlank(resolvedPartnerProfile?.profileImageUrl),
          headerMessage: m.headerMessage,
          previousPlan: m.previousPlan,
          currentWeek: cWeek,
          totalWeeks: tWeeks,
          streakCount: m.streakCount,
          canRescue: m.canRescue,
          completedPlans: m.completedPlans,
        );
      }).toList();

      final baseState = NowTabState.fromModels(updatedModels);
      final partner = profiles.isNotEmpty ? profiles.first.user : null;

      return baseState.copyWith(
        partnerProfile: partner,
        headerPeriodState: periodState,
        currentWeek: null, // 헤더에서는 더 이상 사용 안 함
        totalWeeks: null,
      );
    });
  }

  String? _nonBlank(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  /// 사용자 의도(Intent) 처리
  Future<void> dispatch(NowTabIntent intent) async {
    // 현재 상태가 로딩 중이거나 에러인 경우 처리 불가 (또는 큐잉)
    if (!state.hasValue) return;

    try {
      if (intent is CompletePlanIntent) {
        await _completePlan(intent.planId, intent.message);
      } else if (intent is CheckPartnerActionIntent) {
        await _checkPartnerAction(intent.planId);
      } else if (intent is RefreshIntent) {
        // Stream handles updates, but we can force re-fetch if needed.
        // For StreamNotifier, ref.invalidateSelf() restarts the stream.
        ref.invalidateSelf();
      } else if (intent is SkipPlanIntent) {
        await _skipPlan(intent.planId);
      } else if (intent is CheerPartnerActionIntent) {
        await _cheerPartner(intent.planId, intent.reactionType, intent.message);
      } else if (intent is PassPlanIntent) {
        await _passPlan(intent.planId);
      } else if (intent is ApprovePlanIntent) {
        await _approvePlan(intent.planId);
      } else if (intent is VerifyPartnerPlanIntent) {
        await _verifyPlan(intent.planId);
      } else if (intent is RejectPlanIntent) {
        await _rejectPlan(intent.planId, intent.reason);
      } else if (intent is AcknowledgePokeIntent) {
        await _acknowledgePoke(intent.planId);
      } else if (intent is PokeUserIntent) {
        await _pokeUser(intent.userId, intent.message);
      } else if (intent is PokePartnerIntent) {
        await _pokePartner(
          intent.planId,
          intent.message,
          intent.reward,
          intent.penalty,
        );
      } else if (intent is ProposePromiseIntent) {
        await _proposePromise(intent.planId, intent.reward, intent.penalty);
      } else if (intent is RespondPromiseIntent) {
        await _respondPromise(intent.planId, intent.accept);
      } else if (intent is RescuePlanIntent) {
        await _rescuePlan(intent.planId);
      } else if (intent is RestPlanIntent) {
        await _restPlan(intent.planId);
      } else if (intent is RecordPilotSettlementIntent) {
        await _recordPilotSettlement(
          intent.planId,
          nextPlanIntent: intent.nextPlanIntent,
          exitReason: intent.exitReason,
        );
      } else if (intent is AcknowledgePromiseSettlementIntent) {
        await _acknowledgePromiseSettlement(intent.planId, intent.comment);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _pokeUser(String userId, [String? message]) async {
    await ref.read(recordRepositoryProvider).pokeUser(userId, message: message);
    _dismissPartnerPrompt(_partnerNoPlanPromptKey(userId));
  }

  Future<void> _pokePartner(
    String planId, [
    String? message,
    PromiseReward? reward,
    PromisePenalty? penalty,
  ]) async {
    await ref
        .read(recordRepositoryProvider)
        .pokePartner(planId, message: message);
    _dismissPartnerPrompt(_partnerPokePromptKey(planId));
    if (reward != null || penalty != null) {
      await ref
          .read(recordRepositoryProvider)
          .proposePromise(planId, reward: reward, penalty: penalty);
    }
  }

  Future<void> _proposePromise(
    String planId,
    PromiseReward? reward,
    PromisePenalty? penalty,
  ) async {
    await ref
        .read(recordRepositoryProvider)
        .proposePromise(planId, reward: reward, penalty: penalty);
  }

  Future<void> _respondPromise(String planId, bool accept) async {
    await ref
        .read(recordRepositoryProvider)
        .respondPromise(planId, accept: accept);
  }

  Future<void> _completePlan(String planId, [String? message]) async {
    await ref
        .read(recordRepositoryProvider)
        .reportCompletion(planId, note: message);

    // 알람 업데이트: 오늘 알람 건너뛰기
    await _updateAlarmToSkipToday(planId);
  }

  Future<void> _checkPartnerAction(String planId) async {
    // Legacy support or specific use case
    await ref.read(recordRepositoryProvider).reportCompletion(planId);
    await _updateAlarmToSkipToday(planId);
  }

  Future<void> _skipPlan(String planId) async {
    await ref.read(recordRepositoryProvider).reportSkip(planId);
    await _updateAlarmToSkipToday(planId);
  }

  Future<void> _updateAlarmToSkipToday(String planId) async {
    try {
      final currentAllCards = state.asData?.value.allCards ?? [];
      Plan? targetPlan;
      for (final card in currentAllCards) {
        if (card.plan?.id == planId) {
          targetPlan = card.plan;
          break;
        }
      }

      if (targetPlan != null) {
        await ref
            .read(settingAlarmUseCaseProvider)
            .execute(targetPlan, skipToday: true);
      }
    } catch (e) {
      // 알람 업데이트 실패가 실천 보고 자체를 방해하지 않도록 swallow
      debugPrint('[NowTabViewModel] Failed to update alarm to skip today: $e');
    }
  }

  Future<void> _cheerPartner(
    String planId,
    String reactionType, [
    String? message,
  ]) async {
    await ref
        .read(feedbackToPartnerUseCaseProvider)
        .execute(planId: planId, reactionType: reactionType, message: message);
  }

  Future<void> _passPlan(String planId) async {
    await ref.read(recordRepositoryProvider).passPlan(planId);
  }

  Future<void> _approvePlan(String planId) async {
    await ref.read(recordRepositoryProvider).approvePlan(planId);
  }

  Future<void> _rejectPlan(String planId, String? reason) async {
    await ref.read(recordRepositoryProvider).rejectPlan(planId, reason: reason);
    // 거절된 계획의 알림 제거
    await ref.read(settingAlarmUseCaseProvider).cancelById(planId);
  }

  Future<void> _verifyPlan(String planId) async {
    await ref.read(recordRepositoryProvider).verifyPlan(planId);
  }

  Future<void> _acknowledgePoke(String planId) async {
    await ref.read(recordRepositoryProvider).acknowledgePoke(planId);
  }

  List<HomeCardModel> _filterDismissedPartnerPrompts(
    List<HomeCardModel> models,
  ) {
    if (_dismissedPartnerPromptKeys.isEmpty) {
      return models;
    }

    return models.where((model) {
      final key = _partnerPromptKey(model);
      return key == null || !_dismissedPartnerPromptKeys.contains(key);
    }).toList();
  }

  String? _partnerPromptKey(HomeCardModel model) {
    switch (model.state) {
      case HomeCardState.partnerNoPlan:
        final partnerUid = model.partnerUid;
        return partnerUid == null ? null : _partnerNoPlanPromptKey(partnerUid);
      case HomeCardState.partnerPoke:
        final planId = model.plan?.id;
        return planId == null ? null : _partnerPokePromptKey(planId);
      default:
        return null;
    }
  }

  String _partnerNoPlanPromptKey(String partnerUid) {
    return 'partnerNoPlan:${_todayKey()}:$partnerUid';
  }

  String _partnerPokePromptKey(String planId) {
    return 'partnerPoke:${_todayKey()}:$planId';
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _dismissPartnerPrompt(String key) {
    _dismissedPartnerPromptKeys.add(key);

    final currentState = state.asData?.value;
    if (currentState == null) return;

    final visibleModels = _filterDismissedPartnerPrompts(currentState.allCards);
    final nextState = NowTabState.fromModels(visibleModels).copyWith(
      partnerProfile: currentState.partnerProfile,
      headerPeriodState: currentState.headerPeriodState,
      currentWeek: currentState.currentWeek,
      totalWeeks: currentState.totalWeeks,
    );
    state = AsyncValue.data(nextState);
  }

  Future<void> _rescuePlan(String planId) async {
    await ref.read(recordRepositoryProvider).rescuePlan(planId);
  }

  Future<void> _restPlan(String planId) async {
    await ref.read(recordRepositoryProvider).reportRest(planId);
    await _updateAlarmToSkipToday(planId);
  }

  Future<void> _acknowledgePromiseSettlement(
    String planId,
    String? comment,
  ) async {
    await ref
        .read(recordRepositoryProvider)
        .acknowledgePromiseSettlement(planId, comment: comment);
  }

  Future<void> _recordPilotSettlement(
    String planId, {
    required String nextPlanIntent,
    String? exitReason,
  }) async {
    await ref
        .read(recordRepositoryProvider)
        .recordPilotSettlement(
          planId,
          nextPlanIntent: nextPlanIntent,
          exitReason: exitReason,
        );
  }

  /// 디버그 전용: Fake State 주입
  void setFakeState(NowTabState fakeState) {
    // StreamNotifier doesn't support state assignment directly like AsyncNotifier for data.
    // However, AsyncValue.data is compatible.
    // But overriding the stream is harder.
    // For Debug mode, we might just want to return a stream of this state.
    // Simplest way for now: ignore or create a mock stream provider override in test.
    state = AsyncValue.data(fakeState);
  }
}

/// ViewModel Provider 정의
final nowTabViewModelProvider =
    StreamNotifierProvider<NowTabViewModel, NowTabState>(
      () => NowTabViewModel(),
    );
