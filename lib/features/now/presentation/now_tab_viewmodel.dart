import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'now_tab_state.dart';
import 'now_tab_intent.dart';
import '../../../models/plan_model.dart';
import '../../../models/home_state.dart';
import '../../../models/connected_user.dart';
import '../../../providers/repository_provider.dart';
import '../../../widgets/quiet_header.dart';
import '../domain/usecases/feedback_to_partner_use_case.dart';

/// Now Tab의 상태 관리 및 비즈니스 로직을 담당하는 ViewModel
/// MVI 패턴의 'Model' (State Holder) 역할
class NowTabViewModel extends StreamNotifier<NowTabState> {
  @override
  Stream<NowTabState> build() {
    return _fetchStateStream();
  }

  /// 데이터 스트림 로드 및 State 변환
  Stream<NowTabState> _fetchStateStream() {
    final useCase = ref.watch(getNowCardsUseCaseProvider);
    final partnerStream = Stream.fromFuture(
      ref.watch(connectedProfilesProvider.future),
    );

    return CombineLatestStream.combine2(
      useCase.executeStream(),
      partnerStream,
      (List<HomeCardModel> models, List<ConnectedUser> profiles) {
        // 헤더 정보 계산
        HeaderPeriodState periodState = HeaderPeriodState.noPlan;

        // 개별 카드들에 주차 정보 주입 및 헤더 상태 결정
        final updatedModels = models.map((m) {
          int? cWeek;
          int? tWeeks;

          if (m.plan != null && m.plan!.state == PlanState.active) {
            periodState =
                HeaderPeriodState.inProgress; // 하나라도 활성이면 헤더는 inProgress

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
            partnerName: m.partnerName,
            partnerImageUrl: m.partnerImageUrl,
            headerMessage: m.headerMessage,
            previousPlan: m.previousPlan,
            currentWeek: cWeek,
            totalWeeks: tWeeks,
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
      },
    );
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
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _completePlan(String planId, [String? message]) async {
    await ref
        .read(recordRepositoryProvider)
        .reportCompletion(planId, note: message);
    // Stream updates automatically, no need to invalidate manually for logic correctness
    // BUT for Optimistic UI or immediate feedback, we rely on the repository emitting the new event.
  }

  Future<void> _checkPartnerAction(String planId) async {
    // Legacy support or specific use case
    await ref.read(recordRepositoryProvider).reportCompletion(planId);
  }

  Future<void> _skipPlan(String planId) async {
    await ref.read(recordRepositoryProvider).reportSkip(planId);
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
  }

  Future<void> _verifyPlan(String planId) async {
    await ref.read(recordRepositoryProvider).verifyPlan(planId);
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
