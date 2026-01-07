import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../models/history_item.dart';
import '../../../models/plan_summary.dart';
import '../../../widgets/quiet_header.dart';

part 'history_state.freezed.dart';

enum HistoryFilter { all, me, partner }

@freezed
abstract class HistoryState with _$HistoryState {
  const HistoryState._();
  const factory HistoryState({
    @Default([]) List<HistoryItem> activeItems,
    @Default([]) List<PlanSummary> finishedPlanSummaries,
    @Default(false) bool isLoading,
    @Default(HistoryFilter.all) HistoryFilter filter,
    @Default(null) String? partnerName,
    @Default(HeaderPeriodState.inProgress) HeaderPeriodState headerPeriodState,
    @Default(null) int? currentWeek,
    @Default(null) int? totalWeeks,
  }) = _HistoryState;
}

/// Now Tab과 동일한 MVI 패턴을 위해 확장 가능하게 구성
@freezed
class HistoryIntent with _$HistoryIntent {
  const factory HistoryIntent.refresh() = RefreshIntent;
  const factory HistoryIntent.reconcile(
    String historyId,
    HistoryStatus status,
  ) = ReconcileIntent;
  const factory HistoryIntent.setFilter(HistoryFilter filter) = SetFilterIntent;
}
