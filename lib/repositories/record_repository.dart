import 'dart:typed_data';

import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';
import '../models/promise_model.dart';
import '../models/proof_photo.dart';

/// 이번 주 휴식권을 이미 써서 [RecordRepository.reportRest]가 거절된 경우.
///
/// Why: 예전에는 한국어 문장을 담은 [Exception]을 던지고 UI가 그 문장을
/// `contains('이미 사용')`으로 검사했다. 저장소가 던지는 문장이 로케일과
/// 무관하게 한국어여서 우연히 동작했을 뿐이라, 문구를 다듬는 순간 조용히
/// 깨지는 구조였다. 타입으로 구분하면 그런 결합이 사라진다.
class RestPassAlreadyUsedException implements Exception {
  const RestPassAlreadyUsedException();
}

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

  /// '기록' 탭의 히스토리 내역 스트림 (실시간 반영), 최신순.
  ///
  /// [userIds] 중 나는 내 기록 전부, 짝꿍은 나에게 공유된 기록만
  /// (`actions.managerId == me`, 즉 내가 봐주는 약속의 기록). 비우면 내 것만.
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds});

  /// 특정 유저의 활성 계획 목록을 가져옵니다. 짝꿍이면 내가 봐주는
  /// (`managerId == me`) 계획만 — 나머지는 읽기 권한이 없습니다.
  Future<List<Plan>> getPlansByUserId(String userId);

  /// 특정 유저의 활성 계획 목록을 스트림으로 가져옵니다. (Offline-First)
  /// 짝꿍이면 내가 봐주는 계획만.
  Stream<List<Plan>> getPlansByUserIdStream(String userId);

  /// 특정 유저의 모든 계획 목록(상태 상관없이)을 스트림으로 가져옵니다.
  /// 짝꿍이면 내가 봐주는 계획만.
  Stream<List<Plan>> getAllPlansByUserIdStream(String userId);

  /// 새로운 계획을 생성합니다. (생성된 ID 반환)
  Future<String> createPlan(Plan plan);

  /// 기존 계획을 수정합니다.
  Future<void> updatePlan(Plan plan);

  /// Replaces only the plan's `items` (e.g. a reminder time edited by the
  /// owner) and stamps `lastUpdatedBy` with me. A whole-document
  /// [updatePlan] kept a stale `lastUpdatedBy` (often the partner after their
  /// 인정) — the server then pushed "약속 바꿨어" to me instead of them — and
  /// replayed record arrays from when the editor opened.
  Future<void> updatePlanItems(String planId, List<PlanItem> items);

  /// 특정 계획을 삭제합니다.
  Future<void> deletePlan(String planId);

  /// 특정 계획을 중단합니다. (삭제 대신 상태 변경)
  Future<void> stopPlan(String planId);

  /// 특정 유저의 모든 계획을 삭제합니다. (회원 탈퇴 처리용)
  Future<void> deletePlansByUserId(String uid);

  /// 사후 정리 (Reconcile)
  Future<void> reconcilePlan(String planId, HistoryStatus status);

  /// 파트너의 기록 인정. [reaction] is the one-tap emoji (❤️🔥💪👏), stored as
  /// `actions.reaction`.
  Future<void> verifyHistoryItem(
    String historyId, {
    String? message,
    String? reaction,
  });

  /// 했어 report, optionally with a proof photo (인증샷).
  ///
  /// The photo is uploaded first (bounded by [kProofUploadTimeout]); if that
  /// fails the record is still saved, without the photo, and the result says
  /// so ([ProofCompletionResult.photoFailed]).
  Future<ProofCompletionResult> reportCompletion(
    String planId, {
    String? note,
    ProofPhotoUpload? photo,
  });

  /// One `actions` record by id (e.g. the one a proof photo belongs to), or
  /// null when it doesn't exist.
  Future<HistoryItem?> getHistoryItem(String actionId);

  /// Bytes of the proof photo at Storage [path] (`proofs/…`). Throws when the
  /// read is denied (e.g. after disconnecting); null when the object is gone.
  Future<Uint8List?> downloadProofPhoto(String path);

  /// The owner removes one of their proof photos: the Storage object and the
  /// proof fields on the action (and on the plan when it is the latest one).
  Future<void> deleteProofPhoto(String photoPath);

  /// 파트너 인정 + 응원. [reactionType] is the emoji the partner tapped
  /// (❤️🔥💪👏); it is also stored as `actions.reaction`.
  Future<void> cheerPartner(
    String planId,
    String reactionType, {
    String? message,
  });

  /// One-tap answer to a knock (지금 간다 🏃 / 오늘은 봐줘 🙏): a `cheers` doc
  /// `{fromUserId, toUserId, planId, reactionType: 'reply', message}` (spec
  /// §9). It touches no plan or action field.
  Future<void> replyToPoke(
    String planId, {
    required String toUserId,
    required String message,
  });

  /// 응원 on the partner's missed-workout card: a `cheers` doc with the
  /// [emoji] as reactionType and an optional [message]. Unlike [cheerPartner]
  /// this is not 인정 — no verifiedDates, no action update — so a day the
  /// partner hasn't recorded is never marked acknowledged.
  Future<void> sendCheer(
    String toUserId, {
    String? planId,
    required String emoji,
    String? message,
  });

  /// 실천 건너뛰기 보고 (오늘은 쉴게요) / 카드 넘기기
  Future<void> reportSkip(String planId);

  /// 계획 넘기기 (카드 넘기기 - secondary etc)
  Future<void> passPlan(String planId);

  /// 파트너 찌르기 (똑똑)
  /// message: "똑똑! 실천 메이트가 기다리고 있어요." 등
  Future<void> pokePartner(String planId, {String? message});

  /// 찌르기 확인 (응답)
  Future<void> acknowledgePoke(String planId);

  /// 과거 기록 소명 (HistoryItem 수정)
  Future<void> reconcileHistoryItem(String historyId, HistoryStatus status);

  /// 매니저가 없는 내 진행 중 약속에 새 짝꿍을 매니저로 지정합니다.
  /// 상태는 바꾸지 않습니다(승인 단계 없음). `lastUpdatedBy`는 'system_link'.
  Future<void> assignManagerToActivePlans(String managerId);

  /// 계획 승인 (pending_approval -> active)
  Future<void> approvePlan(String planId);

  /// 계획 실천 확인 (매니저가 파트너의 실천을 확인)
  Future<void> verifyPlan(String planId);

  /// 계획 반려(조율 요청) (pending_approval -> rejected)
  Future<void> rejectPlan(String planId, {String? reason});

  /// 특정 계획의 히스토리 아이템 목록을 스트림으로 가져옵니다 (최신순).
  /// [ownerId]는 계획 주인(`plan.userId`): 내 계획이면 내 기록, 짝꿍 계획이면
  /// 나에게 공유된 기록만 읽습니다. 모르면 비워 두세요(두 쿼리를 합칩니다).
  Stream<List<HistoryItem>> getHistoryItemsByPlanIdStream(
    String planId, {
    String? ownerId,
  });

  /// 기간이 만료된 진행/승인 대기 계획들을 찾아 '완료(completed)' 상태로 자동 전환합니다.
  Future<List<String>> completeOverduePlans();

  /// 특정 유저를 찌릅니다. (계획과 상관없이)
  Future<void> pokeUser(String userId, {String? message});

  /// 약속 제안 (보상/벌칙). reward, penalty 중 최소 하나는 non-null.
  Future<void> proposePromise(
    String planId, {
    PromiseReward? reward,
    PromisePenalty? penalty,
  });

  /// 약속 수락 또는 거절.
  Future<void> respondPromise(String planId, {required bool accept});

  /// 약속 정산. Plan 종료/중단 시 내부적으로 호출.
  Future<void> settlePromise(String planId);

  /// 정산 결과 카드를 현재 사용자가 확인 처리(닫기). 한마디 코멘트를 함께 남길 수 있다.
  Future<void> acknowledgePromiseSettlement(String planId, {String? comment});

  /// 파트너 실천 인정 (스트릭 구제)
  Future<void> rescuePlan(String planId, {DateTime? date});

  /// 휴식권 사용 (주 1회, 스트릭 유지)
  Future<void> reportRest(String planId);

  /// 4주 파일럿 정산 응답 기록.
  Future<void> recordPilotSettlement(
    String planId, {
    required String nextPlanIntent,
    String? exitReason,
  });
}
