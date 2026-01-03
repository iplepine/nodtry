import '../../../models/home_state.dart';
import '../../../models/plan_model.dart';
import 'now_tab_state.dart';

/// UI 테스트를 위한 Fake States
class NowTabFakeStates {
  /// 1. 계획 필요 (Plan Needed) - 신규 유저 또는 계획 없음
  static NowTabState get planNeeded => NowTabState(
    allCards: const [HomeCardModel(state: HomeCardState.emptyPlan)],
    primaryCard: const HomeCardModel(state: HomeCardState.emptyPlan),
    secondaryCards: const [],
    managerCards: const [],
  );

  /// 2. 지금 실천 (Now Action) - 가장 일반적인 케이스
  static NowTabState get nowAction {
    final now = DateTime.now();
    return NowTabState(
      allCards: [
        HomeCardModel(
          state: HomeCardState.nowAction,
          plan: Plan(
            userId: 'test_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '명상 10분 하기',
                description: '편안한 마음으로 시작해요',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value:
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  hour: now.hour,
                  minute: now.minute,
                ),
              ),
            ],
          ),
        ),
      ],
      primaryCard: HomeCardModel(
        state: HomeCardState.nowAction,
        plan: Plan(
          userId: 'test_user',
          startDate: now,
          endDate: now.add(const Duration(days: 7)),
          state: PlanState.active,
          createdAt: now,
          items: [
            PlanItem(
              title: '명상 10분 하기',
              description: '편안한 마음으로 시작해요',
              days: [1, 2, 3, 4, 5, 6, 7],
              count: 7,
              notificationTime: NotificationTime(
                type: 'specific',
                value:
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                hour: now.hour,
                minute: now.minute,
              ),
            ),
          ],
        ),
      ),
      secondaryCards: const [],
      managerCards: const [],
    );
  }

  /// 3. 복잡한 하루 (Complex Day) - 실천 + 미완료 + 파트너 요청
  static NowTabState get complexDay {
    final now = DateTime.now();
    return NowTabState(
      allCards: [],
      primaryCard: HomeCardModel(
        state: HomeCardState.nowAction,
        plan: Plan(
          userId: 'test_user',
          startDate: now,
          endDate: now.add(const Duration(days: 7)),
          state: PlanState.active,
          createdAt: now,
          items: [
            PlanItem(
              title: '저녁 샐러드 먹기',
              description: '가볍게 먹으니까 속이 편해요',
              days: [1, 2, 3, 4, 5, 6, 7],
              count: 7,
              notificationTime: NotificationTime(
                type: 'specific',
                value: '19:00',
                hour: 19,
                minute: 0,
              ),
            ),
          ],
        ),
      ),
      secondaryCards: [
        HomeCardModel(
          state: HomeCardState.overdue,
          plan: Plan(
            userId: 'test_user',
            startDate: now.subtract(const Duration(days: 7)),
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now.subtract(const Duration(days: 7)),
            items: [
              PlanItem(
                title: '아침 약 챙겨먹기',
                description: '마그네슘 약 2알씩 먹기',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '08:00',
                  hour: 8,
                  minute: 0,
                ),
              ),
            ],
          ),
        ),
        HomeCardModel(
          state: HomeCardState.nextAction, // Future action
          headerMessage: '내일 일정',
          plan: Plan(
            userId: 'test_user',
            startDate: now.add(const Duration(days: 1)),
            endDate: now.add(const Duration(days: 8)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '조깅 하기',
                description: '아침 30분 가볍게 뛰기',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '07:00',
                  hour: 7,
                  minute: 0,
                ),
              ),
            ],
          ),
        ),
      ],
      managerCards: [
        HomeCardModel(
          state: HomeCardState.partnerPlanCreate,
          headerMessage: '이런 약속을 제안했어요',
          plan: Plan(
            userId: 'partner_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '주말 등산',
                description: '관악산 어때요?',
                days: [6, 7],
                count: 2,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '09:00',
                  hour: 9,
                  minute: 0,
                ),
              ),
            ],
          ),
          partnerName: '지민',
          partnerImageUrl:
              'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        ),
        HomeCardModel(
          state: HomeCardState.partnerPlanModify,
          headerMessage: '이번엔 이렇게 하기로 했어요',
          plan: Plan(
            userId: 'partner_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '저녁 독서',
                description: '30분만 읽기 (수정됨)',
                days: [1, 2, 3, 4, 5],
                count: 5,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '22:00',
                  hour: 22,
                  minute: 0,
                ),
              ),
            ],
          ),
          partnerName: '지민',
          partnerImageUrl:
              'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
          previousPlan: Plan(
            userId: 'partner_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '저녁 독서 하기',
                description: '1시간 동안 읽기',
                days: [1, 2, 3, 4, 5],
                count: 5,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '22:00',
                  hour: 22,
                  minute: 0,
                ),
              ),
            ],
          ),
        ),
        HomeCardModel(
          state: HomeCardState.partnerAction,
          headerMessage: '나 했어요!',
          plan: Plan(
            userId: 'partner_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '저녁 샐러드 먹기',
                description: '가볍게 먹으니까 속이 편해요',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '19:00',
                  hour: 19,
                  minute: 0,
                ),
              ),
            ],
          ),
          partnerName: '지민',
          partnerImageUrl:
              'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        ),
      ],
    );
  }

  /// 4. 여유 + 다가오는 일정 (Relaxed + Upcoming)
  static NowTabState get relaxedWithUpcoming {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return NowTabState(
      allCards: [],
      primaryCard: const HomeCardModel(state: HomeCardState.todayEmpty),
      secondaryCards: [
        HomeCardModel(
          state: HomeCardState.nextAction, // Use explicit nextAction state
          headerMessage: '내일 일정',
          plan: Plan(
            userId: 'test_user',
            startDate: tomorrow,
            endDate: tomorrow.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '친구와 브런치',
                description: '오전 11시 강남역',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '11:00',
                  hour: 11,
                  minute: 0,
                ),
              ),
            ],
          ),
        ),
      ],
      managerCards: const [],
    );
  }

  /// 5. 파트너 제안 (Partner Proposal)
  static NowTabState get partnerProposal {
    final now = DateTime.now();
    return NowTabState(
      allCards: [],
      primaryCard: const HomeCardModel(state: HomeCardState.todayEmpty),
      secondaryCards: [],
      managerCards: [
        HomeCardModel(
          state: HomeCardState.partnerPlanCreate,
          headerMessage: '같이 맞춰보는 중이에요',
          plan: Plan(
            userId: 'partner_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '주말 클라이밍',
                description: '같이 하면 더 재밌을 것 같아서!',
                days: [6, 7],
                count: 2,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '10:00',
                  hour: 10,
                  minute: 0,
                ),
              ),
            ],
          ),
          partnerName: '지민',
          partnerImageUrl:
              'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        ),
      ],
    );
  }

  /// 모든 fake state의 맵
  static Map<String, NowTabState> get all => {
    '1. 계획 필요 (Plan Needed)': planNeeded,
    '2. 지금 실천 (Now Action)': nowAction,
    '3. 복잡한 하루 (Complex Day)': complexDay,
    '4. 여유 + 내일 (Relaxed + Upcoming)': relaxedWithUpcoming,
    '5. 파트너 제안 (Partner Proposal)': partnerProposal,
  };
}
