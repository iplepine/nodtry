import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';

/// 기록 관련 데이터 저장소 인터페이스
///
/// '지금' 탭과 '기록' 탭에서 사용하는 데이터를 관리합니다.
abstract class RecordRepository {
  /// '지금' 탭의 카드 상태 목록을 가져옵니다.
  /// (Deprecated: Use getHomeCardStatesStream for real-time updates)
  Future<List<HomeCardModel>> getHomeCardStates();

  /// '지금' 탭의 카드 상태 목록을 스트림으로 가져옵니다. (Offline-First)
  Stream<List<HomeCardModel>> getHomeCardStatesStream();

  /// '기록' 탭의 히스토리 아이템 목록을 가져옵니다.
  Future<List<HistoryItem>> getHistoryItems();

  /// '기록' 탭의 히스토리 아이템 목록을 스트림으로  /// 히스토리 내역 스트림 (실시간 반영)
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds});

  /// 특정 유저의 활성 계획 목록을 가져옵니다.
  Future<List<Plan>> getPlansByUserId(String userId);

  /// 특정 유저의 활성 계획 목록을 스트림으로 가져옵니다. (Offline-First)
  Stream<List<Plan>> getPlansByUserIdStream(String userId);

  /// 새로운 계획을 생성합니다.
  Future<void> createPlan(Plan plan);

  /// 기존 계획을 수정합니다.
  Future<void> updatePlan(Plan plan);

  /// 특정 계획을 삭제합니다.
  Future<void> deletePlan(String planId);

  /// 특정 계획을 중단합니다. (삭제 대신 상태 변경)
  Future<void> stopPlan(String planId);

  /// 특정 유저의 모든 계획을 삭제합니다. (회원 탈퇴 처리용)
  Future<void> deletePlansByUserId(String uid);

  /// 사후 정리 (Reconcile)
  Future<void> reconcilePlan(String planId, HistoryStatus status);

  /// 파트너의 실천 기록 확인 처리
  Future<void> verifyHistoryItem(String historyId, {String? message});

  /// 실천 완료 보고 (했어)
  Future<void> reportCompletion(String planId, {String? note});

  /// 파트너 응원하기 (고마워요)
  /// reactionType: 'fire', 'heart', 'thumbs_up', 'muscle' 등
  Future<void> cheerPartner(
    String planId,
    String reactionType, {
    String? message,
  });

  /// 실천 건너뛰기 보고 (오늘은 쉴게요) / 카드 넘기기
  Future<void> reportSkip(String planId);

  /// 계획 넘기기 (카드 넘기기 - secondary etc)
  Future<void> passPlan(String planId);

  /// 과거 기록 소명 (HistoryItem 수정)
  Future<void> reconcileHistoryItem(String historyId, HistoryStatus status);

  /// 기존의 모든 활성 계획에 대해 매니저를 일괄 할당합니다.
  Future<void> assignManagerToActivePlans(String managerId);

  /// 계획 승인 (pending_approval -> active)
  Future<void> approvePlan(String planId);

  /// 계획 실천 확인 (매니저가 파트너의 실천을 확인)
  Future<void> verifyPlan(String planId);
}
