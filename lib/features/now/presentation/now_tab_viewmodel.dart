import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'now_tab_intent.dart';
import '../../../providers/repository_provider.dart';
import 'now_tab_state.dart';

/// Now Tab의 상태 관리 및 비즈니스 로직을 담당하는 ViewModel
/// MVI 패턴의 'Model' (State Holder) 역할
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
    return useCase.executeStream().map((models) {
      return NowTabState.fromModels(models);
    });
  }

  /// 사용자 의도(Intent) 처리
  Future<void> dispatch(NowTabIntent intent) async {
    // 현재 상태가 로딩 중이거나 에러인 경우 처리 불가 (또는 큐잉)
    if (!state.hasValue) return;

    try {
      if (intent is CompletePlanIntent) {
        await _completePlan(intent.planId);
      } else if (intent is CheckPartnerActionIntent) {
        await _checkPartnerAction(intent.planId);
      } else if (intent is RefreshIntent) {
        // Stream handles updates, but we can force re-fetch if needed.
        // For StreamNotifier, ref.invalidateSelf() restarts the stream.
        ref.invalidateSelf();
      } else if (intent is SkipPlanIntent) {
        await _skipPlan(intent.planId);
      } else if (intent is CheerPartnerActionIntent) {
        await _cheerPartner(intent.planId, intent.reactionType);
      } else if (intent is PassPlanIntent) {
        await _passPlan(intent.planId);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _completePlan(String planId) async {
    await ref.read(recordRepositoryProvider).reportCompletion(planId);
    // Stream updates automatically, no need to invalidate manually for logic correctness
    // BUT for Optimistic UI or immediate feedback, we rely on the repository emitting the new event.
  }

  Future<void> _checkPartnerAction(String planId) async {
    await ref.read(recordRepositoryProvider).reportCompletion(planId);
  }

  Future<void> _skipPlan(String planId) async {
    await ref.read(recordRepositoryProvider).reportSkip(planId);
  }

  Future<void> _cheerPartner(String planId, String reactionType) async {
    await ref.read(recordRepositoryProvider).cheerPartner(planId, reactionType);
  }

  Future<void> _passPlan(String planId) async {
    await ref.read(recordRepositoryProvider).passPlan(planId);
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
