import 'plan_model.dart';

/// 홈 화면 Now Card 상태 모델
/// 홈 화면 Now Card 상태 모델
/// 홈 화면 Now Card 상태 모델
enum HomeCardState {
  // --- Mine (나의 활동) ---
  /// Type 1: Now Action (지금 실천)
  nowAction,

  /// Type 1-2: Empty Plan (계획 없음 - CTA)
  emptyPlan,

  /// Type 1-3: Next Action (다음 일정 안내)
  nextAction,

  /// Type 1-4: Today Empty (오늘 일정 없음 - 여유)
  todayEmpty,

  /// Type 1-5: Today Complete (오늘 완료)
  todayComplete,

  /// Type 1-6: Overdue (기한 지남)
  overdue,

  // --- Yours (너의 활동) ---
  /// Type 2-1: Partner Plan Create (계획 제안)
  partnerPlanCreate,

  /// Type 2-2: Partner Plan Modify (계획 수정)
  partnerPlanModify,

  /// Type 2-3: Partner Action (실천 피드백)
  partnerAction,
}

/// 카드 계층 타입
enum CardTier {
  /// Primary Card: 지금 당장 필요한 행동
  primary,

  /// Secondary Card: 조금 뒤에 신경 쓰면 될 것
  secondary,
}

/// 카드 역할 타입
enum CardRole {
  /// Mine: 나의 행동 (Executor)
  mine,

  /// Yours: 너의 행동 (Manager/Response)
  yours,
}

/// 상태 우선순위 및 계층 규칙
extension HomeCardStatePriority on HomeCardState {
  /// 카드 역할 반환
  CardRole get role {
    switch (this) {
      case HomeCardState.nowAction:
      case HomeCardState.emptyPlan:
      case HomeCardState.nextAction:
      case HomeCardState.todayEmpty:
      case HomeCardState.todayComplete:
      case HomeCardState.overdue:
        return CardRole.mine;
      case HomeCardState.partnerPlanCreate:
      case HomeCardState.partnerPlanModify:
      case HomeCardState.partnerAction:
        return CardRole.yours;
    }
  }

  /// Primary Executor Card (Mine Primary) 우선순위
  /// 낮을수록 높은 우선순위
  int get minePrimaryPriority {
    switch (this) {
      case HomeCardState.nowAction:
        return 1; // 1순위: 지금 실천
      case HomeCardState.overdue:
        return 2; // 2순위: 지남 (NowAction 없을 때)
      case HomeCardState.todayComplete:
      case HomeCardState.todayEmpty:
        return 3; // 3순위: 오늘 완료/없음
      case HomeCardState.emptyPlan:
        return 4; // 4순위: 계획 없음 (CTA)
      default:
        return 999;
    }
  }

  /// Secondary Executor Cards (Mine Secondary) 우선순위
  int get mineSecondaryPriority {
    switch (this) {
      case HomeCardState.overdue:
        return 1; // Overdue가 Secondary로 올 때 (Primary가 NowAction일 때)
      case HomeCardState.nextAction:
        return 2; // NextAction
      default:
        return 999;
    }
  }

  /// 이 상태가 Mine Primary Card로 올 수 있는지
  bool get canBeMinePrimary {
    return minePrimaryPriority < 999;
  }

  /// 이 상태가 Mine Secondary Card로 올 수 있는지
  bool get canBeMineSecondary {
    return mineSecondaryPriority < 999;
  }

  /// 이 상태가 Yours Card (Manager Quick Card)로 올 수 있는지
  bool get canBeYours {
    return role == CardRole.yours;
  }

  /// Primary Executor Card 선택
  static HomeCardModel? selectPrimaryExecutorCard(List<HomeCardModel> models) {
    final primaryModels = models
        .where((m) => m.state.canBeMinePrimary)
        .toList();
    if (primaryModels.isEmpty) return null;

    primaryModels.sort(
      (a, b) =>
          a.state.minePrimaryPriority.compareTo(b.state.minePrimaryPriority),
    );
    return primaryModels.first;
  }

  /// Secondary Executor Cards 선택 (엄격한 시나리오 적용)
  static List<HomeCardModel> selectSecondaryExecutorCards(
    List<HomeCardModel> models,
    HomeCardModel? primaryExecutorCard,
  ) {
    if (primaryExecutorCard == null) return [];

    final primaryState = primaryExecutorCard.state;
    List<HomeCardState> allowedSecondaryStates = [];

    // 시나리오별 허용되는 Secondary 상태 정의
    switch (primaryState) {
      case HomeCardState.nowAction:
        // Case 1: NowAction + Overdue
        allowedSecondaryStates = [HomeCardState.overdue];
        break;
      case HomeCardState.overdue:
        // Case 2: Overdue + NextAction
        allowedSecondaryStates = [HomeCardState.nextAction];
        break;
      case HomeCardState.todayComplete:
      case HomeCardState.todayEmpty:
        // Case 3: Today* + NextAction
        allowedSecondaryStates = [HomeCardState.nextAction];
        break;
      case HomeCardState.emptyPlan:
      // Case 0: EmptyPlan -> No Secondary
      default:
        return [];
    }

    // 조건에 맞는 카드 필터링
    final secondaryModels = models
        .where(
          (m) =>
              allowedSecondaryStates.contains(m.state) &&
              m != primaryExecutorCard,
        )
        .toList();

    if (secondaryModels.isEmpty) return [];

    // 정렬 (Secondary Priority 기준)
    secondaryModels.sort(
      (a, b) => a.state.mineSecondaryPriority.compareTo(
        b.state.mineSecondaryPriority,
      ),
    );

    // 최대 3개까지 노출
    return secondaryModels.take(3).toList();
  }

  /// Manager Cards 선택 (다수 가능)
  static List<HomeCardModel> selectManagerCards(List<HomeCardModel> models) {
    // role이 yours인 모든 카드를 반환
    return models.where((m) => m.state.canBeYours).toList();
  }
}

class HomeCardModel {
  final HomeCardState state;
  final Plan? plan;
  final String? partnerName;
  final String? partnerImageUrl;
  final String? headerMessage;

  final Plan? previousPlan;

  const HomeCardModel({
    required this.state,
    this.plan,
    this.partnerName,
    this.partnerImageUrl,
    this.headerMessage,
    this.previousPlan,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeCardModel &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          plan?.id == other.plan?.id &&
          headerMessage == other.headerMessage &&
          previousPlan?.id == other.previousPlan?.id;

  @override
  int get hashCode =>
      state.hashCode ^
      (plan?.id).hashCode ^
      headerMessage.hashCode ^
      (previousPlan?.id).hashCode;
}
