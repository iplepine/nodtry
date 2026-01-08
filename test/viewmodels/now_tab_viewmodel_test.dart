import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nod_try/features/now/presentation/now_tab_viewmodel.dart';
import 'package:nod_try/features/now/presentation/now_tab_intent.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/features/now/presentation/now_tab_state.dart';

import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/features/now/domain/usecases/get_now_cards_use_case.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/history_item.dart';
import 'dart:async';

class MockRecordRepository extends Fake implements RecordRepository {
  int reportCompletionCallCount = 0;
  String? lastReportedPlanId;
  int reportSkipCallCount = 0;
  String? lastSkippedPlanId;
  int cheerPartnerCallCount = 0;
  String? lastCheeredPlanId;
  int passPlanCallCount = 0;
  String? lastPassedPlanId;

  // Stream Controller for testing real-time updates
  final _controller = StreamController<List<HomeCardModel>>.broadcast();
  List<HomeCardModel> _currentValue = [];

  void emit(List<HomeCardModel> data) {
    _currentValue = data;
    _controller.add(data);
  }

  @override
  Future<void> reportCompletion(String planId, {String? note}) async {
    reportCompletionCallCount++;
    lastReportedPlanId = planId;
    emit(_currentValue); // Emit current (or updated) value to trigger stream
  }

  @override
  Future<void> reportSkip(String planId) async {
    reportSkipCallCount++;
    lastSkippedPlanId = planId;
    emit(_currentValue);
  }

  @override
  Future<void> cheerPartner(
    String planId,
    String reactionType, {
    String? message,
  }) async {
    cheerPartnerCallCount++;
    lastCheeredPlanId = planId;
    emit(_currentValue);
  }

  @override
  Future<void> passPlan(String planId) async {
    passPlanCallCount++;
    lastPassedPlanId = planId;
    emit(_currentValue);
  }

  @override
  Future<List<HomeCardModel>> getHomeCardStates() => Future.value([]);

  @override
  Stream<List<HomeCardModel>> getHomeCardStatesStream() async* {
    yield _currentValue;
    yield* _controller.stream;
  }

  @override
  Future<List<HistoryItem>> getHistoryItems() => Future.value([]);
  @override
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds}) =>
      Stream.value([]);

  @override
  Future<List<Plan>> getPlansByUserId(String userId) => Future.value([]);
  @override
  Stream<List<Plan>> getPlansByUserIdStream(String userId) => Stream.value([]);

  @override
  Future<void> createPlan(Plan plan) => Future.value();
  @override
  Future<void> updatePlan(Plan plan) => Future.value();
  @override
  Future<void> deletePlan(String planId) => Future.value();
  @override
  Future<void> deletePlansByUserId(String uid) => Future.value();

  @override
  Future<void> reconcilePlan(String planId, HistoryStatus status) =>
      Future.value();
  @override
  Future<void> verifyHistoryItem(String historyId, {String? message}) =>
      Future.value();
  @override
  Future<void> reconcileHistoryItem(String historyId, HistoryStatus status) =>
      Future.value();

  @override
  Future<void> assignManagerToActivePlans(String managerId) => Future.value();
  @override
  Future<void> approvePlan(String planId) => Future.value();
  @override
  Future<void> verifyPlan(String planId) => Future.value();
}

class MockGetNowCardsUseCase extends Fake implements GetNowCardsUseCase {
  int executeCallCount = 0;
  final _controller = StreamController<List<HomeCardModel>>.broadcast();
  List<HomeCardModel> _currentValue = [];

  void emit(List<HomeCardModel> data) {
    _currentValue = data;
    _controller.add(data);
  }

  @override
  Future<List<HomeCardModel>> execute() async {
    return [];
  }

  @override
  Stream<List<HomeCardModel>> executeStream() async* {
    executeCallCount++;
    yield _currentValue;
    yield* _controller.stream;
  }
}

void main() {
  late MockRecordRepository mockRecordRepository;
  late MockGetNowCardsUseCase mockGetNowCardsUseCase;
  late ProviderContainer container;

  setUp(() {
    mockRecordRepository = MockRecordRepository();
    mockGetNowCardsUseCase = MockGetNowCardsUseCase();
    container = ProviderContainer(
      overrides: [
        recordRepositoryProvider.overrideWithValue(mockRecordRepository),
        getNowCardsUseCaseProvider.overrideWithValue(mockGetNowCardsUseCase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Initial state should be loading then data', () async {
    // Arrange
    final state = NowTabState(
      allCards: [],
      primaryCard: const HomeCardModel(state: HomeCardState.todayEmpty),
      secondaryCards: [],
      managerCards: const [],
    );
    final expectedCards = [state.primaryCard!];
    mockGetNowCardsUseCase.emit(expectedCards); // Pre-set value

    // Act
    // Reading future waits for the first valid state
    final result = await container.read(nowTabViewModelProvider.future);

    // Assert
    expect(result.allCards, expectedCards);
    expect(mockGetNowCardsUseCase.executeCallCount, 1);
  });

  test('CompletePlanIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await container.read(nowTabViewModelProvider.future);
    mockRecordRepository.reportCompletionCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CompletePlanIntent('plan-123'));

    expect(mockRecordRepository.reportCompletionCallCount, 1);
    expect(mockRecordRepository.lastReportedPlanId, 'plan-123');
  });

  test('CheckPartnerActionIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await container.read(nowTabViewModelProvider.future);
    mockRecordRepository.reportCompletionCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CheckPartnerActionIntent('plan-456'));

    expect(mockRecordRepository.reportCompletionCallCount, 1);
    expect(mockRecordRepository.lastReportedPlanId, 'plan-456');
  });

  test('CheerPartnerActionIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await container.read(nowTabViewModelProvider.future);
    mockRecordRepository.cheerPartnerCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CheerPartnerActionIntent('plan-cheer', 'fire'));

    expect(mockRecordRepository.cheerPartnerCallCount, 1);
    expect(mockRecordRepository.lastCheeredPlanId, 'plan-cheer');
  });

  test('PassPlanIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await container.read(nowTabViewModelProvider.future);
    mockRecordRepository.passPlanCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const PassPlanIntent('plan-pass'));

    expect(mockRecordRepository.passPlanCallCount, 1);
    expect(mockRecordRepository.lastPassedPlanId, 'plan-pass');
  });

  test('RefreshIntent should re-subscribe to stream', () async {
    mockGetNowCardsUseCase.emit([]);
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0; // Reset

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const RefreshIntent());

    // Invalidate re-triggers build, which calls executeStream
    // We wait for microtask cycle
    await Future.delayed(Duration.zero);

    expect(mockGetNowCardsUseCase.executeCallCount, 1);
  });

  test('SkipPlanIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await container.read(nowTabViewModelProvider.future);
    mockRecordRepository.reportSkipCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const SkipPlanIntent('plan-skip-123'));

    expect(mockRecordRepository.reportSkipCallCount, 1);
    expect(mockRecordRepository.lastSkippedPlanId, 'plan-skip-123');
  });
}
