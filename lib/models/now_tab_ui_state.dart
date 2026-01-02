import 'package:freezed_annotation/freezed_annotation.dart';
import 'home_state.dart';

part 'now_tab_ui_state.freezed.dart';

/// Now Tab의 전체 UI 상태
@freezed
abstract class NowTabUiState with _$NowTabUiState {
  const NowTabUiState._();

  const factory NowTabUiState({
    /// 전체 카드 리스트 (Raw Data)
    required List<HomeCardModel> allCards,

    /// 메인 실행 카드 (가장 큰 카드)
    HomeCardModel? primaryCard,

    /// 서브 실행 카드 리스트 (우측 정렬 작은 카드들)
    @Default([]) List<HomeCardModel> secondaryCards,

    /// 관리자/파트너 카드 (좌측 정렬)
    HomeCardModel? managerCard,
  }) = _NowTabUiState;

  /// HomeCardModel 리스트로부터 UI State 생성
  factory NowTabUiState.fromModels(List<HomeCardModel> models) {
    // 1. 빈 리스트 처리
    final List<HomeCardModel> processedModels = List.from(models);
    if (processedModels.isEmpty) {
      processedModels.add(const HomeCardModel(state: HomeCardState.planNeeded));
    }

    // 2. Primary Card 선정
    final primary = HomeCardStatePriority.selectPrimaryExecutorCard(
      processedModels,
    );

    // 3. Secondary Cards 선정
    final secondaries = HomeCardStatePriority.selectSecondaryExecutorCards(
      processedModels,
      primary,
    );

    // 4. Manager Quick Card 선정
    final manager = HomeCardStatePriority.selectManagerQuickCard(
      processedModels,
    );

    return NowTabUiState(
      allCards: processedModels,
      primaryCard: primary,
      secondaryCards: secondaries,
      managerCard: manager,
    );
  }
}
