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
    final profileAsync = ref.watch(myProfileProvider);
    final profile = profileAsync.value;

    // If profile is not loaded yet, wait to avoid querying with mock 'me' ID
    if (profile == null) {
      return Stream.value(const HistoryState(isLoading: true));
    }

    final myUid = profile.uid;

    // Watch partner UID for full sync
    final connectedUsers = ref.watch(connectedProfilesProvider).value ?? [];
    final partnerUid = connectedUsers.isNotEmpty
        ? connectedUsers.first.user.uid
        : null;
    final userIds = [myUid, if (partnerUid != null) partnerUid];

    final recordRepo = ref.watch(recordRepositoryProvider);

    // 1. Get Unified History Stream (Me + Partner)
    final historyStream = historyUseCase.executeStream(userIds: userIds);

    return historyStream.asyncMap((allItems) async {
      // 2. Fetch both my plans and partner plans to reconcile history and summaries
      final allPlans = <Plan>[];
      final myPlans = await recordRepo.getPlansByUserId(myUid);
      allPlans.addAll(myPlans);

      if (partnerUid != null) {
        final partnerPlans = await recordRepo.getPlansByUserId(partnerUid);
        allPlans.addAll(partnerPlans);
      }

      // Show all items (removing PlanState.active restriction to ensure all recordings are visible)
      final activeItems = List<HistoryItem>.from(allItems);
      activeItems.sort((a, b) => b.date.compareTo(a.date));

      // 3. Prepare summaries for completed plans
      final finishedPlanSummaries = <PlanSummary>[];
      final completedPlans = allPlans.where(
        (p) => p.state == PlanState.completed,
      );

      for (var plan in completedPlans) {
        final count = allItems.where((item) {
          return item.planId == plan.id &&
              (item.status == HistoryStatus.done ||
                  item.status == HistoryStatus.actuallyDone);
        }).length;

        finishedPlanSummaries.add(
          PlanSummary(
            planId: plan.id ?? '',
            title: plan.items.isNotEmpty ? plan.items.first.title : '제목 없음',
            startDate: plan.startDate,
            endDate: plan.endDate,
            myCount:
                count, // This is technically "Our Count" or "Executor Count"
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
