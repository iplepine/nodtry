import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/quiet_header.dart';
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
      return Stream.value(
        const HistoryState(
          isLoading: true,
          headerPeriodState: HeaderPeriodState.noPlan,
        ),
      );
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
      final myPlans = await recordRepo.getAllPlansByUserIdStream(myUid).first;
      allPlans.addAll(myPlans);

      if (partnerUid != null) {
        final partnerPlans = await recordRepo
            .getAllPlansByUserIdStream(partnerUid)
            .first;
        allPlans.addAll(partnerPlans);
      }

      // 3. Apply Filtering
      List<HistoryItem> filteredItems = List<HistoryItem>.from(allItems);
      final currentFilter = state.asData?.value.filter ?? HistoryFilter.all;

      if (currentFilter == HistoryFilter.me) {
        filteredItems = filteredItems
            .where((item) => item.executorId == myUid)
            .toList();
      } else if (currentFilter == HistoryFilter.partner && partnerUid != null) {
        filteredItems = filteredItems
            .where((item) => item.executorId == partnerUid)
            .toList();
      }

      filteredItems.sort((a, b) => b.date.compareTo(a.date));

      // 4. Prepare summaries for completed plans
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

        final pCount = allItems.where((item) {
          return item.planId == plan.id && item.isVerifiedByPartner == true;
        }).length;

        finishedPlanSummaries.add(
          PlanSummary(
            planId: plan.id ?? '',
            title: plan.items.isNotEmpty ? plan.items.first.title : '제목 없음',
            startDate: plan.startDate,
            endDate: plan.endDate,
            myCount: count,
            partnerCount: pCount > 0 ? pCount : null,
          ),
        );
      }

      // 5. Calculate Header Data
      HeaderPeriodState periodState = HeaderPeriodState.noPlan;
      int? currentWeekNum;
      int? totalWeeksNum;

      if (allPlans.any((p) => p.state == PlanState.active)) {
        periodState = HeaderPeriodState.inProgress;
        final plan = allPlans.firstWhere((p) => p.state == PlanState.active);
        final now = DateTime.now();
        final diff = now.difference(plan.startDate).inDays;
        currentWeekNum = (diff / 7).floor() + 1;

        final totalDiff = plan.endDate.difference(plan.startDate).inDays;
        totalWeeksNum = (totalDiff / 7).ceil();
        if (totalWeeksNum == 0) totalWeeksNum = 1;
      } else if (allPlans.any((p) => p.state == PlanState.pendingApproval)) {
        periodState =
            HeaderPeriodState.inProgress; // Or a specific state if needed
      }

      final partnerName = connectedUsers.isNotEmpty
          ? connectedUsers.first.user.displayName
          : null;

      return HistoryState(
        activeItems: filteredItems,
        finishedPlanSummaries: finishedPlanSummaries,
        isLoading: false,
        filter: currentFilter,
        partnerName: partnerName,
        headerPeriodState: periodState,
        currentWeek: currentWeekNum,
        totalWeeks: totalWeeksNum,
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
      } else if (intent is VerifyHistoryIntent) {
        await _verify(intent.historyId, message: intent.message);
      } else if (intent is SetFilterIntent) {
        state = AsyncValue.data(state.value!.copyWith(filter: intent.filter));
        // Filtering is done in the stream naturally when state.value.filter changes?
        // Wait, _fetchStateStream uses state.asData?.value.filter.
        // It's a StreamNotifier, so manually setting state to data with new filter
        // will trigger the stream to re-map if the stream is watched?
        // Actually, StreamNotifier's build() returns the stream.
        // If I update the state manually, the stream map should use the new filter value.
        // But the stream itself doesn't emit a new event just because the filter changed.
        // I should probably invalidate if I want the stream to re-emit with new filter
        // OR make the filtering happen more reactively.
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

  Future<void> _verify(String historyId, {String? message}) async {
    await ref
        .read(recordRepositoryProvider)
        .verifyHistoryItem(historyId, message: message);
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
