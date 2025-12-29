import '../models/home_state.dart';
import '../models/history_item.dart';
import 'record_repository.dart';

/// 실제 데이터 저장소 구현체 (Firestore 연동 예정)
class RealRecordRepository implements RecordRepository {
  @override
  Future<List<HomeCardState>> getHomeCardStates() async {
    // TODO: Firestore에서 실제 데이터 가져오기
    return [];
  }

  @override
  Future<List<HistoryItem>> getHistoryItems() async {
    // TODO: Firestore에서 실제 데이터 가져오기
    return [];
  }
}
