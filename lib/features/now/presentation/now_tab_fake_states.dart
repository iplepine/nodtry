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
  static Plan _createPlan(
    String title,
    DateTime date, {
    int hour = 0,
    String? note,
    String? comment,
  }) {
    return Plan(
      userId: 'test_user',
      startDate: date,
      endDate: date.add(const Duration(days: 7)),
      state: PlanState.active,
      createdAt: date,
      lastActionNote: note,
      lastComment: comment,
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
  static NowTabState get case0Empty => NowTabState(
    allCards: const [HomeCardModel(state: HomeCardState.emptyPlan)],
    primaryCard: const HomeCardModel(state: HomeCardState.emptyPlan),
    secondaryCards: const [],
    managerCards: const [],
  );

  // --- Case 1: NowAction + Overdue ---
  static NowTabState get case1NowOverdue => NowTabState(
    allCards: [],
    primaryCard: HomeCardModel(
      state: HomeCardState.nowAction,
      plan: _createPlan('지금 운동하기', _now, hour: _now.hour),
      currentWeek: 2,
      totalWeeks: 4,
    ),
    secondaryCards: [
      HomeCardModel(
        state: HomeCardState.overdue,
        plan: _createPlan('아침 약 먹기 (지난 일)', _yesterday, hour: 8),
        currentWeek: 1,
        totalWeeks: 4,
      ),
    ],
    managerCards: const [],
  );

  // --- Case 2: Overdue + NextAction ---
  static NowTabState get case2OverdueNext => NowTabState(
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
  static NowTabState get case3TodayNext => NowTabState(
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
      plan: _createPlan(
        '저녁 샐러드 먹기',
        _now,
        hour: 19,
        note: '오늘은 드레싱 없이 먹었어요! 뿌듯합니다.',
        comment: '오 드레싱 없이! 대단해요 🥗 칭찬합니다!',
      ),
      currentWeek: 3,
      totalWeeks: 8,
    ),
    secondaryCards: [
      HomeCardModel(
        state: HomeCardState.overdue,
        plan: _createPlan(
          '아침 약 챙겨먹기',
          _yesterday,
          hour: 8,
          note: '어제는 깜빡했네요 ㅠㅠ',
        ),
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
        plan: _createPlan(
          '아침 스트레칭',
          _now,
          hour: 7,
          note: '아침 공기가 상쾌해서 평소보다 길게 했어요 🏃‍♀️',
          comment: '상쾌한 아침이었겠네요! 멋져요!',
        ),
        currentWeek: 2,
        totalWeeks: 4,
      ),
    ],
  );

  // --- Case 4: Message Variations (Note only, Comment only, Both) ---
  static NowTabState get case4Messages => NowTabState(
    allCards: [],
    primaryCard: HomeCardModel(
      state: HomeCardState.nowAction,
      plan: _createPlan('노트만 있는 경우', _now, hour: 12, note: '실천자가 남긴 한마디입니다.'),
    ),
    secondaryCards: [
      HomeCardModel(
        state: HomeCardState.overdue,
        plan: _createPlan(
          '피드백만 있는 경우',
          _yesterday,
          hour: 10,
          comment: '매니저의 따뜻한 응원 한마디!',
        ),
      ),
    ],
    managerCards: [
      HomeCardModel(
        state: HomeCardState.partnerAction,
        headerMessage: '나 했어요!',
        partnerName: '상대방',
        plan: _createPlan(
          '둘 다 있는 경우',
          _now,
          hour: 9,
          note: '실천 소감과 함께입니다.',
          comment: '소감을 보고 답해주는 피드백입니다.',
        ),
      ),
    ],
  );

  /// 모든 fake state의 맵
  static Map<String, NowTabState> get all => {
    'Case 0: Empty': case0Empty,
    'Case 1: Now + Overdue': case1NowOverdue,
    'Case 2: Overdue + Next': case2OverdueNext,
    'Case 3: Done + Next': case3TodayNext,
    'Case 4: Variations': case4Messages,
    'Advanced: Complex Day': complexDay,
  };
}
