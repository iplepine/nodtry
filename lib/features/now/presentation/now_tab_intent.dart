import 'package:flutter/foundation.dart';

/// Now Tab에서 발생하는 사용자 의도(Intent) 정의
/// MVI 패턴의 'Intent' 역할
@immutable
sealed class NowTabIntent {
  const NowTabIntent();
}

/// 계획 실천 완료 (했어/넘어갈게요)
class CompletePlanIntent extends NowTabIntent {
  final String planId;
  final String? message;
  const CompletePlanIntent(this.planId, {this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletePlanIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          message == other.message;

  @override
  int get hashCode => planId.hashCode ^ message.hashCode;
}

/// 파트너 실천 확인 (확인하기/응원하기)
class CheckPartnerActionIntent extends NowTabIntent {
  final String planId;
  const CheckPartnerActionIntent(this.planId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckPartnerActionIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}

/// 화면 새로고침
class RefreshIntent extends NowTabIntent {
  const RefreshIntent();
}

/// 계획 건너뛰기 (오늘은 쉴게요)
class SkipPlanIntent extends NowTabIntent {
  final String planId;
  const SkipPlanIntent(this.planId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkipPlanIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}

/// 파트너 응원하기 (고마워요 + 리액션)
class CheerPartnerActionIntent extends NowTabIntent {
  final String planId;
  final String reactionType; // 'fire', 'heart', 'thumbs_up', 'muscle'
  final String? message;
  const CheerPartnerActionIntent(
    this.planId,
    this.reactionType, {
    this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheerPartnerActionIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          reactionType == other.reactionType &&
          message == other.message;

  @override
  int get hashCode =>
      planId.hashCode ^ reactionType.hashCode ^ (message?.hashCode ?? 0);
}

/// 계획 넘기기 (카드 넘기기)
class PassPlanIntent extends NowTabIntent {
  final String planId;
  const PassPlanIntent(this.planId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassPlanIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}

/// 계획 승인 (pending_approval -> active)
class ApprovePlanIntent extends NowTabIntent {
  final String planId;
  const ApprovePlanIntent(this.planId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovePlanIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}

/// 파트너 실천 확인 (사실 했어요 -> 확인됨)
class VerifyPartnerPlanIntent extends NowTabIntent {
  final String planId;
  const VerifyPartnerPlanIntent(this.planId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerifyPartnerPlanIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}
