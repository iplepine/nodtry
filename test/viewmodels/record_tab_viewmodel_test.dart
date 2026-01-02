import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nod_try/features/history/presentation/history_viewmodel.dart';
import 'package:nod_try/features/history/presentation/history_state.dart';
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
    container.listen(historyViewModelProvider, (_, __) {});
    final result = await container.read(historyViewModelProvider.future);

    // Assert
    expect(result.items.length, 2);
    expect(mockRecordRepository.getHistoryItemsCallCount, 1);
  });

  test('setFilter(me) should filter only my items', () async {
    // Arrange
    await container.read(historyViewModelProvider.future); // Initial load

    // Act
    await container
        .read(historyViewModelProvider.notifier)
        .dispatch(const HistoryIntent.setFilter(HistoryFilterType.me));
    final result = await container.read(historyViewModelProvider.future);

    // Assert
    expect(result.items.length, 1);
    expect(result.items.first.executorId, 'me');
    // Implementation calls `_fetchState` again
    expect(mockRecordRepository.getHistoryItemsCallCount, 2);
  });

  test('setFilter(partner) should filter only partner items', () async {
    // Arrange
    await container.read(historyViewModelProvider.future);

    // Act
    await container
        .read(historyViewModelProvider.notifier)
        .dispatch(const HistoryIntent.setFilter(HistoryFilterType.partner));
    final result = await container.read(historyViewModelProvider.future);

    // Assert
    expect(result.items.length, 1);
    expect(result.items.first.executorId, 'partner');
  });

  test('reconcile should call repository and refresh', () async {
    // Arrange
    container.listen(
      historyViewModelProvider,
      (_, __) {},
    ); // Keep alive and listen
    await container.read(historyViewModelProvider.future);
    mockRecordRepository.getHistoryItemsCallCount = 0; // Reset

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

    // Should trigger refresh (invalidateSelf)
    expect(mockRecordRepository.getHistoryItemsCallCount, greaterThan(0));
  });
}
