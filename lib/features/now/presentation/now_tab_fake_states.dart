import '../../../models/home_state.dart';
import '../../../models/plan_model.dart';
import 'now_tab_state.dart';

/// UI 테스트를 위한 Fake States
/// User Defined Scenarios:
/// Case 0: EmptyPlan
/// Case 1: NowAction + Overdue
/// Case 2: Overdue + NextAction
/// Case 3: TodayComplete/Empty + NextAction
class NowTabFakeStates {
  static final DateTime _now = DateTime.now();
  static final DateTime _tomorrow = _now.add(const Duration(days: 1));
  static final DateTime _threeDaysLater = _now.add(const Duration(days: 3));
  static final DateTime _yesterday = _now.subtract(const Duration(days: 1));

  // --- Helpers ---
  static Plan _createPlan(String title, DateTime date, {int hour = 0}) {
    return Plan(
      userId: 'test_user',
      startDate: date,
      endDate: date.add(const Duration(days: 7)),
      state: PlanState.active,
      createdAt: date,
      items: [
        PlanItem(
          title: title,
          days: [1, 2, 3, 4, 5, 6, 7],
          count: 7,
          notificationTime: NotificationTime(
            type: 'specific',
            value: '${hour.toString().padLeft(2, '0')}:00',
            hour: hour,
            minute: 0,
          ),
        ),
      ],
    );
  }

  // --- Case 0: EmptyPlan ---
  static NowTabState get case0_empty => NowTabState(
    allCards: const [HomeCardModel(state: HomeCardState.emptyPlan)],
    primaryCard: const HomeCardModel(state: HomeCardState.emptyPlan),
    secondaryCards: const [],
    managerCards: const [],
  );

  // --- Case 1: NowAction + Overdue ---
  static NowTabState get case1_now_overdue => NowTabState(
    allCards: [],
    primaryCard: HomeCardModel(
      state: HomeCardState.nowAction,
      plan: _createPlan('지금 운동하기', _now, hour: _now.hour),
    ),
    secondaryCards: [
      HomeCardModel(
        state: HomeCardState.overdue,
        plan: _createPlan('아침 약 먹기 (지난 일)', _yesterday, hour: 8),
      ),
    ],
    managerCards: const [],
  );

  // --- Case 2: Overdue + NextAction ---
  static NowTabState get case2_overdue_next => NowTabState(
    allCards: [],
    primaryCard: HomeCardModel(
      state: HomeCardState.overdue,
      plan: _createPlan('어제 못 한 독서', _yesterday, hour: 20),
    ),
    secondaryCards: [
      HomeCardModel(
        state: HomeCardState.nextAction,
        headerMessage: '내일 일정',
        plan: _createPlan('내일 아침 조깅', _tomorrow, hour: 7),
      ),
    ],
    managerCards: const [],
  );

  // --- Case 3: TodayComplete + NextAction ---
  static NowTabState get case3_today_next => NowTabState(
    allCards: [],
    primaryCard: const HomeCardModel(state: HomeCardState.todayComplete),
    secondaryCards: [
      HomeCardModel(
        state: HomeCardState.nextAction,
        headerMessage: '3일 뒤 일정',
        plan: _createPlan('주말 브런치', _threeDaysLater, hour: 11),
      ),
    ],
    managerCards: const [],
  );

  // --- Complex Day (Case 1 Var + Yours) ---
  static NowTabState get complexDay => NowTabState(
    allCards: [],
    primaryCard: HomeCardModel(
      state: HomeCardState.nowAction,
      plan: _createPlan('저녁 샐러드 먹기', _now, hour: 19),
    ),
    secondaryCards: [
      HomeCardModel(
        state: HomeCardState.overdue,
        plan: _createPlan('아침 약 챙겨먹기', _yesterday, hour: 8),
      ),
    ],
    managerCards: [
      HomeCardModel(
        state: HomeCardState.partnerPlanModify,
        headerMessage: '이번엔 이렇게 하기로 했어요',
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        plan: _createPlan('저녁 독서 (수정)', _now, hour: 22),
        previousPlan: _createPlan('저녁 독서 하기', _now, hour: 22),
      ),
      HomeCardModel(
        state: HomeCardState.partnerAction,
        headerMessage: '나 했어요!',
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        plan: _createPlan('아침 스트레칭', _now, hour: 7),
      ),
    ],
  );

  /// 모든 fake state의 맵
  static Map<String, NowTabState> get all => {
    'Case 0: Empty': case0_empty,
    'Case 1: Now + Overdue': case1_now_overdue,
    'Case 2: Overdue + Next': case2_overdue_next,
    'Case 3: Done + Next': case3_today_next,
    'Advanced: Complex Day': complexDay,
  };
}
