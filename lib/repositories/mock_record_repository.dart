import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';
import 'record_repository.dart';

/// Mock 데이터 저장소 구현체
class MockRecordRepository implements RecordRepository {
  // 테스트용 상태 설정
  // 개발자 화면에서 이 값을 변경하여 다양한 시나리오 테스트 가능
  // 테스트용 상태 설정
  // 개발자 화면에서 이 값을 변경하여 다양한 시나리오 테스트 가능
  List<HomeCardModel> _mockHomeCardModels = [
    const HomeCardModel(state: HomeCardState.planNeeded),
  ];

  List<HistoryItem> _mockHistoryItems = [];

  MockRecordRepository() {
    _mockHistoryItems = _buildInitialMockHistory();
  }

  List<HistoryItem> _buildInitialMockHistory() {
    return [
      HistoryItem(
        id: '1',
        date: DateTime.now().subtract(const Duration(days: 1)), // 어제
        title: '책 30분 읽기',
        status: HistoryStatus.verified,
        executorId: 'partner',
        isVerifiedByMe: true,
        comment: '어제도 고마워요. 덕분에 책 읽는 시간이 생겼어요.',
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
      ),
      HistoryItem(
        id: '2',
        date: DateTime.now().subtract(const Duration(days: 2)), // 2일 전
        title: '매일 스쿼트 50회',
        status: HistoryStatus.actuallyDone,
        executorId: 'me',
        isVerifiedByPartner: true,
        comment: '뒤늦게라도 완료!',
      ),
      HistoryItem(
        id: '3',
        date: DateTime.now().subtract(const Duration(days: 3)), // 3일 전
        title: '책 30분 읽기',
        status: HistoryStatus.done,
        executorId: 'partner',
        isVerifiedByMe: false, // 아직 확인 안 함
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
      ),
      HistoryItem(
        id: '4',
        date: DateTime.now().subtract(const Duration(days: 4)), // 4일 전
        title: '영양제 챙겨 먹기',
        status: HistoryStatus.rested,
        executorId: 'me',
        comment: '오늘은 컨디션 난조로 쉬어갔어요.',
      ),
    ];
  }

  @override
  Future<List<HomeCardModel>> getHomeCardStates() async {
    // 네트워크 딜레이 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockHomeCardModels;
  }

  @override
  Future<List<HistoryItem>> getHistoryItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockHistoryItems;
  }

  @override
  Future<void> createPlan(Plan plan) async {
    // Mock: 1초 딜레이 후 성공
    await Future.delayed(const Duration(seconds: 1));
    // 상태를 Active로 변경 시뮬레이션
    _mockHomeCardModels = [
      const HomeCardModel(state: HomeCardState.reportNeeded),
    ]; // 계획 생기면 ReportNeeded 상태로?
  }

  // Mock 전용 메서드: 복잡한 상태 시나리오 설정
  void setScenario(MockScenario scenario) {
    switch (scenario) {
      case MockScenario.planNeeded:
        _mockHomeCardModels = [
          const HomeCardModel(state: HomeCardState.planNeeded),
        ];
        break;
      case MockScenario.quietDay:
        _mockHomeCardModels = [
          const HomeCardModel(state: HomeCardState.quietDay),
        ];
        break;
      case MockScenario.reportNeeded_Morning:
        final plan = _createMockPlan(8, 0, '아침 조깅');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.reportNeeded, plan: plan),
        ];
        break;
      case MockScenario.reportNeeded_Afternoon:
        final plan = _createMockPlan(14, 0, '오후 독서');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.reportNeeded, plan: plan),
        ];
        break;
      case MockScenario.reportNeeded_Night:
        final plan = _createMockPlan(23, 0, '밤 명상');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.reportNeeded, plan: plan),
        ];
        break;
      case MockScenario.waitingForCheck:
        _mockHomeCardModels = [
          const HomeCardModel(state: HomeCardState.waitingForCheck),
        ];
        break;
      case MockScenario.checked:
        _mockHomeCardModels = [
          const HomeCardModel(state: HomeCardState.checked),
        ];
        break;
      case MockScenario.pastUncompleted:
        _mockHomeCardModels = [
          HomeCardModel(
            state: HomeCardState.pastUncompleted,
            plan: _createMockPlan(DateTime.now().hour - 1, 0, '이미 지남'),
          ),
        ];
        break;
      case MockScenario.multiPlanSelection:
        _mockHomeCardModels = [
          HomeCardModel(
            state: HomeCardState.pastUncompleted,
            plan: _createMockPlan(DateTime.now().hour - 1, 0, '1시간 전 약속'),
          ),
          HomeCardModel(
            state: HomeCardState.reportNeeded,
            plan: _createMockPlan(
              DateTime.now().hour + 1,
              0,
              '1시간 뒤 약속 (Primary)',
            ),
          ),
          HomeCardModel(
            state: HomeCardState.reportNeeded,
            plan: _createMockPlan(
              DateTime.now().hour + 3,
              0,
              '3시간 뒤 약속 (Secondary 대기)',
            ),
          ),
        ];
        break;
    }
  }

  Plan _createMockPlan(int hour, int minute, String title) {
    return Plan(
      userId: 'mock_user',
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 7)),
      state: PlanState.active,
      items: [
        PlanItem(
          title: title,
          days: [1, 2, 3, 4, 5, 6, 7],
          count: 7,
          notificationTime: NotificationTime.custom(hour, minute),
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deletePlansByUserId(String uid) async {
    // Mock: 딜레이만
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> reconcilePlan(String planId, HistoryStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // 선택된 항목을 목록에서 제거하거나 상태를 변경함
    _mockHomeCardModels.removeWhere((m) => m.plan?.id == planId);
  }

  @override
  Future<void> verifyHistoryItem(String historyId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockHistoryItems.indexWhere((item) => item.id == historyId);
    if (index != -1) {
      final item = _mockHistoryItems[index];
      _mockHistoryItems[index] = HistoryItem(
        id: item.id,
        date: item.date,
        title: item.title,
        status: item.status,
        executorId: item.executorId,
        isVerifiedByMe: true, // 내가 확인함
        isVerifiedByPartner: item.isVerifiedByPartner,
        comment: item.comment,
        partnerName: item.partnerName,
        partnerImageUrl: item.partnerImageUrl,
      );
    }
  }
}

enum MockScenario {
  planNeeded,
  quietDay,
  reportNeeded_Morning,
  reportNeeded_Afternoon,
  reportNeeded_Night,
  waitingForCheck,
  checked,
  pastUncompleted,
  multiPlanSelection,
}
