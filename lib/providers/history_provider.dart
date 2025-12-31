import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_item.dart';
import 'repository_provider.dart';

enum HistoryFilter { all, me, partner }

class HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => HistoryFilter.all;

  void setFilter(HistoryFilter filter) {
    state = filter;
  }
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterNotifier, HistoryFilter>(
      HistoryFilterNotifier.new,
    );

/// 히스토리 목록 프로바이더 (자동 갱신 지원)
final historyItemsProvider = FutureProvider<List<HistoryItem>>((ref) async {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.getHistoryItems();
});
