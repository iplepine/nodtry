import '../models/home_state.dart';
import '../models/history_item.dart';

/// 기록 관련 데이터 저장소 인터페이스
///
/// '지금' 탭과 '기록' 탭에서 사용하는 데이터를 관리합니다.
abstract class RecordRepository {
  /// '지금' 탭의 카드 상태 목록을 가져옵니다.
  Future<List<HomeCardState>> getHomeCardStates();

  /// '기록' 탭의 히스토리 아이템 목록을 가져옵니다.
  Future<List<HistoryItem>> getHistoryItems();
}
