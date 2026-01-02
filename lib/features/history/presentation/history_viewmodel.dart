import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'history_state.dart';
import '../../../providers/repository_provider.dart';
import '../../../models/history_item.dart';

class HistoryViewModel extends AsyncNotifier<HistoryState> {
  @override
  FutureOr<HistoryState> build() async {
    return _fetchState();
  }

  Future<HistoryState> _fetchState() async {
    final useCase = ref.read(getHistoryUseCaseProvider);
    final allItems = await useCase.execute();

    // Default filter from current state if exists, otherwise .all
    final filter = state.value?.currentFilter ?? HistoryFilterType.all;

    // Profile for identifying 'me'
    final myProfile = ref.read(myProfileProvider).value;
    final myUid = myProfile?.uid ?? 'me';

    List<HistoryItem> filtered;
    switch (filter) {
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

    filtered.sort((a, b) => b.date.compareTo(a.date));

    return HistoryState(
      items: filtered,
      currentFilter: filter,
      isLoading: false,
    );
  }

  Future<void> dispatch(HistoryIntent intent) async {
    if (!state.hasValue) return;

    try {
      if (intent is RefreshIntent) {
        state = await AsyncValue.guard(() => _fetchState());
      } else if (intent is SetFilterIntent) {
        // Update filter in state immediately for UI responsiveness if needed,
        // but here we let _fetchState handle it.
        // We need to store the intended filter somewhere or pass it.
        // Let's refine _fetchState to take a filter or use a private variable.
        await _changeFilter(intent.filter);
      } else if (intent is ReconcileIntent) {
        await _reconcile(intent.historyId, intent.status);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _changeFilter(HistoryFilterType filter) async {
    state = AsyncValue.data(
      state.value!.copyWith(currentFilter: filter, isLoading: true),
    );
    state = await AsyncValue.guard(() => _fetchState());
  }

  Future<void> _reconcile(String historyId, HistoryStatus status) async {
    await ref
        .read(recordRepositoryProvider)
        .reconcileHistoryItem(historyId, status);
    ref.invalidateSelf();
    await future;
  }
}

final historyViewModelProvider =
    AsyncNotifierProvider<HistoryViewModel, HistoryState>(
      () => HistoryViewModel(),
    );
