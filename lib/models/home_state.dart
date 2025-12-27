/// 홈 화면 Now Card 상태 모델
enum HomeCardState {
  /// Type A: Action Card (보고 필요)
  reportNeeded,
  
  /// Type B: Response Card (확인 필요)
  checkNeeded,
  
  /// Type C: Waiting Card (확인 대기)
  waitingForCheck,
  
  /// Type D: Quiet Card (지금 할 일 없음)
  quietDay,
  
  /// Type E: Acknowledged Card (확인 완료)
  checked,
  
  /// Type F: Plan Needed Card (계획 없음)
  planNeeded,
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
      case HomeCardState.reportNeeded:
      case HomeCardState.planNeeded:
      case HomeCardState.waitingForCheck:
      case HomeCardState.checked:
      case HomeCardState.quietDay:
        return CardRole.executor;
      case HomeCardState.checkNeeded:
        return CardRole.manager;
    }
  }
  
  /// Primary Executor Card 우선순위 (낮을수록 높은 우선순위)
  /// 실천자 Primary Card로 올 수 있는 타입만
  int get executorPrimaryPriority {
    switch (this) {
      case HomeCardState.reportNeeded:
        return 1; // 최우선
      case HomeCardState.planNeeded:
        return 2;
      default:
        return 999; // Primary Executor Card로 올 수 없음
    }
  }
  
  /// Secondary Executor Card 우선순위 (낮을수록 높은 우선순위)
  /// 실천자 Secondary Card로만 올 수 있는 타입
  int get executorSecondaryPriority {
    switch (this) {
      case HomeCardState.waitingForCheck:
        return 1;
      case HomeCardState.checked:
        return 2;
      case HomeCardState.quietDay:
        return 3;
      default:
        return 999; // Secondary Executor Card로 올 수 없음
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
    return this == HomeCardState.checkNeeded;
  }
  
  /// Primary Executor Card 선택
  static HomeCardState? selectPrimaryExecutorCard(List<HomeCardState> states) {
    final primaryStates = states.where((s) => s.canBeExecutorPrimary).toList();
    if (primaryStates.isEmpty) return null;
    
    primaryStates.sort((a, b) => a.executorPrimaryPriority.compareTo(b.executorPrimaryPriority));
    return primaryStates.first;
  }
  
  /// Secondary Executor Cards 선택 (최대 3개)
  static List<HomeCardState> selectSecondaryExecutorCards(
    List<HomeCardState> states,
    HomeCardState? primaryExecutorCard,
  ) {
    // Primary Executor Card와 중복 제거
    final secondaryStates = states
        .where((s) => s.canBeExecutorSecondary && s != primaryExecutorCard)
        .toList();
    
    if (secondaryStates.isEmpty) return [];
    
    secondaryStates.sort((a, b) => a.executorSecondaryPriority.compareTo(b.executorSecondaryPriority));
    
    // 최대 3개까지
    return secondaryStates.take(3).toList();
  }
  
  /// Manager Quick Card 선택
  static HomeCardState? selectManagerQuickCard(List<HomeCardState> states) {
    final managerStates = states.where((s) => s.canBeManagerQuick).toList();
    if (managerStates.isEmpty) return null;
    
    return managerStates.first; // checkNeeded는 하나만 있을 수 있음
  }
}

