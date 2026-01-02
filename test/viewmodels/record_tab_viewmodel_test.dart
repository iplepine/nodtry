import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nod_try/viewmodels/record_tab_viewmodel.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';

// Manual Mock
class MockRecordRepository extends Fake implements RecordRepository {
  List<HistoryItem> mockItems = [];
  int getHistoryItemsCallCount = 0;

  String? lastReconciledId;
  HistoryStatus? lastReconciledStatus;
  int reconcileCallCount = 0;

  @override
  Future<List<HistoryItem>> getHistoryItems() async {
    getHistoryItemsCallCount++;
    return mockItems;
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
    date: DateTime.now(),
    title: 'My Action',
    status: HistoryStatus.done,
    executorId: 'me', // Assuming 'me' logic in VM
  );

  final itemPartner = HistoryItem(
    id: '2',
    date: DateTime.now(),
    title: 'Partner Action',
    status: HistoryStatus.done,
    executorId: 'partner',
  );

  setUp(() {
    mockRecordRepository = MockRecordRepository();
    // Default items
    mockRecordRepository.mockItems = [itemMe, itemPartner];

    container = ProviderContainer(
      overrides: [
        recordRepositoryProvider.overrideWithValue(mockRecordRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Initial state should load all items', () async {
    // Act
    container.listen(recordTabViewModelProvider, (_, __) {});
    final result = await container.read(recordTabViewModelProvider.future);

    // Assert
    expect(result.length, 2);
    expect(mockRecordRepository.getHistoryItemsCallCount, 1);
  });

  test('setFilter(me) should filter only my items', () async {
    // Arrange
    await container.read(recordTabViewModelProvider.future); // Initial load

    // Act
    await container
        .read(recordTabViewModelProvider.notifier)
        .setFilter(HistoryFilterType.me);
    final result = await container.read(recordTabViewModelProvider.future);

    // Assert
    expect(result.length, 1);
    expect(result.first.executorId, 'me');
    // It should trigger fetch again (ref.invalidateSelf case) or just filter from cached?
    // Implementation calls `_fetchHistory` again which calls repository getHistoryItems again.
    expect(mockRecordRepository.getHistoryItemsCallCount, 2);
  });

  test('setFilter(partner) should filter only partner items', () async {
    // Arrange
    await container.read(recordTabViewModelProvider.future);

    // Act
    await container
        .read(recordTabViewModelProvider.notifier)
        .setFilter(HistoryFilterType.partner);
    final result = await container.read(recordTabViewModelProvider.future);

    // Assert
    expect(result.length, 1);
    expect(result.first.executorId, 'partner');
  });

  test('reconcile should call repository and refresh', () async {
    // Arrange
    container.listen(
      recordTabViewModelProvider,
      (_, __) {},
    ); // Keep alive and listen
    await container.read(recordTabViewModelProvider.future);
    mockRecordRepository.getHistoryItemsCallCount = 0; // Reset

    // Act
    await container
        .read(recordTabViewModelProvider.notifier)
        .reconcile('1', HistoryStatus.actuallyDone);

    // Wait for async rebuild?
    // invalidateSelf is sync, but the new build future starts.
    // Let's read it to ensure it completes.
    await container.read(recordTabViewModelProvider.future);

    // Assert
    expect(mockRecordRepository.reconcileCallCount, 1);
    expect(mockRecordRepository.lastReconciledId, '1');
    expect(
      mockRecordRepository.lastReconciledStatus,
      HistoryStatus.actuallyDone,
    );

    // Should trigger refresh (invalidateSelf)
    expect(mockRecordRepository.getHistoryItemsCallCount, greaterThan(0));
  });
}
