import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/context_free_l10n.dart';
import 'proof_photo.dart';

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

  /// 파트너가 실천 인정 (Rescued)
  rescued,
}

class HistoryItem {
  final String id; // 기록 고유 ID
  final String? planId; // 연관된 계획 ID
  final DateTime date;
  final String title;
  final HistoryStatus status;
  final String executorId; // 누가 했는지 (UID)
  final String? note; // 실천자가 남긴 한마디
  final String? comment; // 매니저가 남긴 피드백/응원
  final bool isVerifiedByPartner; // 파트너가 확인해줬는지 여부
  final bool isVerifiedByMe; // 내가 확인해줬는지 여부 (상대 실천에 대해)
  final String? partnerName;
  final String? partnerImageUrl;
  final String? partnerMessage; // 파트너의 응원 메시지

  /// Storage path of the proof photo (`actions.proofPhotoPath`), never a URL.
  final String? proofPhotoPath;

  /// `actions.proofSource`: `camera` or `gallery` (see [ProofSource]).
  final String? proofSource;

  /// `actions.proofTakenAt`: capture time (camera) or the album photo's
  /// original capture time when known.
  final DateTime? proofTakenAt;

  /// `actions.reaction`: the emoji the partner gave as 인정.
  final String? reaction;

  /// Whether I can give this partner record 인정: only records of a plan I
  /// manage (the rules deny the rest — e.g. the partner's plans that ended
  /// before we linked). Set by the history view model.
  final bool canVerify;

  const HistoryItem({
    required this.id,
    this.planId,
    required this.date,
    required this.title,
    required this.status,
    required this.executorId,
    this.isVerifiedByPartner = false,
    this.isVerifiedByMe = false,
    this.note,
    this.comment,
    this.partnerName,
    this.partnerImageUrl,
    this.partnerMessage,
    this.proofPhotoPath,
    this.proofSource,
    this.proofTakenAt,
    this.reaction,
    this.canVerify = true,
  });

  /// 내가 실천한 기록인지 여부
  bool isMine(String myUid) => executorId == myUid;

  /// [proofSource] parsed; null when unknown or missing.
  ProofSource? get proofSourceType => ProofSource.fromId(proofSource);

  factory HistoryItem.fromMap(Map<String, dynamic> map, String id) {
    final verifiedBy = map['verifiedBy'] as String?;
    final rawComment =
        map['partnerMessage'] as String? ?? map['comment'] as String?;

    return HistoryItem(
      id: id,
      planId: map['planId'] as String?,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      title:
          map['title'] as String? ?? contextFreeL10n().promiseUntitledFallback,
      status: _parseStatus(map['type'] as String),
      executorId: map['userId'] as String,
      note:
          map['note'] as String? ??
          (verifiedBy == null ? map['comment'] as String? : null),
      comment: rawComment,
      isVerifiedByPartner: verifiedBy != null, // repository에서 사용자 기준으로 보정 가능
      isVerifiedByMe: false, // 별도 로직으로 판단 필요
      partnerName: null, // Join 필요 (repository에서 처리)
      partnerImageUrl: null,
      partnerMessage: map['partnerMessage'] as String?,
      proofPhotoPath: _nonEmptyString(map['proofPhotoPath']),
      proofSource: _nonEmptyString(map['proofSource']),
      proofTakenAt: map['proofTakenAt'] is Timestamp
          ? (map['proofTakenAt'] as Timestamp).toDate()
          : null,
      reaction: _nonEmptyString(map['reaction']),
    );
  }

  static String? _nonEmptyString(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }

  static HistoryStatus _parseStatus(String type) {
    switch (type) {
      case 'done':
        return HistoryStatus.done;
      case 'skipped':
        return HistoryStatus.skipped;
      case 'rested':
        return HistoryStatus.rested;
      case 'rescued':
        return HistoryStatus.rescued;
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
    String? note,
    String? comment,
    bool? isVerifiedByPartner,
    bool? isVerifiedByMe,
    String? partnerName,
    String? partnerImageUrl,
    String? partnerMessage,
    String? proofPhotoPath,
    String? proofSource,
    DateTime? proofTakenAt,
    String? reaction,
    bool? canVerify,
    bool clearProofPhoto = false,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      date: date ?? this.date,
      title: title ?? this.title,
      status: status ?? this.status,
      executorId: executorId ?? this.executorId,
      note: note ?? this.note,
      comment: comment ?? this.comment,
      isVerifiedByPartner: isVerifiedByPartner ?? this.isVerifiedByPartner,
      isVerifiedByMe: isVerifiedByMe ?? this.isVerifiedByMe,
      partnerName: partnerName ?? this.partnerName,
      partnerImageUrl: partnerImageUrl ?? this.partnerImageUrl,
      partnerMessage: partnerMessage ?? this.partnerMessage,
      proofPhotoPath: clearProofPhoto
          ? null
          : proofPhotoPath ?? this.proofPhotoPath,
      proofSource: clearProofPhoto ? null : proofSource ?? this.proofSource,
      proofTakenAt: clearProofPhoto ? null : proofTakenAt ?? this.proofTakenAt,
      reaction: reaction ?? this.reaction,
      canVerify: canVerify ?? this.canVerify,
    );
  }
}
