import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nod_try/features/history/presentation/history_viewmodel.dart';
import 'package:nod_try/features/history/presentation/history_state.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
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
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds}) {
    getHistoryItemsCallCount++;
    return Stream.value(mockItems);
  }

  @override
  Future<List<Plan>> getPlansByUserId(String userId) async {
    getPlansCallCount++;
    return mockPlans;
  }

  @override
  Stream<List<Plan>> getPlansByUserIdStream(String userId) {
    getPlansCallCount++;
    return Stream.value(mockPlans);
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

  @override
  Future<void> pokeUser(String userId, {String? message}) async {
    // Mock implementation for test
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

  final mockUser = UserModel(
    uid: 'me',
    email: 'me@example.com',
    displayName: 'Me',
    loginType: LoginType.email,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockRecordRepository = MockRecordRepository();
    mockRecordRepository.mockItems = [itemMe, itemPartner];
    mockRecordRepository.mockPlans = [activePlan];

    container = ProviderContainer(
      overrides: [
        recordRepositoryProvider.overrideWithValue(mockRecordRepository),
        myProfileProvider.overrideWith((ref) => Stream.value(mockUser)),
        connectedProfilesProvider.overrideWith((ref) => Future.value([])),
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
    // Default filter is 'all', so it should load both items
    expect(result.activeItems.length, 2);
    expect(mockRecordRepository.getHistoryItemsCallCount, greaterThan(0));
    expect(mockRecordRepository.getPlansCallCount, greaterThan(0));
  });

  test('reconcile should call repository and refresh', () async {
    // Arrange
    container.listen(historyViewModelProvider, (_, __) {});
    await container.read(historyViewModelProvider.future);
    mockRecordRepository.getHistoryItemsCallCount = 0;

    // Act
    await container
        .read(historyViewModelProvider.notifier)
        .dispatch(HistoryIntent.reconcile('1', HistoryStatus.actuallyDone));

    // Wait for async rebuild - invalidateSelf triggers build() in next microtask
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
