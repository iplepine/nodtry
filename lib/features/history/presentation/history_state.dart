import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../models/history_item.dart';
import '../../../models/plan_summary.dart';

part 'history_state.freezed.dart';

@freezed
abstract class HistoryState with _$HistoryState {
  const HistoryState._();
  const factory HistoryState({
    @Default([]) List<HistoryItem> activeItems,
    @Default([]) List<PlanSummary> finishedPlanSummaries,
    @Default(false) bool isLoading,
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
}
