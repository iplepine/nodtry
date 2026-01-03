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
    managerCard: null,
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
      managerCard: null,
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
          state: HomeCardState
              .nowAction, // "Still Actionable" for today's past task
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
      ],
      managerCard: HomeCardModel(
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
      managerCard: null,
    );
  }

  /// 5. 파트너 제안 (Partner Proposal)
  static NowTabState get partnerProposal {
    final now = DateTime.now();
    return NowTabState(
      allCards: [],
      primaryCard: const HomeCardModel(state: HomeCardState.todayEmpty),
      secondaryCards: [],
      managerCard: HomeCardModel(
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
