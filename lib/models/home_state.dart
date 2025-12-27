/// 홈 화면 Today Card 상태 모델
enum HomeCardState {
  /// 상태 A: 내가 해야 할 말이 있을 때 (보고 필요)
  reportNeeded,
  
  /// 상태 B: 내가 들어야 할 말이 있을 때 (확인 필요)
  checkNeeded,
  
  /// 상태 C: 전달은 했고, 확인을 기다리는 중
  waitingForCheck,
  
  /// 상태 D: 오늘은 오갈 말이 없음
  quietDay,
  
  /// 상태 E: 확인이 완료됨
  checked,
}

/// 상태 우선순위 규칙
/// 여러 상태가 동시에 가능한 경우, 아래 우선순위로 하나만 선택
extension HomeCardStatePriority on HomeCardState {
  /// 우선순위 값 (낮을수록 높은 우선순위)
  int get priority {
    switch (this) {
      case HomeCardState.checkNeeded:
        return 1; // 최우선
      case HomeCardState.reportNeeded:
        return 2;
      case HomeCardState.waitingForCheck:
        return 3;
      case HomeCardState.checked:
        return 4;
      case HomeCardState.quietDay:
        return 5; // 최하위
    }
  }
  
  /// 여러 상태 중 우선순위가 가장 높은 상태 선택
  static HomeCardState selectHighestPriority(List<HomeCardState> states) {
    if (states.isEmpty) return HomeCardState.quietDay;
    
    states.sort((a, b) => a.priority.compareTo(b.priority));
    return states.first;
  }
}

