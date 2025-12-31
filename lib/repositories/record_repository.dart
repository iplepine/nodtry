import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';

/// 기록 관련 데이터 저장소 인터페이스
///
/// '지금' 탭과 '기록' 탭에서 사용하는 데이터를 관리합니다.
abstract class RecordRepository {
  /// '지금' 탭의 카드 상태 목록을 가져옵니다.
  Future<List<HomeCardModel>> getHomeCardStates();

  /// '기록' 탭의 히스토리 아이템 목록을 가져옵니다.
  Future<List<HistoryItem>> getHistoryItems();

  /// 새로운 계획을 생성합니다.
  Future<void> createPlan(Plan plan);

  /// 특정 유저의 모든 계획을 삭제합니다. (회원 탈퇴 처리용)
  Future<void> deletePlansByUserId(String uid);

  /// 사후 정리 (Reconcile)
  Future<void> reconcilePlan(String planId, HistoryStatus status);

  /// 파트너의 실천 기록 확인 처리
  Future<void> verifyHistoryItem(String historyId);
}
