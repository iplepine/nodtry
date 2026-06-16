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

    /// 메인 카드 슬롯에서 좌우 스와이프로 순회할 오늘의 실천 카드 리스트.
    /// primaryCard 가 항상 [0]번째이며 비어있거나 1개면 스와이프 비활성.
    @Default([]) List<HomeCardModel> primaryCarouselCards,

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

    // 4. Primary 캐러셀 구성: primary 가 nowAction/overdue/nextAction 이면 같은
    //    슬롯에서 좌우 스와이프로 오늘의 다른 실천(지금 + 이따 + 지난)을 순회한다.
    final carousel = _buildPrimaryCarousel(processedModels, primary);

    // 5. Manager Cards 선정 (다수 가능)
    final managers = HomeCardStatePriority.selectManagerCards(processedModels);

    return NowTabState(
      allCards: processedModels,
      primaryCard: primary,
      primaryCarouselCards: carousel,
      secondaryCards: secondaries,
      managerCards: managers,
      headerPeriodState: HeaderPeriodState.noPlan,
    );
  }

  static List<HomeCardModel> _buildPrimaryCarousel(
    List<HomeCardModel> models,
    HomeCardModel? primary,
  ) {
    if (primary == null) return const [];
    if (primary.state != HomeCardState.nowAction &&
        primary.state != HomeCardState.overdue &&
        primary.state != HomeCardState.nextAction) {
      return [primary];
    }

    final due = models
        .where((m) => m.state == HomeCardState.nowAction)
        .toList();
    final later = models
        .where((m) => m.state == HomeCardState.nextAction)
        .toList();
    final overdue = models
        .where((m) => m.state == HomeCardState.overdue)
        .toList();

    // primary 부터 노출 후 같은 슬롯에서 우측 스와이프로
    // 지금(due) → 이따(later) → 지난(overdue) 순으로 오늘 타임라인을 훑는다.
    final ordered = <HomeCardModel>[primary];
    for (final m in due) {
      if (!identical(m, primary)) ordered.add(m);
    }
    for (final m in later) {
      if (!identical(m, primary)) ordered.add(m);
    }
    for (final m in overdue) {
      if (!identical(m, primary)) ordered.add(m);
    }
    return ordered;
  }
}
