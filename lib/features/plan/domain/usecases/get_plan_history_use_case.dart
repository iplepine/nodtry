import '../../../../models/history_item.dart';
import '../../../../repositories/record_repository.dart';

class GetPlanHistoryUseCase {
  final RecordRepository _repository;

  GetPlanHistoryUseCase(this._repository);

  /// [ownerId] is the plan's `userId` (picks the readable query shape).
  Stream<List<HistoryItem>> execute(String planId, {String? ownerId}) {
    return _repository.getHistoryItemsByPlanIdStream(planId, ownerId: ownerId);
  }
}
