import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../models/home_state.dart';
import '../../../models/user_model.dart';
import '../../../widgets/quiet_header.dart';

part 'now_tab_state.freezed.dart';

/// Now Tab의 전체 UI 상태
@freezed
abstract class NowTabState with _$NowTabState {
  const NowTabState._();

  const factory NowTabState({
    /// 전체 카드 리스트 (Raw Data)
    required List<HomeCardModel> allCards,

    /// 메인 실행 카드 (가장 큰 카드)
    HomeCardModel? primaryCard,

    /// 서브 실행 카드 리스트 (우측 정렬 작은 카드들)
    @Default([]) List<HomeCardModel> secondaryCards,

    /// 관리자/파트너 카드 리스트 (좌측 정렬)
    @Default([]) List<HomeCardModel> managerCards,

    /// 헤더용 데이터
    @Default(null) UserModel? partnerProfile,
    @Default(HeaderPeriodState.inProgress) HeaderPeriodState headerPeriodState,
    @Default(null) int? currentWeek,
    @Default(null) int? totalWeeks,
  }) = _NowTabState;

  /// HomeCardModel 리스트로부터 UI State 생성
  factory NowTabState.fromModels(List<HomeCardModel> models) {
    // 1. 빈 리스트 처리
    final List<HomeCardModel> processedModels = List.from(models);
    if (processedModels.isEmpty) {
      processedModels.add(const HomeCardModel(state: HomeCardState.emptyPlan));
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

    // 4. Manager Cards 선정 (다수 가능)
    final managers = HomeCardStatePriority.selectManagerCards(processedModels);

    return NowTabState(
      allCards: processedModels,
      primaryCard: primary,
      secondaryCards: secondaries,
      managerCards: managers,
      headerPeriodState: HeaderPeriodState.noPlan,
    );
  }
}
