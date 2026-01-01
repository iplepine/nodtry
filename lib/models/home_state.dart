import 'plan_model.dart';

/// 홈 화면 Now Card 상태 모델
/// 홈 화면 Now Card 상태 모델
enum HomeCardState {
  /// Type 1: Now Action Card (지금 가장 가까운 시일 내 실천해야 할 항목)
  nowAction,

  /// Type 2-1: Plan Needed Card (한 달 내 계획이 없는 경우)
  planNeeded,

  /// Type 2-2 A: Today Done (오늘 다 했어요)
  todayDone,

  /// Type 2-2 B: Relaxed Day (오늘은 여유로운 날이에요)
  relaxedDay,

  /// Type 3: Partner Plan Share (상대방의 계획 제안/공유)
  partnerPlanShare,

  /// Type 4: Partner Action Share (상대방의 실천 공유 + 피드백)
  partnerActionShare,

  /// Type 5: Overdue Self Action (시간이 지나버린 내 실천)
  overdueSelfAction,
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
  /// 실천자 카드: 내가 해야 할 행동
  executor,

  /// 관리자 카드: 내가 확인해야 할 행동
  manager,
}

/// 상태 우선순위 및 계층 규칙
extension HomeCardStatePriority on HomeCardState {
  /// 카드 역할 반환
  CardRole? get role {
    switch (this) {
      case HomeCardState.nowAction:
      case HomeCardState.planNeeded:
      case HomeCardState.todayDone:
      case HomeCardState.relaxedDay:
      case HomeCardState.overdueSelfAction:
        return CardRole.executor;
      case HomeCardState.partnerPlanShare:
      case HomeCardState.partnerActionShare:
        return CardRole.manager;
    }
  }

  /// Primary Executor Card 우선순위 (낮을수록 높은 우선순위)
  int get executorPrimaryPriority {
    switch (this) {
      case HomeCardState.nowAction:
        return 1; // 1순위: 지금 실천
      case HomeCardState.overdueSelfAction:
        return 2; // 2순위: 지났지만 아직 안 한 것 (Type 5)
      case HomeCardState.planNeeded:
        return 3; // 3순위: 계획 필요
      default:
        return 999;
    }
  }

  /// Secondary Executor Card 우선순위
  int get executorSecondaryPriority {
    switch (this) {
      case HomeCardState.todayDone:
        return 1;
      case HomeCardState.relaxedDay:
        return 2;
      default:
        return 999;
    }
  }

  /// 이 상태가 Primary Executor Card로 올 수 있는지
  bool get canBeExecutorPrimary {
    return executorPrimaryPriority < 999;
  }

  /// 이 상태가 Secondary Executor Card로만 올 수 있는지
  bool get canBeExecutorSecondary {
    return executorSecondaryPriority < 999;
  }

  /// 이 상태가 Manager Quick Card로 올 수 있는지
  bool get canBeManagerQuick {
    return this == HomeCardState.partnerPlanShare ||
        this == HomeCardState.partnerActionShare;
  }

  /// Primary Executor Card 선택
  /// Primary Executor Card 선택
  static HomeCardModel? selectPrimaryExecutorCard(List<HomeCardModel> models) {
    final primaryModels = models
        .where((m) => m.state.canBeExecutorPrimary)
        .toList();
    if (primaryModels.isEmpty) return null;

    primaryModels.sort(
      (a, b) => a.state.executorPrimaryPriority.compareTo(
        b.state.executorPrimaryPriority,
      ),
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
        .where(
          (m) => m.state.canBeExecutorSecondary && m != primaryExecutorCard,
        )
        .toList();

    if (secondaryModels.isEmpty) return [];

    secondaryModels.sort(
      (a, b) => a.state.executorSecondaryPriority.compareTo(
        b.state.executorSecondaryPriority,
      ),
    );

    // 최대 3개까지
    return secondaryModels.take(3).toList();
  }

  /// Manager Quick Card 선택
  static HomeCardModel? selectManagerQuickCard(List<HomeCardModel> models) {
    final managerModels = models
        .where((m) => m.state.canBeManagerQuick)
        .toList();
    if (managerModels.isEmpty) return null;

    return managerModels.first; // checkNeeded는 하나만 있을 수 있음
  }
}

class HomeCardModel {
  final HomeCardState state;
  final Plan? plan;
  final String? partnerName;
  final String? partnerImageUrl;
  final String? headerMessage;

  const HomeCardModel({
    required this.state,
    this.plan,
    this.partnerName,
    this.partnerImageUrl,
    this.headerMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeCardModel &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          plan?.id == other.plan?.id &&
          headerMessage == other.headerMessage;

  @override
  int get hashCode =>
      state.hashCode ^ (plan?.id).hashCode ^ headerMessage.hashCode;
}
