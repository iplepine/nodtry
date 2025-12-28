/// 기록 상태 (Spec 3.1)
enum HistoryStatus {
  /// 했어 (Did it)
  done,

  /// 확인됐어요 (Verified)
  verified,

  /// 이번엔 못 했어 (Skipped)
  skipped,
}

/// 기록 항목 데이터 모델
/// _spec/20-feature/03-02-history-tab.md
class HistoryItem {
  final DateTime date;
  final String title;
  final HistoryStatus status;
  final String? comment;
  final String? verifierName;
  final String? verifierImageUrl;

  const HistoryItem({
    required this.date,
    required this.title,
    required this.status,
    this.comment,
    this.verifierName,
    this.verifierImageUrl,
  });

  /// 확인된 항목인지 여부
  bool get isVerified => status == HistoryStatus.verified;
}
