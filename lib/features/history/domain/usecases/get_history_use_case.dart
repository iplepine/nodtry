import '../../../../models/history_item.dart';
import '../../../../repositories/record_repository.dart';

class GetHistoryUseCase {
  final RecordRepository _repository;

  GetHistoryUseCase(this._repository);

  Future<List<HistoryItem>> execute() async {
    return _repository.getHistoryItems();
  }

  Stream<List<HistoryItem>> executeStream({List<String>? userIds}) {
    return _repository.getHistoryItemsStream(userIds: userIds);
  }
}
