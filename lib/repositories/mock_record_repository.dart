import 'dart:async';
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
        state: HomeCardState.overdue,
        plan: _createMockPlan(hour: 8, minute: 0, title: '아침 영양제 챙겨먹기'),
      ),
      HomeCardModel(
        state: HomeCardState.nowAction,
        plan: _createMockPlan(hour: 13, minute: 0, title: '점심 후 10분 명상'),
      ),
      HomeCardModel(
        state: HomeCardState.partnerPlanCreate,
        plan: _createMockPlan(hour: 10, minute: 0, title: '책 30분 읽기'),
      ),
      HomeCardModel(
        state: HomeCardState.partnerAction,
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
        state: HomeCardState.partnerPlanCreate,
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
        state: HomeCardState.partnerAction,
        plan: _createMockPlan(hour: 21, minute: 0, title: '하루 회고록 쓰기'),
        headerMessage: '함께하는 중',
      ),
      const HomeCardModel(state: HomeCardState.emptyPlan),
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
        note: '어제도 고마워요. 덕분에 책 읽는 시간이 생겼어요.',
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
        note: '뒤늦게라도 완료!',
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
        note: '오늘은 컨디션 난조로 쉬어갔어요.',
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

  final _streamController = StreamController<List<HomeCardModel>>.broadcast();
  final _historyStreamController =
      StreamController<List<HistoryItem>>.broadcast();

  @override
  Stream<List<HomeCardModel>> getHomeCardStatesStream() {
    // 초기값 전달
    Future.microtask(() => _streamController.add(_mockHomeCardModels));
    return _streamController.stream;
  }

  @override
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds}) {
    // Return a stream that updates whenever _mockHistoryItems changes,
    // filtered by userIds if provided.
    return _historyStreamController.stream.map((allItems) {
      if (userIds == null || userIds.isEmpty) return allItems;
      return allItems
          .where((item) => userIds.contains(item.executorId))
          .toList();
    });
  }

  void _notifyStream() {
    _streamController.add(_mockHomeCardModels);
  }

  void _notifyHistoryStream() {
    _historyStreamController.add(_mockHistoryItems);
  }

  final _plansStreamController = StreamController<List<Plan>>.broadcast();

  void _notifyPlansStream() {
    _plansStreamController.add(_mockPlans);
  }

  @override
  Stream<List<Plan>> getPlansByUserIdStream(String userId) {
    // Initial emission
    Future.microtask(() {
      final filtered = userId == 'me'
          ? _mockPlans.where((p) => p.userId == 'me').toList()
          : _mockPlans.where((p) => p.userId != 'me').toList();
      _plansStreamController.add(filtered);
    });

    return _plansStreamController.stream.map((plans) {
      if (userId == 'me') {
        return plans.where((p) => p.userId == 'me').toList();
      } else {
        return plans.where((p) => p.userId != 'me').toList();
      }
    });
  }

  @override
  Future<void> createPlan(Plan plan) async {
    // Mock: 1초 딜레이 후 성공
    await Future.delayed(const Duration(seconds: 1));
    // Generate ID if missing
    final newPlan = plan.copyWith(
      id: plan.id ?? 'mock-${DateTime.now().millisecondsSinceEpoch}',
    );
    _mockPlans.add(newPlan); // 리스트에 추가

    // 상태를 Active로 변경 시뮬레이션 (단순화: 덮어쓰기)
    _mockHomeCardModels = [
      HomeCardModel(state: HomeCardState.nowAction, plan: newPlan),
    ];
    _notifyStream();
    _notifyPlansStream();
  }

  @override
  Future<void> updatePlan(Plan plan) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockHomeCardModels.indexWhere((m) => m.plan?.id == plan.id);
    if (index != -1) {
      // Re-process to model (simplified for mock: Assume active)
      _mockHomeCardModels[index] = HomeCardModel(
        state: HomeCardState.nowAction,
        plan: plan,
      );
      _notifyStream();
    }

    // Update plan in _mockPlans list
    final planIndex = _mockPlans.indexWhere((p) => p.id == plan.id);
    if (planIndex != -1) {
      _mockPlans[planIndex] = plan;
      _notifyPlansStream();
    }
  }

  @override
  Future<void> deletePlan(String planId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockHomeCardModels.removeWhere((m) => m.plan?.id == planId);
    if (_mockHomeCardModels.isEmpty) {
      _mockHomeCardModels.add(
        const HomeCardModel(state: HomeCardState.todayComplete),
      );
    }
    _notifyStream();

    _mockPlans.removeWhere((p) => p.id == planId);
    _notifyPlansStream();
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
      verifiedDates: const [],
    );
  }

  @override
  Future<void> deletePlansByUserId(String uid) async {
    // Mock: 딜레이만
    await Future.delayed(const Duration(milliseconds: 500));
    // For completeness, updates could be simulated here too
    _mockHomeCardModels = [const HomeCardModel(state: HomeCardState.emptyPlan)];
    _notifyStream();

    // Remove all plans for user (simulated)
    if (uid == 'me') {
      _mockPlans.removeWhere((p) => p.userId == 'me');
    } else {
      _mockPlans.removeWhere((p) => p.userId != 'me');
    }
    _notifyPlansStream();
  }

  @override
  Future<void> reconcilePlan(String planId, HistoryStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // 선택된 항목을 목록에서 제거하거나 상태를 변경함
    _mockHomeCardModels.removeWhere((m) => m.plan?.id == planId);
    _notifyStream();
  }

  @override
  Future<void> verifyHistoryItem(String historyId, {String? message}) async {
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
        note: item.note,
        comment: message ?? item.comment,
        partnerName: item.partnerName,
        partnerImageUrl: item.partnerImageUrl,
      );
    }
  }

  @override
  Future<void> reportCompletion(String planId, {String? note}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Find model
    final index = _mockHomeCardModels.indexWhere((m) => m.plan?.id == planId);

    if (index != -1) {
      final model = _mockHomeCardModels[index];
      // If it's my plan (active), remove it to show next card
      if (model.state == HomeCardState.nowAction ||
          model.state == HomeCardState.overdue) {
        _mockHomeCardModels.removeAt(index);
        // If empty, add todayComplete
        if (_mockHomeCardModels.isEmpty) {
          _mockHomeCardModels.add(
            const HomeCardModel(state: HomeCardState.todayComplete),
          );
        }
      } else {
        // Partner plan logic (existing)
        _mockHomeCardModels[index] = HomeCardModel(
          state: HomeCardState.partnerAction,
          plan: model.plan,
          partnerName: model.partnerName,
          partnerImageUrl: model.partnerImageUrl,
          headerMessage: '함께하는 중',
        );
      }
      _notifyStream();

      // 히스토리에 추가
      _mockHistoryItems.insert(
        0,
        HistoryItem(
          id: 'mock_h_${DateTime.now().millisecondsSinceEpoch}',
          planId: planId,
          date: DateTime.now(),
          title: model.plan?.items.firstOrNull?.title ?? '계획 완료',
          status:
              (model.state == HomeCardState.nowAction ||
                  model.state == HomeCardState.overdue)
              ? HistoryStatus.done
              : HistoryStatus.actuallyDone,
          executorId:
              (model.state == HomeCardState.nowAction ||
                  model.state == HomeCardState.overdue)
              ? 'me'
              : 'partner',
          note: note,
        ),
      );
      _notifyHistoryStream();
    }
  }

  @override
  Future<void> reconcileHistoryItem(
    String historyId,
    HistoryStatus status,
  ) async {
    // ... existing impl ...
    await Future.delayed(const Duration(milliseconds: 500));
    // ... logic omitted for brevity as it doesn't affect HomeCardState directly usually ...
    // But copying existing logic just in case
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
        note: status == HistoryStatus.actuallyDone
            ? '사실 완료했어요'
            : (status == HistoryStatus.rested ? '쉬어갔어요' : item.note),
        partnerName: item.partnerName,
        partnerImageUrl: item.partnerImageUrl,
      );
      _notifyHistoryStream();
    }
  }

  @override
  Future<void> reportSkip(String planId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockHomeCardModels.removeWhere((m) => m.plan?.id == planId);

    if (_mockHomeCardModels.isEmpty) {
      _mockHomeCardModels.add(
        const HomeCardModel(state: HomeCardState.todayComplete),
      );
    }
    _notifyStream();

    // 히스토리에 추가 (Skip)
    _mockHistoryItems.insert(
      0,
      HistoryItem(
        id: 'mock_h_skip_${DateTime.now().millisecondsSinceEpoch}',
        planId: planId,
        date: DateTime.now(),
        title: '계획 건너뜀',
        status: HistoryStatus.skipped,
        executorId: 'me',
      ),
    );
    _notifyHistoryStream();
  }

  @override
  Future<void> cheerPartner(
    String planId,
    String reactionType, {
    String? message,
  }) async {
    // ignore: avoid_print
    print(
      'Mock: Partner cheered for plan $planId with reaction $reactionType, message: $message',
    );
    await Future.delayed(const Duration(milliseconds: 500));

    // Plan 업데이트 시뮬레이션
    final index = _mockPlans.indexWhere((p) => p.id == planId);
    if (index != -1) {
      _mockPlans[index] = _mockPlans[index].copyWith(
        lastComment: message,
        lastCheerType: reactionType,
        lastCheerAt: DateTime.now(),
      );
      _notifyPlansStream();
    }
  }

  @override
  Future<void> passPlan(String planId) async {
    // ignore: avoid_print
    print('Mock: Plan passed for $planId');
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock passing logic
    _notifyStream();
  }

  @override
  Future<void> assignManagerToActivePlans(String managerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (var plan in _mockPlans) {
      if (plan.userId == 'me' &&
          (plan.managerId == null || plan.managerId!.isEmpty) &&
          (plan.state == PlanState.active ||
              plan.state == PlanState.pendingApproval)) {
        // Mock update: Create new instance with managerId
        final index = _mockPlans.indexOf(plan);
        _mockPlans[index] = plan.copyWith(
          managerId: managerId,
          state: PlanState.pendingApproval, // 변경
        );
      }
    }
  }

  @override
  Future<void> approvePlan(String planId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockPlans.indexWhere((p) => p.id == planId);
    if (index != -1) {
      _mockPlans[index] = _mockPlans[index].copyWith(state: PlanState.active);
      _notifyPlansStream();
      // Update Home Cards? For mock, simplified.
    }
  }

  @override
  Future<void> verifyPlan(String planId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Verify Logic for Mock
    final index = _mockHistoryItems.indexWhere(
      (h) => h.planId == planId && h.date.day == DateTime.now().day,
    );
    if (index != -1) {
      _mockHistoryItems[index] = _mockHistoryItems[index].copyWith(
        isVerifiedByMe: true,
      );
      _notifyHistoryStream();
    }
  }
}
