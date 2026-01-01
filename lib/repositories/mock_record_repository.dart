import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';
import 'record_repository.dart';

/// Mock 데이터 저장소 구현체
class MockRecordRepository implements RecordRepository {
  List<HomeCardModel> _mockHomeCardModels = [];
  List<HistoryItem> _mockHistoryItems = [];

  MockRecordRepository() {
    _mockHomeCardModels = _buildInitialMockModels();
    _mockHistoryItems = _buildInitialMockHistory();
  }

  List<HomeCardModel> _buildInitialMockModels() {
    return [
      HomeCardModel(
        state: HomeCardState.overdueSelfAction,
        plan: _createMockPlan(8, 0, '아침 영양제 챙겨먹기'),
      ),
      HomeCardModel(
        state: HomeCardState.nowAction,
        plan: _createMockPlan(13, 0, '점심 후 10분 명상'),
      ),
      HomeCardModel(
        state: HomeCardState.partnerPlanShare,
        plan: _createMockPlan(10, 0, '책 30분 읽기'),
      ),
      HomeCardModel(
        state: HomeCardState.partnerActionShare,
        plan: _createMockPlan(
          20,
          0,
          '책 30분 읽기',
          description: '자기 전 마음의 양식 쌓기',
          days: [1, 2, 3, 4, 5],
        ),
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        headerMessage: '오늘도 완료했어요!',
      ),
      HomeCardModel(
        state: HomeCardState.partnerPlanShare,
        plan: _createMockPlan(
          22,
          0,
          '밤 산책하기',
          description: '하루를 마무리하며 가볍게 동네 한 바퀴',
          days: [1, 3, 5],
        ),
        partnerName: '지민',
        partnerImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
        headerMessage: '이런 약속을 제안했어요',
      ),
      HomeCardModel(
        state: HomeCardState.partnerActionShare,
        plan: _createMockPlan(21, 0, '하루 회고록 쓰기'),
        headerMessage: '함께하는 중',
      ),
      const HomeCardModel(state: HomeCardState.planNeeded),
    ];
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
      HistoryItem(
        id: '5',
        date: DateTime.now().subtract(const Duration(hours: 5)), // 5시간 전
        title: '물 2L 마시기',
        status: HistoryStatus.skipped,
        executorId: 'me',
        comment: '시간이 초과되어 자동으로 넘겨졌어요.',
      ),
      HistoryItem(
        id: '6',
        date: DateTime.now().subtract(const Duration(hours: 12)), // 반나절 전
        title: '스트레칭 하기',
        status: HistoryStatus.skipped,
        executorId: 'me',
        // 코멘트 없음 (완전히 대응 안 한 상태 시뮬레이션)
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
      HomeCardModel(state: HomeCardState.nowAction, plan: plan),
    ];
  }

  // Mock 전용 메서드: 복잡한 상태 시나리오 설정
  void setScenario(MockScenario scenario) {
    switch (scenario) {
      case MockScenario.planNeeded:
        _mockHomeCardModels = [
          const HomeCardModel(state: HomeCardState.planNeeded),
        ];
        break;
      case MockScenario.relaxedDay:
        _mockHomeCardModels = [
          const HomeCardModel(state: HomeCardState.relaxedDay),
        ];
        break;
      case MockScenario.nowActionMorning:
        final plan = _createMockPlan(8, 0, '아침 조깅');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.nowAction, plan: plan),
        ];
        break;
      case MockScenario.nowActionAfternoon:
        final plan = _createMockPlan(14, 0, '오후 독서');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.nowAction, plan: plan),
        ];
        break;
      case MockScenario.nowActionNight:
        final plan = _createMockPlan(23, 0, '밤 명상');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.nowAction, plan: plan),
        ];
        break;
      case MockScenario.partnerPlanShare:
        _mockHomeCardModels = [
          HomeCardModel(
            state: HomeCardState.partnerPlanShare,
            plan: _createMockPlan(10, 0, '책 30분 읽기'),
            partnerName: '지민',
            partnerImageUrl:
                'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
          ),
        ];
        break;
      case MockScenario.partnerActionShare:
        _mockHomeCardModels = [
          HomeCardModel(
            state: HomeCardState.partnerActionShare,
            plan: _createMockPlan(21, 0, '하루 회고록 쓰기'),
            partnerName: '지민',
            partnerImageUrl:
                'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
            headerMessage: '오늘도 완료했어요!',
          ),
        ];
        break;
      case MockScenario.overdueSelfAction:
        _mockHomeCardModels = [
          HomeCardModel(
            state: HomeCardState.overdueSelfAction,
            plan: _createMockPlan(DateTime.now().hour - 1, 0, '이미 지남'),
          ),
        ];
        break;
      case MockScenario.multiPlanSelection:
        _mockHomeCardModels = [
          HomeCardModel(
            state: HomeCardState.overdueSelfAction,
            plan: _createMockPlan(DateTime.now().hour - 1, 0, '1시간 전 약속'),
          ),
          HomeCardModel(
            state: HomeCardState.nowAction,
            plan: _createMockPlan(
              DateTime.now().hour + 1,
              0,
              '1시간 뒤 약속 (Primary)',
            ),
          ),
          HomeCardModel(
            state: HomeCardState.nowAction,
            plan: _createMockPlan(
              DateTime.now().hour + 3,
              0,
              '3시간 뒤 약속 (Secondary 대기)',
            ),
          ),
        ];
        break;
      case MockScenario.todayDone:
        _mockHomeCardModels = [
          const HomeCardModel(state: HomeCardState.todayDone),
        ];
        break;
    }
  }

  Plan _createMockPlan(
    int hour,
    int minute,
    String title, {
    String? description,
    List<int>? days,
  }) {
    return Plan(
      id: 'mock_plan_${hour}_$minute',
      userId: 'mock_user',
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(
        const Duration(days: 21),
      ), // Total 28 days (4 weeks)
      state: PlanState.active,
      items: [
        PlanItem(
          title: title,
          days: days ?? [1, 2, 3, 4, 5, 6, 7],
          count: days?.length ?? 7,
          notificationTime: NotificationTime.custom(hour, minute),
          description: description,
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

  @override
  Future<void> reportCompletion(String planId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockHomeCardModels.indexWhere((m) => m.plan?.id == planId);
    if (index != -1) {
      final model = _mockHomeCardModels[index];
      _mockHomeCardModels[index] = HomeCardModel(
        state: HomeCardState.partnerActionShare, // Checked -> Type 4
        plan: model.plan,
        partnerName: model.partnerName,
        partnerImageUrl: model.partnerImageUrl,
        headerMessage: '함께하는 중', // Completion implies 'Together' or similar
      );
    }
  }
}

enum MockScenario {
  planNeeded,
  relaxedDay,
  todayDone,
  nowActionMorning,
  nowActionAfternoon,
  nowActionNight,
  partnerPlanShare,
  partnerActionShare,
  overdueSelfAction,
  multiPlanSelection,
}
