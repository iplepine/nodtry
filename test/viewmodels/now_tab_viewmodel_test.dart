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

class MockRecordRepository extends Fake implements RecordRepository {
  int reportCompletionCallCount = 0;
  String? lastReportedPlanId;
  int reportSkipCallCount = 0;
  String? lastSkippedPlanId;
  int cheerPartnerCallCount = 0;
  String? lastCheeredPlanId;
  int passPlanCallCount = 0;
  String? lastPassedPlanId;

  @override
  Future<void> reportCompletion(String planId) async {
    reportCompletionCallCount++;
    lastReportedPlanId = planId;
  }

  @override
  Future<void> reportSkip(String planId) async {
    reportSkipCallCount++;
    lastSkippedPlanId = planId;
  }

  @override
  Future<void> cheerPartner(String planId, String reactionType) async {
    cheerPartnerCallCount++;
    lastCheeredPlanId = planId;
  }

  @override
  Future<void> passPlan(String planId) async {
    passPlanCallCount++;
    lastPassedPlanId = planId;
  }

  @override
  Future<List<HomeCardModel>> getHomeCardStates() => Future.value([]);
  @override
  Future<List<HistoryItem>> getHistoryItems() => Future.value([]);
  @override
  Future<List<Plan>> getPlansByUserId(String userId) => Future.value([]);
  @override
  Future<void> createPlan(Plan plan) => Future.value();
  @override
  Future<void> deletePlansByUserId(String uid) => Future.value();
  @override
  Future<void> reconcilePlan(String planId, HistoryStatus status) =>
      Future.value();
  @override
  Future<void> verifyHistoryItem(String historyId) => Future.value();
  @override
  Future<void> reconcileHistoryItem(String historyId, HistoryStatus status) =>
      Future.value();
}

class MockGetNowCardsUseCase extends Fake implements GetNowCardsUseCase {
  int executeCallCount = 0;
  List<HomeCardModel> returnValues = [];

  @override
  Future<List<HomeCardModel>> execute() async {
    executeCallCount++;
    return returnValues;
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
    mockGetNowCardsUseCase.returnValues = [state.primaryCard!];
    final expectedCards = mockGetNowCardsUseCase.returnValues;

    // Act
    final sub = container.listen(nowTabViewModelProvider, (_, __) {});
    await container.read(nowTabViewModelProvider.future);

    // Assert
    expect(sub.read().value?.allCards, expectedCards);
    expect(mockGetNowCardsUseCase.executeCallCount, 1);
  });

  test('CompletePlanIntent should call repository and refresh', () async {
    // Arrange
    mockGetNowCardsUseCase.returnValues = [];
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0;
    mockRecordRepository.reportCompletionCallCount = 0;

    // Act
    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CompletePlanIntent('plan-123'));

    // Assert
    expect(mockRecordRepository.reportCompletionCallCount, 1);
    expect(mockRecordRepository.lastReportedPlanId, 'plan-123');
    expect(mockGetNowCardsUseCase.executeCallCount, greaterThan(0));
  });

  test('CheckPartnerActionIntent should call repository and refresh', () async {
    // Arrange
    mockGetNowCardsUseCase.returnValues = [];
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0;
    mockRecordRepository.reportCompletionCallCount = 0;

    // Act
    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CheckPartnerActionIntent('plan-456'));

    // Assert
    expect(mockRecordRepository.reportCompletionCallCount, 1);
    expect(mockRecordRepository.lastReportedPlanId, 'plan-456');
    expect(mockGetNowCardsUseCase.executeCallCount, greaterThan(0));
  });

  test('CheerPartnerActionIntent should call repository and refresh', () async {
    // Arrange
    mockGetNowCardsUseCase.returnValues = [];
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0;
    mockRecordRepository.cheerPartnerCallCount = 0;

    // Act
    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CheerPartnerActionIntent('plan-cheer', 'fire'));

    // Assert
    expect(mockRecordRepository.cheerPartnerCallCount, 1);
    expect(mockRecordRepository.lastCheeredPlanId, 'plan-cheer');
    expect(mockGetNowCardsUseCase.executeCallCount, greaterThan(0));
  });

  test('PassPlanIntent should call repository and refresh', () async {
    // Arrange
    mockGetNowCardsUseCase.returnValues = [];
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0;
    mockRecordRepository.passPlanCallCount = 0;

    // Act
    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const PassPlanIntent('plan-pass'));

    // Assert
    expect(mockRecordRepository.passPlanCallCount, 1);
    expect(mockRecordRepository.lastPassedPlanId, 'plan-pass');
    expect(mockGetNowCardsUseCase.executeCallCount, greaterThan(0));
  });

  test('RefreshIntent should trigger refresh', () async {
    mockGetNowCardsUseCase.returnValues = [];
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0; // Reset

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const RefreshIntent());

    expect(mockGetNowCardsUseCase.executeCallCount, 1);
  });

  test('SkipPlanIntent should call repository and refresh', () async {
    mockGetNowCardsUseCase.returnValues = [];
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0;
    mockRecordRepository.reportSkipCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const SkipPlanIntent('plan-skip-123'));

    expect(mockRecordRepository.reportSkipCallCount, 1);
    expect(mockRecordRepository.lastSkippedPlanId, 'plan-skip-123');
    expect(mockGetNowCardsUseCase.executeCallCount, greaterThan(0));
  });
}
