import '../../../models/home_state.dart';
import '../../../models/plan_model.dart';
import 'now_tab_state.dart';

/// UI 테스트를 위한 Fake States
class NowTabFakeStates {
  /// 1. 완전히 비어있는 상태 (신규 사용자)
  static NowTabState get empty => const NowTabState(
    allCards: [],
    primaryCard: null,
    secondaryCards: [],
    managerCard: null,
  );

  /// 2. 로딩 중 상태 (실제로는 AsyncValue.loading으로 처리되지만 참고용)
  static NowTabState get loading => const NowTabState(
    allCards: [],
    primaryCard: null,
    secondaryCards: [],
    managerCard: null,
  );

  /// 3. 계획 필요 상태 (Plan Needed)
  static NowTabState get planNeeded => NowTabState(
    allCards: const [HomeCardModel(state: HomeCardState.planNeeded)],
    primaryCard: const HomeCardModel(state: HomeCardState.planNeeded),
    secondaryCards: const [],
    managerCard: null,
  );

  /// 4. 지금 실천 상태 (Now Action)
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

  /// 5. 과거 미완료 상태 (Overdue Self Action)
  static NowTabState get overdueSelfAction {
    final now = DateTime.now();
    return NowTabState(
      allCards: [
        HomeCardModel(
          state: HomeCardState.overdueSelfAction,
          plan: Plan(
            userId: 'test_user',
            startDate: now.subtract(const Duration(days: 7)),
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now.subtract(const Duration(days: 7)),
            items: [
              PlanItem(
                title: '아침 조깅 30분',
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
      primaryCard: HomeCardModel(
        state: HomeCardState.overdueSelfAction,
        plan: Plan(
          userId: 'test_user',
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now.add(const Duration(days: 7)),
          state: PlanState.active,
          createdAt: now.subtract(const Duration(days: 7)),
          items: [
            PlanItem(
              title: '아침 조깅 30분',
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
      secondaryCards: const [],
      managerCard: null,
    );
  }

  /// 6. Secondary Cards가 있는 상태 (With Secondary)
  static NowTabState get withSecondary {
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
                title: '물 마시기',
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
        HomeCardModel(
          state: HomeCardState.todayDone,
          plan: Plan(
            userId: 'test_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '아침 조깅',
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
          partnerName: '지민',
          partnerImageUrl:
              'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        ),
        HomeCardModel(
          state: HomeCardState.todayDone,
          plan: Plan(
            userId: 'test_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '영양제 챙겨먹기',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '08:30',
                  hour: 8,
                  minute: 30,
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
              title: '물 마시기',
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
      secondaryCards: [
        HomeCardModel(
          state: HomeCardState.todayDone,
          plan: Plan(
            userId: 'test_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '아침 조깅',
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
          partnerName: '지민',
          partnerImageUrl:
              'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        ),
        HomeCardModel(
          state: HomeCardState.todayDone,
          plan: Plan(
            userId: 'test_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '영양제 챙겨먹기',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '08:30',
                  hour: 8,
                  minute: 30,
                ),
              ),
            ],
          ),
        ),
      ],
      managerCard: null,
    );
  }

  /// 7. Manager Card가 있는 상태 (With Manager)
  static NowTabState get withManager {
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
                title: '책 30분 읽기',
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
        HomeCardModel(
          state: HomeCardState.partnerActionShare,
          plan: Plan(
            userId: 'partner_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '스트레칭 하기',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value:
                      '${now.add(const Duration(hours: 1)).hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  hour: now.add(const Duration(hours: 1)).hour,
                  minute: now.minute,
                ),
              ),
            ],
          ),
          partnerName: '지민',
          partnerImageUrl:
              'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
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
              title: '책 30분 읽기',
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
      managerCard: HomeCardModel(
        state: HomeCardState.partnerActionShare,
        plan: Plan(
          userId: 'partner_user',
          startDate: now,
          endDate: now.add(const Duration(days: 7)),
          state: PlanState.active,
          createdAt: now,
          items: [
            PlanItem(
              title: '스트레칭 하기',
              days: [1, 2, 3, 4, 5, 6, 7],
              count: 7,
              notificationTime: NotificationTime(
                type: 'specific',
                value:
                    '${now.add(const Duration(hours: 1)).hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                hour: now.add(const Duration(hours: 1)).hour,
                minute: now.minute,
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

  /// 8. 전체 상태 (Full - Primary + Secondary + Manager)
  static NowTabState get full {
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
                title: '명상 10분',
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
        HomeCardModel(
          state: HomeCardState.todayDone,
          plan: Plan(
            userId: 'test_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '아침 조깅',
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
        HomeCardModel(
          state: HomeCardState.todayDone,
          plan: Plan(
            userId: 'test_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '영양제 먹기',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '08:30',
                  hour: 8,
                  minute: 30,
                ),
              ),
            ],
          ),
          partnerName: '지민',
          partnerImageUrl:
              'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        ),
        HomeCardModel(
          state: HomeCardState.partnerActionShare,
          plan: Plan(
            userId: 'partner_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '저녁 산책',
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
              title: '명상 10분',
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
      secondaryCards: [
        HomeCardModel(
          state: HomeCardState.todayDone,
          plan: Plan(
            userId: 'test_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '아침 조깅',
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
        HomeCardModel(
          state: HomeCardState.todayDone,
          plan: Plan(
            userId: 'test_user',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            state: PlanState.active,
            createdAt: now,
            items: [
              PlanItem(
                title: '영양제 먹기',
                days: [1, 2, 3, 4, 5, 6, 7],
                count: 7,
                notificationTime: NotificationTime(
                  type: 'specific',
                  value: '08:30',
                  hour: 8,
                  minute: 30,
                ),
              ),
            ],
          ),
          partnerName: '지민',
          partnerImageUrl:
              'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        ),
      ],
      managerCard: HomeCardModel(
        state: HomeCardState.partnerActionShare,
        plan: Plan(
          userId: 'partner_user',
          startDate: now,
          endDate: now.add(const Duration(days: 7)),
          state: PlanState.active,
          createdAt: now,
          items: [
            PlanItem(
              title: '저녁 산책',
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

  /// 9. 여유로운 날 (Relaxed Day)
  static NowTabState get relaxedDay => NowTabState(
    allCards: const [HomeCardModel(state: HomeCardState.relaxedDay)],
    primaryCard: const HomeCardModel(state: HomeCardState.relaxedDay),
    secondaryCards: const [],
    managerCard: null,
  );

  /// 모든 fake state의 맵 (개발자 화면에서 선택할 수 있도록)
  static Map<String, NowTabState> get all => {
    '비어있음 (Empty)': empty,
    '계획 필요 (Plan Needed)': planNeeded,
    '지금 실천 (Now Action)': nowAction,
    '과거 미완료 (Overdue)': overdueSelfAction,
    'Secondary 포함 (With Secondary)': withSecondary,
    'Manager 포함 (With Manager)': withManager,
    '전체 상태 (Full)': full,
    '여유로운 날 (Relaxed Day)': relaxedDay,
  };
}
