import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'history_state.dart';
import '../../../providers/repository_provider.dart';
import '../../../models/history_item.dart';
import '../../../models/plan_model.dart';
import '../../../models/plan_summary.dart';

class HistoryViewModel extends AsyncNotifier<HistoryState> {
  @override
  FutureOr<HistoryState> build() async {
    return _fetchState();
  }

  Future<HistoryState> _fetchState() async {
    final useCase = ref.read(getHistoryUseCaseProvider);
    final allItems = await useCase.execute();

    // Profile for identifying 'me'
    final myProfile = ref.read(myProfileProvider).value;
    final myUid = myProfile?.uid ?? 'me';

    // Fetch all plans to distinguish active vs completed
    final recordRepo = ref.read(recordRepositoryProvider);
    final myPlans = await recordRepo.getPlansByUserId(myUid);

    // Assuming we also want to see partner's finished plans or shared plans
    // In this app, plans are usually shared (managerId/userId pair)
    // For now, let's treat all fetched plans as relevant
    final activePlanIds = myPlans
        .where((p) => p.state == PlanState.active)
        .map((p) => p.id)
        .toSet();

    final activeItems = allItems.where((item) {
      if (item.planId != null) {
        return activePlanIds.contains(item.planId);
      }
      // Fallback: If no planId, use date range of active plans if needed
      // but ideally all new items should have planId.
      return true; // Temporary
    }).toList();

    activeItems.sort((a, b) => b.date.compareTo(a.date));

    // Build summaries for completed plans
    final finishedPlanSummaries = <PlanSummary>[];
    final completedPlans = myPlans.where((p) => p.state == PlanState.completed);

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
  }

  Future<void> dispatch(HistoryIntent intent) async {
    if (!state.hasValue) return;

    try {
      if (intent is RefreshIntent) {
        state = await AsyncValue.guard(() => _fetchState());
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
    ref.invalidateSelf();
    await future;
  }

  /// 디버그용: FakeState를 직접 주입
  void setFakeState(HistoryState fakeState) {
    state = AsyncValue.data(fakeState);
  }
}

final historyViewModelProvider =
    AsyncNotifierProvider<HistoryViewModel, HistoryState>(
      () => HistoryViewModel(),
    );
