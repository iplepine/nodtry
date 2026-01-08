import '../../../models/history_item.dart';
import '../../../models/plan_summary.dart';
import 'history_state.dart';

/// UI 테스트를 위한 Fake States
class HistoryFakeStates {
  /// 1. 완전히 비어있는 상태 (신규 사용자)
  static HistoryState get empty => const HistoryState(
    activeItems: [],
    finishedPlanSummaries: [],
    isLoading: false,
  );

  /// 2. 로딩 중 상태
  static HistoryState get loading => const HistoryState(
    activeItems: [],
    finishedPlanSummaries: [],
    isLoading: true,
  );

  /// 3. 진행 중인 약속만 있는 상태 (초기 단계)
  static HistoryState get onlyActive => HistoryState(
    activeItems: [
      HistoryItem(
        id: '1',
        planId: 'plan_morning',
        date: DateTime.now(),
        title: '아침 조깅',
        status: HistoryStatus.done,
        executorId: 'me',
        note: '상쾌하게 시작!',
        comment: '오늘도 멋진 시작이네요! 파이팅!',
      ),
      HistoryItem(
        id: '2',
        planId: 'plan_reading',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        title: '책 30분 읽기',
        status: HistoryStatus.done,
        executorId: 'partner',
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
      ),
      HistoryItem(
        id: '3',
        planId: 'plan_vitamin',
        date: DateTime.now().subtract(const Duration(days: 1)),
        title: '영양제 챙겨먹기',
        status: HistoryStatus.verified,
        executorId: 'me',
        isVerifiedByPartner: true,
      ),
    ],
    finishedPlanSummaries: [],
    isLoading: false,
  );

