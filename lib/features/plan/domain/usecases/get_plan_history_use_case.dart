import '../../../../models/history_item.dart';
import '../../../../repositories/record_repository.dart';

class GetPlanHistoryUseCase {
  final RecordRepository _repository;

  GetPlanHistoryUseCase(this._repository);

  Stream<List<HistoryItem>> execute(String planId) {
    return _repository.getHistoryItemsByPlanIdStream(planId);
  }
}
