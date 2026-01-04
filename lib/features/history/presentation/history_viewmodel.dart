import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'history_state.dart';
import '../../../providers/repository_provider.dart';
import '../../../models/history_item.dart';
import '../../../models/plan_model.dart';
import '../../../models/plan_summary.dart';

class HistoryViewModel extends StreamNotifier<HistoryState> {
  @override
  Stream<HistoryState> build() {
    return _fetchStateStream();
  }

  Stream<HistoryState> _fetchStateStream() {
    final historyUseCase = ref.watch(getHistoryUseCaseProvider);
    final profile = ref.watch(myProfileProvider).value;
    final myUid = profile?.uid ?? 'me';
    final recordRepo = ref.watch(recordRepositoryProvider);

    // 1. Get History Stream
    final historyStream = historyUseCase.executeStream();

    // Combine streams
    // Note: This is a simple combination. For production, consider using RxDart's CombineLatest.
    // or separate providers that this one watches.
    // Here we use nested streams/mapping for simplicity without extra dependencies.
    return historyStream.asyncMap((allItems) async {
      // Since plans are also a stream, we fetch the current list of plans.
      // In a more reactive way, this should also rebuild when plans change.
      final myPlans = await recordRepo.getPlansByUserId(myUid);

      final activePlanIds = myPlans
          .where((p) => p.state == PlanState.active)
          .map((p) => p.id)
          .toSet();

      final activeItems = allItems.where((item) {
        if (item.planId != null) {
          return activePlanIds.contains(item.planId);
        }
        return true;
      }).toList();

      activeItems.sort((a, b) => b.date.compareTo(a.date));

      final finishedPlanSummaries = <PlanSummary>[];
      final completedPlans = myPlans.where(
        (p) => p.state == PlanState.completed,
      );

      for (var plan in completedPlans) {
        final myCount = allItems.where((item) {
          return item.planId == plan.id &&
              item.executorId == myUid &&
              (item.status == HistoryStatus.done ||
                  item.status == HistoryStatus.actuallyDone);
        }).length;

        finishedPlanSummaries.add(
          PlanSummary(
            planId: plan.id ?? '',
            title: plan.items.isNotEmpty ? plan.items.first.title : '제목 없음',
            startDate: plan.startDate,
            endDate: plan.endDate,
            myCount: myCount,
          ),
        );
      }

      return HistoryState(
        activeItems: activeItems,
        finishedPlanSummaries: finishedPlanSummaries,
        isLoading: false,
      );
    });
  }

  Future<void> dispatch(HistoryIntent intent) async {
    if (!state.hasValue) return;

    try {
      if (intent is RefreshIntent) {
        ref.invalidateSelf();
      } else if (intent is ReconcileIntent) {
        await _reconcile(intent.historyId, intent.status);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _reconcile(String historyId, HistoryStatus status) async {
    await ref
        .read(recordRepositoryProvider)
        .reconcileHistoryItem(historyId, status);
    // Stream handles updates automatically, but we can invalidate if we want immediate fresh build
    ref.invalidateSelf();
  }

  /// 디버그용: FakeState를 직접 주입
  void setFakeState(HistoryState fakeState) {
    state = AsyncValue.data(fakeState);
  }
}

final historyViewModelProvider =
    StreamNotifierProvider<HistoryViewModel, HistoryState>(
      () => HistoryViewModel(),
    );
