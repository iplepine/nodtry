import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';
import 'record_repository.dart';

/// Mock 데이터 저장소 구현체
class MockRecordRepository implements RecordRepository {
  List<HomeCardModel> _mockHomeCardModels = [];
  List<HistoryItem> _mockHistoryItems = [];

  List<Plan> _mockPlans = [];

  MockRecordRepository() {
    _mockHomeCardModels = _buildInitialMockModels();
    _mockHistoryItems = _buildInitialMockHistory();
    _mockPlans = _buildInitialMockPlans();
  }

  List<HomeCardModel> _buildInitialMockModels() {
    return [
      HomeCardModel(
        state: HomeCardState.overdueSelfAction,
        plan: _createMockPlan(hour: 8, minute: 0, title: '아침 영양제 챙겨먹기'),
      ),
      HomeCardModel(
        state: HomeCardState.nowAction,
        plan: _createMockPlan(hour: 13, minute: 0, title: '점심 후 10분 명상'),
      ),
      HomeCardModel(
        state: HomeCardState.partnerPlanShare,
        plan: _createMockPlan(hour: 10, minute: 0, title: '책 30분 읽기'),
      ),
      HomeCardModel(
        state: HomeCardState.partnerActionShare,
        plan: _createMockPlan(
          hour: 20,
          minute: 0,
          title: '책 30분 읽기',
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
          hour: 22,
          minute: 0,
          title: '밤 산책하기',
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
        plan: _createMockPlan(hour: 21, minute: 0, title: '하루 회고록 쓰기'),
        headerMessage: '함께하는 중',
      ),
      const HomeCardModel(state: HomeCardState.planNeeded),
    ];
  }

  List<HistoryItem> _buildInitialMockHistory() {
    return [
      HistoryItem(
        id: '1',
        planId: 'mock_plan_book',
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
        planId: 'mock_plan_squat',
        date: DateTime.now().subtract(const Duration(days: 2)), // 2일 전
        title: '매일 스쿼트 50회',
        status: HistoryStatus.actuallyDone,
        executorId: 'me',
        isVerifiedByPartner: true,
        comment: '뒤늦게라도 완료!',
      ),
      HistoryItem(
        id: '3',
        planId: 'mock_plan_book',
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
        planId: 'mock_plan_vitamin',
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

  List<Plan> _buildInitialMockPlans() {
    return [
      _createMockPlan(
        id: 'mock_plan_book',
        hour: 21,
        minute: 0,
        title: '책 30분 읽기',
        description: '매일 밤 하루를 정리해요',
        days: [1, 2, 3, 4, 5],
      ),
      _createMockPlan(
        id: 'mock_plan_squat',
        hour: 13,
        minute: 0,
        title: '매일 스쿼트 50회',
        description: '오후 집중력을 위해',
        days: [1, 3, 5],
        state: PlanState.completed,
      ),
      _createMockPlan(
        id: 'mock_plan_vitamin',
        hour: 8,
        minute: 0,
        title: '영양제 챙겨먹기',
        description: '건강이 최고',
        days: [1, 2, 3, 4, 5, 6, 7],
      ),
    ].map((p) {
      if (p.id == 'mock_plan_book') {
        return p.copyWith(userId: 'partner');
      }
      return p.copyWith(userId: 'me');
    }).toList();
  }

  @override
  Future<List<Plan>> getPlansByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock Logic: userId가 'me'이면 내 것, 아니면 파트너 것 반환
    // 실제 앱에서는 userId로 정확히 필터링
    if (userId == 'me') {
      return _mockPlans.where((p) => p.userId == 'me').toList();
    } else {
      return _mockPlans.where((p) => p.userId != 'me').toList();
    }
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
    _mockPlans.add(plan); // 리스트에 추가
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
        final plan = _createMockPlan(hour: 8, minute: 0, title: '아침 조깅');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.nowAction, plan: plan),
        ];
        break;
      case MockScenario.nowActionAfternoon:
        final plan = _createMockPlan(hour: 14, minute: 0, title: '오후 독서');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.nowAction, plan: plan),
        ];
        break;
      case MockScenario.nowActionNight:
        final plan = _createMockPlan(hour: 23, minute: 0, title: '밤 명상');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.nowAction, plan: plan),
        ];
        break;
      case MockScenario.partnerPlanShare:
        _mockHomeCardModels = [
          HomeCardModel(
            state: HomeCardState.partnerPlanShare,
            plan: _createMockPlan(hour: 10, minute: 0, title: '책 30분 읽기'),
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
            plan: _createMockPlan(hour: 21, minute: 0, title: '하루 회고록 쓰기'),
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
            plan: _createMockPlan(
              hour: DateTime.now().hour - 1,
              minute: 0,
              title: '이미 지남',
            ),
          ),
        ];
        break;
      case MockScenario.multiPlanSelection:
        _mockHomeCardModels = [
          HomeCardModel(
            state: HomeCardState.overdueSelfAction,
            plan: _createMockPlan(
              hour: DateTime.now().hour - 1,
              minute: 0,
              title: '1시간 전 약속',
            ),
          ),
          HomeCardModel(
            state: HomeCardState.nowAction,
            plan: _createMockPlan(
              hour: DateTime.now().hour + 1,
              minute: 0,
              title: '1시간 뒤 약속 (Primary)',
            ),
          ),
          HomeCardModel(
            state: HomeCardState.nowAction,
            plan: _createMockPlan(
              hour: DateTime.now().hour + 3,
              minute: 0,
              title: '3시간 뒤 약속 (Secondary 대기)',
            ),
          ),
        ];
        break;
      case MockScenario.todayDone:
        _mockHomeCardModels = [
          const HomeCardModel(state: HomeCardState.todayDone),
        ];
        break;
      case MockScenario.partnerActionShareWithNowAction:
        final plan = _createMockPlan(hour: 15, minute: 0, title: '오후 미팅 준비');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.nowAction, plan: plan),
          HomeCardModel(
            state: HomeCardState.partnerActionShare,
            plan: _createMockPlan(hour: 21, minute: 0, title: '하루 회고록 쓰기'),
            partnerName: '지민',
            partnerImageUrl:
                'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
            headerMessage: '오늘도 완료했어요!',
          ),
        ];
        break;
      case MockScenario.partnerPlanShareWithNowAction:
        final plan = _createMockPlan(hour: 18, minute: 0, title: '저녁 식사 준비');
        _mockHomeCardModels = [
          HomeCardModel(state: HomeCardState.nowAction, plan: plan),
          HomeCardModel(
            state: HomeCardState.partnerPlanShare,
            plan: _createMockPlan(hour: 22, minute: 0, title: '밤 산책하기'),
            partnerName: '지민',
            partnerImageUrl:
                'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
            headerMessage: '이런 약속을 제안했어요',
          ),
        ];
        break;
      case MockScenario.richContent:
        // Demo scenario with many cards
        _mockHomeCardModels = [
          // 1. Primary Now Action (Morning)
          HomeCardModel(
            state: HomeCardState.nowAction,
            plan: _createMockPlan(
              hour: 8,
              minute: 0,
              title: '아침 영양제 챙겨먹기',
              description: '공복에 유산균 포함',
            ),
          ),
          // 2. Partner Action Share (Done)
          HomeCardModel(
            state: HomeCardState.partnerActionShare,
            plan: _createMockPlan(hour: 7, minute: 30, title: '아침 조깅'),
            partnerName: '지민',
            partnerImageUrl:
                'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
            headerMessage: '오늘도 완료했어요!',
          ),
          // 3. Now Action (Lunch)
          HomeCardModel(
            state: HomeCardState.nowAction,
            plan: _createMockPlan(hour: 12, minute: 30, title: '점심 후 10분 명상'),
          ),
          // 4. Overdue Action
          HomeCardModel(
            state: HomeCardState.overdueSelfAction,
            plan: _createMockPlan(
              hour: DateTime.now().hour - 2,
              minute: 0,
              title: '물 500ml 마시기',
            ),
          ),
          // 5. Partner Plan Share
          HomeCardModel(
            state: HomeCardState.partnerPlanShare,
            plan: _createMockPlan(hour: 20, minute: 0, title: '주말 영화 예매하기'),
            partnerName: '지민',
            partnerImageUrl:
                'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
            headerMessage: '이런 약속을 제안했어요',
          ),
          // 6. Now Action (Night)
          HomeCardModel(
            state: HomeCardState.nowAction,
            plan: _createMockPlan(hour: 22, minute: 0, title: '자기 전 스트레칭'),
          ),
          // 7. Today Done List
          const HomeCardModel(state: HomeCardState.todayDone),
        ];
        break;
    }

    // Sync _mockPlans with _mockHomeCardModels for test consistency
    // 시나리오가 변경되면 Us 탭의 목록도 해당 계획들로 갱신됨
    if (scenario == MockScenario.planNeeded) {
      _mockPlans = [];
    } else {
      _mockPlans = [];
      for (var model in _mockHomeCardModels) {
        if (model.plan != null) {
          final uid =
              model.partnerName != null || model.state.name.contains('partner')
              ? 'partner'
              : 'me';

          // 이미 리스트에 있는지 확인 (ID 중복 가이드)
          if (!_mockPlans.any((p) => p.id == model.plan!.id)) {
            _mockPlans.add(model.plan!.copyWith(userId: uid));
          }
        }
      }
      // If relaxedDay (no active items but maybe plans exist?), we might want to keep some?
      // For now, simple sync: relaxedDay = empty plans (or we can add dummy plans if needed)
      if (scenario == MockScenario.relaxedDay && _mockPlans.isEmpty) {
        // Add a dummy plan that is not for today?
        // For simplicity, leave it empty.
      }
    }
  }

  Plan _createMockPlan({
    String? id,
    required int hour,
    required int minute,
    required String title,
    String? description,
    List<int>? days,
    PlanState state = PlanState.active,
  }) {
    return Plan(
      id: id ?? 'mock_plan_${hour}_$minute',
      userId: 'mock_user',
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(
        const Duration(days: 21),
      ), // Total 28 days (4 weeks)
      state: state,
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
        planId: item.planId,
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

  @override
  Future<void> reconcileHistoryItem(
    String historyId,
    HistoryStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockHistoryItems.indexWhere((item) => item.id == historyId);
    if (index != -1) {
      final item = _mockHistoryItems[index];
      _mockHistoryItems[index] = HistoryItem(
        id: item.id,
        planId: item.planId,
        date: item.date,
        title: item.title,
        status: status, // Update Status
        executorId: item.executorId,
        isVerifiedByMe: item.isVerifiedByMe,
        isVerifiedByPartner: item.isVerifiedByPartner,
        comment: status == HistoryStatus.actuallyDone
            ? '사실 완료했어요'
            : (status == HistoryStatus.rested ? '쉬어갔어요' : item.comment),
        partnerName: item.partnerName,
        partnerImageUrl: item.partnerImageUrl,
      );
    }
  }

  @override
  Future<void> reportSkip(String planId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockHomeCardModels.removeWhere((m) => m.plan?.id == planId);

    // If empty after removal, add todayDone or relaxedDay?
    // For now, let's leave it empty so ViewModel/UI handles it or Repository checks.
    // Actually getHomeCardStates returns _mockHomeCardModels.
    // If empty, 'PlanNeeded' or 'RelaxedDay' logic is usually inside getHomeCardStates logic in real repo.
    // In Mock, we should probably ensure it's not just empty list if we want to show 'Done'.

    if (_mockHomeCardModels.isEmpty) {
      _mockHomeCardModels.add(
        const HomeCardModel(state: HomeCardState.todayDone),
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
  partnerActionShareWithNowAction,
  partnerPlanShareWithNowAction,
  richContent,
}
