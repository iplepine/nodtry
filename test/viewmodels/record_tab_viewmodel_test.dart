import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nod_try/features/history/presentation/history_viewmodel.dart';
import 'package:nod_try/features/history/presentation/history_state.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';

// Manual Mock
class MockRecordRepository extends Fake implements RecordRepository {
  List<HistoryItem> mockItems = [];
  List<Plan> mockPlans = [];
  int getHistoryItemsCallCount = 0;
  int getPlansCallCount = 0;

  String? lastReconciledId;
  HistoryStatus? lastReconciledStatus;
  int reconcileCallCount = 0;

  @override
  Future<List<HistoryItem>> getHistoryItems() async {
    getHistoryItemsCallCount++;
    return mockItems;
  }

  @override
  Future<List<Plan>> getPlansByUserId(String userId) async {
    getPlansCallCount++;
    return mockPlans;
  }

  @override
  Future<void> reconcileHistoryItem(
    String historyId,
    HistoryStatus status,
  ) async {
    reconcileCallCount++;
    lastReconciledId = historyId;
    lastReconciledStatus = status;
  }
}

void main() {
  late MockRecordRepository mockRecordRepository;
  late ProviderContainer container;

  final itemMe = HistoryItem(
    id: '1',
    planId: 'plan_1',
    date: DateTime.now(),
    title: 'My Action',
    status: HistoryStatus.done,
    executorId: 'me',
  );

  final itemPartner = HistoryItem(
    id: '2',
    planId: 'plan_2',
    date: DateTime.now(),
    title: 'Partner Action',
    status: HistoryStatus.done,
    executorId: 'partner',
  );

  final activePlan = Plan(
    id: 'plan_1',
    userId: 'me',
    startDate: DateTime.now().subtract(const Duration(days: 7)),
    endDate: DateTime.now().add(const Duration(days: 7)),
    state: PlanState.active,
    items: [],
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockRecordRepository = MockRecordRepository();
    mockRecordRepository.mockItems = [itemMe, itemPartner];
    mockRecordRepository.mockPlans = [activePlan];

    container = ProviderContainer(
      overrides: [
        recordRepositoryProvider.overrideWithValue(mockRecordRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Initial state should load active items', () async {
    // Act
    container.listen(historyViewModelProvider, (_, __) {});
    final result = await container.read(historyViewModelProvider.future);

    // Assert
    // activePlanId에 해당하는 itemMe만 포함되어야 함 (VM logic)
    expect(result.activeItems.length, 1);
    expect(result.activeItems.first.id, '1');
    expect(mockRecordRepository.getHistoryItemsCallCount, 1);
    expect(mockRecordRepository.getPlansCallCount, 1);
  });

  test('reconcile should call repository and refresh', () async {
    // Arrange
    container.listen(historyViewModelProvider, (_, __) {});
    await container.read(historyViewModelProvider.future);
    mockRecordRepository.getHistoryItemsCallCount = 0;

    // Act
    await container
        .read(historyViewModelProvider.notifier)
        .dispatch(
          const HistoryIntent.reconcile('1', HistoryStatus.actuallyDone),
        );

    // Wait for async rebuild
    await container.read(historyViewModelProvider.future);

    // Assert
    expect(mockRecordRepository.reconcileCallCount, 1);
    expect(mockRecordRepository.lastReconciledId, '1');
    expect(
      mockRecordRepository.lastReconciledStatus,
      HistoryStatus.actuallyDone,
    );

    expect(mockRecordRepository.getHistoryItemsCallCount, greaterThan(0));
  });
}
