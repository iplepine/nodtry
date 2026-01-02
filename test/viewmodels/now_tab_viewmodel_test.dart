import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nod_try/features/now/presentation/now_tab_viewmodel.dart';
import 'package:nod_try/features/now/presentation/now_tab_intent.dart';
import 'package:nod_try/models/home_state.dart';

import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/features/now/domain/usecases/get_now_cards_use_case.dart';

// Manual Mocks
class MockRecordRepository extends Fake implements RecordRepository {
  int reportCompletionCallCount = 0;
  String? lastReportedPlanId;
  int reportSkipCallCount = 0;
  String? lastSkippedPlanId;

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
    final expectedCards = [
      const HomeCardModel(state: HomeCardState.relaxedDay),
    ];
    mockGetNowCardsUseCase.returnValues = expectedCards;

    // Act
    final sub = container.listen(nowTabViewModelProvider, (_, __) {});
    await container.read(nowTabViewModelProvider.future);

    // Assert
    // Assert
    expect(sub.read().value?.allCards, expectedCards);
    expect(mockGetNowCardsUseCase.executeCallCount, 1);
  });

  test('CompletePlanIntent should call repository and refresh', () async {
    // Arrange
    mockGetNowCardsUseCase.returnValues = [];

    // Initial fetch
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0; // Reset count
    mockRecordRepository.reportCompletionCallCount = 0;

    // Act
    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CompletePlanIntent('plan-123'));

    // Assert
    expect(mockRecordRepository.reportCompletionCallCount, 1);
    expect(mockRecordRepository.lastReportedPlanId, 'plan-123');
    // Should trigger refresh (execute call count should increase)
    expect(mockGetNowCardsUseCase.executeCallCount, greaterThan(0));
  });

  test('CheckPartnerActionIntent should call repository and refresh', () async {
    // Arrange
    mockGetNowCardsUseCase.returnValues = [];

    // Initial fetch
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0; // Reset count
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

  test('RefreshIntent should trigger refresh', () async {
    // Arrange
    mockGetNowCardsUseCase.returnValues = [];

    // Initial load
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0;

    // Act
    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const RefreshIntent());

    // Assert
    expect(mockGetNowCardsUseCase.executeCallCount, 1);
  });
  test('SkipPlanIntent should call repository and refresh', () async {
    // Arrange
    mockGetNowCardsUseCase.returnValues = [];

    // Initial load
    await container.read(nowTabViewModelProvider.future);
    mockGetNowCardsUseCase.executeCallCount = 0;
    mockRecordRepository.reportSkipCallCount = 0;

    // Act
    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const SkipPlanIntent('plan-skip-123'));

    // Assert
    expect(mockRecordRepository.reportSkipCallCount, 1);
    expect(mockRecordRepository.lastSkippedPlanId, 'plan-skip-123');
    expect(mockGetNowCardsUseCase.executeCallCount, greaterThan(0));
  });
}