  /// 4. 종료된 약속만 있는 상태 (모든 계획 완료)
  static HistoryState get onlyFinished => HistoryState(
    activeItems: [],
    finishedPlanSummaries: [
      PlanSummary(
        planId: 'plan_completed_1',
        title: '매일 물 2L 마시기',
        startDate: DateTime.now().subtract(const Duration(days: 28)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        myCount: 25,
      ),
      PlanSummary(
        planId: 'plan_completed_2',
        title: '주 3회 운동하기',
        startDate: DateTime.now().subtract(const Duration(days: 21)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        myCount: 9,
      ),
    ],
    isLoading: false,
  );

  /// 5. 진행 중 + 종료된 약속 모두 있는 상태 (일반적인 상태)
  static HistoryState get mixed => HistoryState(
    activeItems: [
      // 오늘
      HistoryItem(
        id: 'today_1',
        planId: 'plan_active_1',
        date: DateTime.now(),
        title: '명상 10분',
        status: HistoryStatus.done,
        executorId: 'me',
      ),
      HistoryItem(
        id: 'today_2',
        planId: 'plan_active_2',
        date: DateTime.now().subtract(const Duration(hours: 3)),
        title: '스트레칭',
        status: HistoryStatus.done,
        executorId: 'partner',
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        isVerifiedByMe: true,
        comment: '동작이 아주 정확하네요! 👍',
      ),
      // 어제
      HistoryItem(
        id: 'yesterday_1',
        planId: 'plan_active_1',
        date: DateTime.now().subtract(const Duration(days: 1)),
        title: '명상 10분',
        status: HistoryStatus.actuallyDone,
        executorId: 'me',
        note: '늦었지만 완료했어요!',
      ),
      // 2일 전
      HistoryItem(
        id: 'two_days_ago',
        planId: 'plan_active_2',
        date: DateTime.now().subtract(const Duration(days: 2)),
        title: '스트레칭',
        status: HistoryStatus.rested,
        executorId: 'partner',
        note: '오늘은 컨디션이 안 좋아서 쉬었어요',
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        comment: '오늘 푹 쉬고 내일 다시 함께해요 🍵',
      ),
    ],
    finishedPlanSummaries: [
      PlanSummary(
        planId: 'plan_finished_1',
        title: '아침 일찍 일어나기',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().subtract(const Duration(days: 3)),
        myCount: 22,
      ),
    ],
    isLoading: false,
  );

  /// 6. 스킵된 항목이 있는 상태 (소명 필요)
  static HistoryState get withSkipped => HistoryState(
    activeItems: [
      HistoryItem(
        id: 'skip_1',
        planId: 'plan_1',
        date: DateTime.now().subtract(const Duration(days: 1)),
        title: '운동 30분',
        status: HistoryStatus.skipped,
        executorId: 'me',
      ),
      HistoryItem(
        id: 'done_1',
        planId: 'plan_1',
        date: DateTime.now(),
        title: '운동 30분',
        status: HistoryStatus.done,
        executorId: 'me',
      ),
    ],
    finishedPlanSummaries: [],
    isLoading: false,
  );

  /// 7. 많은 데이터가 있는 상태 (스크롤 테스트용)
  static HistoryState get manyItems {
    final activeItems = <HistoryItem>[];
    final executors = ['me', 'partner'];
    final titles = [
      '아침 조깅',
      '책 읽기',
      '영양제 먹기',
      '명상하기',
      '스트레칭',
      '물 마시기',
      '일기 쓰기',
    ];
    final statuses = [
      HistoryStatus.done,
      HistoryStatus.verified,
      HistoryStatus.actuallyDone,
      HistoryStatus.rested,
    ];

    for (int day = 0; day < 7; day++) {
      for (int i = 0; i < 3; i++) {
        activeItems.add(
          HistoryItem(
            id: 'item_${day}_$i',
            planId: 'plan_${i % 3}',
            date: DateTime.now().subtract(Duration(days: day, hours: i * 2)),
            title: titles[i % titles.length],
            status: statuses[i % statuses.length],
            executorId: executors[i % 2],
            partnerName: executors[i % 2] == 'partner' ? '지민' : null,
            partnerImageUrl: executors[i % 2] == 'partner'
                ? 'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin'
                : null,
            isVerifiedByMe: i % 3 == 0,
            isVerifiedByPartner: i % 3 == 1,
          ),
        );
      }
    }

    return HistoryState(
      activeItems: activeItems,
      finishedPlanSummaries: [
        PlanSummary(
          planId: 'old_plan_1',
          title: '매일 독서 30분',
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          endDate: DateTime.now().subtract(const Duration(days: 30)),
          myCount: 28,
        ),
        PlanSummary(
          planId: 'old_plan_2',
          title: '주 5회 운동',
          startDate: DateTime.now().subtract(const Duration(days: 90)),
          endDate: DateTime.now().subtract(const Duration(days: 60)),
          myCount: 18,
        ),
        PlanSummary(
          planId: 'old_plan_3',
          title: '아침 명상',
          startDate: DateTime.now().subtract(const Duration(days: 120)),
          endDate: DateTime.now().subtract(const Duration(days: 90)),
          myCount: 25,
        ),
      ],
      isLoading: false,
    );
  }

  /// 8. 오늘 날짜의 다양한 상태가 섞인 상태
  static HistoryState get todayVaried => HistoryState(
    activeItems: [
      HistoryItem(
        id: 't1',
        planId: 'plan_1',
        date: DateTime.now(),
        title: '완료한 약속',
        status: HistoryStatus.done,
        executorId: 'me',
      ),
      HistoryItem(
        id: 't2',
        planId: 'plan_2',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        title: '파트너가 확인한 약속',
        status: HistoryStatus.verified,
        executorId: 'me',
        isVerifiedByPartner: true,
      ),
      HistoryItem(
        id: 't3',
        planId: 'plan_3',
        date: DateTime.now().subtract(const Duration(hours: 4)),
        title: '파트너가 완료한 약속',
        status: HistoryStatus.done,
        executorId: 'partner',
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
      ),
      HistoryItem(
        id: 't4',
        planId: 'plan_4',
        date: DateTime.now().subtract(const Duration(hours: 6)),
        title: '내가 확인한 파트너 약속',
        status: HistoryStatus.done,
        executorId: 'partner',
        isVerifiedByMe: true,
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
      ),
    ],
    finishedPlanSummaries: [],
    isLoading: false,
  );

  /// 모든 fake state의 맵 (개발자 화면에서 선택할 수 있도록)
  static Map<String, HistoryState> get all => {
    '비어있음 (Empty)': empty,
    '로딩 중 (Loading)': loading,
    '진행 중만 (Only Active)': onlyActive,
    '종료됨만 (Only Finished)': onlyFinished,
    '진행 중 + 종료됨 (Mixed)': mixed,
    '스킵 항목 있음 (With Skipped)': withSkipped,
    '많은 데이터 (Many Items)': manyItems,
    '오늘 다양한 상태 (Today Varied)': todayVaried,
  };
}
