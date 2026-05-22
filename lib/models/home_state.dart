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

  /// Type 1-8: Poked (피드백/찌르기 받음)
  poked,

  /// Type 1-7: Rejected (반려됨/조율 요청)
  rejected,

  // --- Yours (너의 활동) ---
  /// Type 2-1: Partner Plan Create (계획 제안)
  partnerPlanCreate,

  /// Type 2-2: Partner Plan Modify (계획 수정)
  partnerPlanModify,

  /// Type 2-3: Partner Action (실천 피드백)
  partnerAction,

  /// Type 2-3-2: Partner Today Complete (오늘 예정 약속 전체 완료)
  partnerTodayComplete,

  /// Type 2-4: Partner No Plan (상대방 계획 없음 - 똑똑/제안 유도)
  partnerNoPlan,

  /// Type 2-5: Partner Poke (상대방 실천 지연 - 똑똑 유도)
  partnerPoke,

  // --- Promise (약속 보상/벌칙) ---
  /// Type 3-1: 상대가 나에게 약속을 제안함 (수락/거절 필요)
  promiseProposed,

  /// Type 3-2: 내가 상대에게 약속을 제안함 (대기 중, 정보성)
  partnerPromiseProposed,

  /// Type 3-3: 약속 정산 결과 (양쪽 모두에게 노출)
  promiseSettled,

  /// Type 4-1: 4주 파일럿 정산 (실천자에게 노출)
  pilotSettlement,
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
      case HomeCardState.rejected:
      case HomeCardState.poked:
      case HomeCardState.promiseProposed:
      case HomeCardState.promiseSettled:
      case HomeCardState.pilotSettlement:
        return CardRole.mine;
      case HomeCardState.partnerPlanCreate:
      case HomeCardState.partnerPlanModify:
      case HomeCardState.partnerAction:
      case HomeCardState.partnerTodayComplete:
      case HomeCardState.partnerNoPlan:
      case HomeCardState.partnerPoke:
      case HomeCardState.partnerPromiseProposed:
        return CardRole.yours;
    }
  }

  /// Primary Executor Card (Mine Primary) 우선순위
  /// 낮을수록 높은 우선순위
  int get minePrimaryPriority {
    switch (this) {
      case HomeCardState.rejected:
        return 0; // 0순위: 반려됨 (가장 급함)
      case HomeCardState.poked:
        return 0; // 0순위: 찌르기 받음 (반려와 동급, 즉시 확인 필요)
      case HomeCardState.promiseProposed:
        return 0; // 0순위: 약속 제안 받음 (즉시 응답 필요)
      case HomeCardState.promiseSettled:
        return 0; // 0순위: 약속 정산 결과 (확인 필요)
      case HomeCardState.pilotSettlement:
        return 0; // 0순위: 파일럿 정산 응답 필요
      case HomeCardState.nowAction:
        return 1; // 1순위: 지금 실천
      case HomeCardState.overdue:
        return 2; // 2순위: 지남 (NowAction 없을 때)
      case HomeCardState.todayComplete:
      case HomeCardState.todayEmpty:
        return 4; // 4순위: 오늘 완료/없음 (이전 3)
      case HomeCardState.emptyPlan:
        return 5; // 5순위: 계획 없음 (CTA) (이전 4)
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
  final String? partnerUid; // Added
  final String? partnerName;
  final String? partnerImageUrl;
  final String? headerMessage;
  final Plan? previousPlan;
  final int? currentWeek;
  final int? totalWeeks;
  final int? streakCount; // 연속 달성 횟수
  final bool canRescue; // 파트너가 실천 인정 가능 여부

  /// 오늘 완료한 모든 플랜 (todayComplete 상태일 때만 채워짐).
  /// 길이가 2 이상이면 체크리스트 형태로 렌더링.
  final List<Plan> completedPlans;

  const HomeCardModel({
    required this.state,
    this.plan,
    this.partnerUid,
    this.partnerName,
    this.partnerImageUrl,
    this.headerMessage,
    this.previousPlan,
    this.currentWeek,
    this.totalWeeks,
    this.streakCount,
    this.canRescue = false,
    this.completedPlans = const [],
  });

  HomeCardModel copyWith({
    HomeCardState? state,
    Plan? plan,
    String? partnerUid,
    String? partnerName,
    String? partnerImageUrl,
    String? headerMessage,
    Plan? previousPlan,
    int? currentWeek,
    int? totalWeeks,
    int? streakCount,
    bool? canRescue,
    List<Plan>? completedPlans,
  }) {
    return HomeCardModel(
      state: state ?? this.state,
      plan: plan ?? this.plan,
      partnerUid: partnerUid ?? this.partnerUid,
      partnerName: partnerName ?? this.partnerName,
      partnerImageUrl: partnerImageUrl ?? this.partnerImageUrl,
      headerMessage: headerMessage ?? this.headerMessage,
      previousPlan: previousPlan ?? this.previousPlan,
      currentWeek: currentWeek ?? this.currentWeek,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      streakCount: streakCount ?? this.streakCount,
      canRescue: canRescue ?? this.canRescue,
      completedPlans: completedPlans ?? this.completedPlans,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeCardModel &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          plan?.id == other.plan?.id &&
          partnerUid == other.partnerUid &&
          partnerName == other.partnerName &&
          partnerImageUrl == other.partnerImageUrl &&
          headerMessage == other.headerMessage &&
          previousPlan?.id == other.previousPlan?.id &&
          currentWeek == other.currentWeek &&
          totalWeeks == other.totalWeeks &&
          streakCount == other.streakCount &&
          canRescue == other.canRescue &&
          _listEquals(completedPlans, other.completedPlans);

  @override
  int get hashCode =>
      state.hashCode ^
      (plan?.id).hashCode ^
      partnerUid.hashCode ^
      partnerName.hashCode ^
      partnerImageUrl.hashCode ^
      headerMessage.hashCode ^
      (previousPlan?.id).hashCode ^
      currentWeek.hashCode ^
      totalWeeks.hashCode ^
      streakCount.hashCode ^
      canRescue.hashCode ^
      Object.hashAll(completedPlans.map((p) => p.id));
}

bool _listEquals(List<Plan> a, List<Plan> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id) return false;
  }
  return true;
}
