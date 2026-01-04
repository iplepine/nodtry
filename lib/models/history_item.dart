import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory HistoryItem.fromMap(Map<String, dynamic> map, String id) {
    return HistoryItem(
      id: id,
      planId: map['planId'] as String?,
      date: (map['date'] as Timestamp).toDate(),
      title: map['title'] as String? ?? '알 수 없는 계획',
      status: _parseStatus(map['type'] as String),
      executorId: map['userId'] as String,
      comment: map['comment'] as String?,
      isVerifiedByPartner: map['verifiedBy'] != null, // 확인자가 있으면 확인된 것
      isVerifiedByMe: false, // 별도 로직으로 판단 필요
      partnerName: null, // Join 필요 (repository에서 처리)
      partnerImageUrl: null,
    );
  }

  static HistoryStatus _parseStatus(String type) {
    switch (type) {
      case 'done':
        return HistoryStatus.done;
      case 'skipped':
        return HistoryStatus.skipped;
      case 'rested':
        return HistoryStatus.rested;
      default:
        return HistoryStatus.skipped;
    }
  }

  HistoryItem copyWith({
    String? id,
    String? planId,
    DateTime? date,
    String? title,
    HistoryStatus? status,
    String? executorId,
    String? comment,
    bool? isVerifiedByPartner,
    bool? isVerifiedByMe,
    String? partnerName,
    String? partnerImageUrl,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      date: date ?? this.date,
      title: title ?? this.title,
      status: status ?? this.status,
      executorId: executorId ?? this.executorId,
      comment: comment ?? this.comment,
      isVerifiedByPartner: isVerifiedByPartner ?? this.isVerifiedByPartner,
      isVerifiedByMe: isVerifiedByMe ?? this.isVerifiedByMe,
      partnerName: partnerName ?? this.partnerName,
      partnerImageUrl: partnerImageUrl ?? this.partnerImageUrl,
    );
  }
}
