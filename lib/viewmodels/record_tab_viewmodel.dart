import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_item.dart';
import '../providers/repository_provider.dart';

enum HistoryFilterType { all, me, partner }

class RecordTabViewModel extends AsyncNotifier<List<HistoryItem>> {
  HistoryFilterType _currentFilter = HistoryFilterType.all;

  @override
  FutureOr<List<HistoryItem>> build() async {
    return _fetchHistory();
  }

  Future<List<HistoryItem>> _fetchHistory() async {
    final repository = ref.read(recordRepositoryProvider);
    final allItems = await repository.getHistoryItems();

    // Filter Logic
    // Assuming 'me' is current user ID. in real app, fetch from auth provider.
    // In Mock, we can check executorId.

    // For MVP/Mock, we assume 'me' is the current user.
    // Ideally we should get current user ID from proper provider.
    final myUid =
        'me'; // TODO: Replace with ref.read(myProfileProvider).value?.uid ?? 'me'

    List<HistoryItem> filtered;
    switch (_currentFilter) {
      case HistoryFilterType.all:
        filtered = allItems;
        break;
      case HistoryFilterType.me:
        filtered = allItems.where((item) => item.executorId == myUid).toList();
        break;
      case HistoryFilterType.partner:
        filtered = allItems.where((item) => item.executorId != myUid).toList();
        break;
    }

    // Sort by date desc
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  Future<void> setFilter(HistoryFilterType filter) async {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHistory());
  }

  Future<void> reconcile(String historyId, HistoryStatus status) async {
    final repository = ref.read(recordRepositoryProvider);
    await repository.reconcileHistoryItem(historyId, status);

    // Refresh list
    ref.invalidateSelf();
  }

  FilterType get currentFilter => _currentFilter;
}

// Alias for convenience
typedef FilterType = HistoryFilterType;

final recordTabViewModelProvider =
    AsyncNotifierProvider<RecordTabViewModel, List<HistoryItem>>(
      () => RecordTabViewModel(),
    );
