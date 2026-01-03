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
        return 2; // 2순위: 지남
      case HomeCardState.emptyPlan:
        return 3; // 3순위: 계획 없음 (CTA)
      case HomeCardState.todayEmpty:
        return 4; // 4순위: 여유 (오늘 일정 없음)
      case HomeCardState.todayComplete:
        return 5; // 5순위: 오늘 완료
      // nextAction은 보통 Secondary로 보여주지만, Primary가 될 수도 있음
      default:
        return 999;
    }
  }

  /// Secondary Executor Cards (Mine Secondary) 우선순위
  int get mineSecondaryPriority {
    switch (this) {
      case HomeCardState.nextAction:
        return 1; // 다음 일정
      case HomeCardState.todayEmpty:
        return 2;
      case HomeCardState.todayComplete:
        return 3;
      default:
        // nowAction 등은 이미 Primary에 떴다면 중복 제외되어야 함
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

  /// Secondary Executor Cards 선택 (최대 3개)
  static List<HomeCardModel> selectSecondaryExecutorCards(
    List<HomeCardModel> models,
    HomeCardModel? primaryExecutorCard,
  ) {
    // Primary Executor Card와 중복 제거
    final secondaryModels = models
        .where((m) => m.state.canBeMineSecondary && m != primaryExecutorCard)
        .toList();

    if (secondaryModels.isEmpty) return [];

    secondaryModels.sort(
      (a, b) => a.state.mineSecondaryPriority.compareTo(
        b.state.mineSecondaryPriority,
      ),
    );

    // 최대 3개까지
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
