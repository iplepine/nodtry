/// 기록 상태 (Spec 3.1)
enum HistoryStatus {
  /// 했어 (Did it)
  done,

  /// 사실 했어요 (Actually did it - Reconciled)
  actuallyDone,

  /// 오늘은 쉬어갔어요 (Took a rest - Reconciled)
  rested,

  /// 확인됐어요 (Verified)
  verified,

  /// 이번엔 못 했어 (Skipped)
  skipped,
}

class HistoryItem {
  final String id; // 기록 고유 ID
  final String? planId; // 연관된 계획 ID
  final DateTime date;
  final String title;
  final HistoryStatus status;
  final String executorId; // 누가 했는지 (UID)
  final String? comment;
  final bool isVerifiedByPartner; // 파트너가 확인해줬는지 여부
  final bool isVerifiedByMe; // 내가 확인해줬는지 여부 (상대 실천에 대해)
  final String? partnerName;
  final String? partnerImageUrl;

  const HistoryItem({
    required this.id,
    this.planId,
    required this.date,
    required this.title,
    required this.status,
    required this.executorId,
    this.isVerifiedByPartner = false,
    this.isVerifiedByMe = false,
    this.comment,
    this.partnerName,
    this.partnerImageUrl,
  });

  /// 내가 실천한 기록인지 여부
  bool isMine(String myUid) => executorId == myUid;
}
