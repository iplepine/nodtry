import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'now_tab_intent.dart';
import '../../../providers/repository_provider.dart';
import 'now_tab_state.dart';

/// Now Tab의 상태 관리 및 비즈니스 로직을 담당하는 ViewModel
/// MVI 패턴의 'Model' (State Holder) 역할
class NowTabViewModel extends AsyncNotifier<NowTabState> {
  @override
  FutureOr<NowTabState> build() async {
    // 초기 데이터 로드
    return _fetchState();
  }

  /// 데이터 로드 및 State 변환
  Future<NowTabState> _fetchState() async {
    final useCase = ref.read(getNowCardsUseCaseProvider);
    final models = await useCase.execute();
    return NowTabState.fromModels(models);
  }

  /// 사용자 의도(Intent) 처리
  Future<void> dispatch(NowTabIntent intent) async {
    // 현재 상태가 로딩 중이거나 에러인 경우 처리 불가 (또는 큐잉)
    if (!state.hasValue) return;

    // Optimistic Update를 위해 현재 값 보존 (필요 시)
    // final previousState = state.value;

    try {
      if (intent is CompletePlanIntent) {
        await _completePlan(intent.planId);
      } else if (intent is CheckPartnerActionIntent) {
        await _checkPartnerAction(intent.planId);
      } else if (intent is RefreshIntent) {
        state = const AsyncValue.loading();
        state = await AsyncValue.guard(() => _fetchState());
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
    // 1. Repository 호출
    await ref.read(recordRepositoryProvider).reportCompletion(planId);

    // 2. 데이터 갱신 (Invalidate하여 다시 로드)
    //    Optimistic Update를 구현하려면 여기서 state를 직접 수정할 수도 있음
    ref.invalidateSelf();
    await future; // 재로딩 대기
  }

  Future<void> _checkPartnerAction(String planId) async {
    // 1. Repository 호출
    //    기존 로직: recordRepositoryProvider.reportCompletion(planId) -> verify?
    //    Here it seems check means confirming partner did it.
    //    Actually check partner action -> verifyHistoryItem logic?
    //    But in NowTab context, it typically means acknowledging the card.
    //    Assuming reportCompletion handles it or separate verify method.
    //    For now, relying on existing impl which was reportCompletion.
    await ref.read(recordRepositoryProvider).reportCompletion(planId);

    // 2. 데이터 갱신
    ref.invalidateSelf();
    await future;
  }

  Future<void> _skipPlan(String planId) async {
    await ref.read(recordRepositoryProvider).reportSkip(planId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> _cheerPartner(String planId, String reactionType) async {
    await ref.read(recordRepositoryProvider).cheerPartner(planId, reactionType);
    ref.invalidateSelf();
    await future;
  }

  Future<void> _passPlan(String planId) async {
    await ref.read(recordRepositoryProvider).passPlan(planId);
    ref.invalidateSelf();
    await future;
  }

  /// 디버그 전용: Fake State 주입
  /// 디버그 모드에서 다양한 UI 상태를 테스트하기 위해 사용
  void setFakeState(NowTabState fakeState) {
    state = AsyncValue.data(fakeState);
  }
}

/// ViewModel Provider 정의
final nowTabViewModelProvider =
    AsyncNotifierProvider<NowTabViewModel, NowTabState>(
      () => NowTabViewModel(),
    );
