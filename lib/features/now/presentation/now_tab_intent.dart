import 'package:flutter/foundation.dart';
import '../../../models/promise_model.dart';

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

/// 계획 반려 (pending_approval -> rejected)
class RejectPlanIntent extends NowTabIntent {
  final String planId;
  final String? reason;
  const RejectPlanIntent(this.planId, {this.reason});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RejectPlanIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          reason == other.reason;

  @override
  int get hashCode => planId.hashCode ^ reason.hashCode;
}

/// 찌르기 확인 (똑똑 -> 네)
class AcknowledgePokeIntent extends NowTabIntent {
  final String planId;
  const AcknowledgePokeIntent(this.planId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcknowledgePokeIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}

/// 유저 찌르기 (계획 없이 똑똑)
class PokeUserIntent extends NowTabIntent {
  final String userId;
  final String? message;
  const PokeUserIntent(this.userId, {this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokeUserIntent &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          message == other.message;

  @override
  int get hashCode => userId.hashCode ^ (message?.hashCode ?? 0);
}

/// 특정 계획 찌르기 (계획에 대해 똑똑)
class PokePartnerIntent extends NowTabIntent {
  final String planId;
  final String? message;
  final PromiseReward? reward;
  final PromisePenalty? penalty;
  const PokePartnerIntent(
    this.planId, {
    this.message,
    this.reward,
    this.penalty,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokePartnerIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          message == other.message;

  @override
  int get hashCode => planId.hashCode ^ (message?.hashCode ?? 0);
}

/// 약속 제안 (보상/벌칙)
class ProposePromiseIntent extends NowTabIntent {
  final String planId;
  final PromiseReward? reward;
  final PromisePenalty? penalty;
  const ProposePromiseIntent(this.planId, {this.reward, this.penalty});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposePromiseIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}

/// 약속 수락/거절
class RespondPromiseIntent extends NowTabIntent {
  final String planId;
  final bool accept;
  const RespondPromiseIntent(this.planId, {required this.accept});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RespondPromiseIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          accept == other.accept;

  @override
  int get hashCode => planId.hashCode ^ accept.hashCode;
}

/// 파트너 실천 인정 (스트릭 구제)
class RescuePlanIntent extends NowTabIntent {
  final String planId;
  const RescuePlanIntent(this.planId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RescuePlanIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}

/// 휴식권 사용 (주 1회)
class RestPlanIntent extends NowTabIntent {
  final String planId;
  const RestPlanIntent(this.planId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestPlanIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}

/// 약속 정산 결과 확인 (선택적으로 한마디 코멘트 첨부)
class AcknowledgePromiseSettlementIntent extends NowTabIntent {
  final String planId;
  final String? comment;
  const AcknowledgePromiseSettlementIntent(this.planId, {this.comment});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcknowledgePromiseSettlementIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          comment == other.comment;

  @override
  int get hashCode => planId.hashCode ^ (comment?.hashCode ?? 0);
}

/// 4주 파일럿 정산 응답 기록
class RecordPilotSettlementIntent extends NowTabIntent {
  final String planId;
  final String nextPlanIntent;
  final String? exitReason;

  const RecordPilotSettlementIntent(
    this.planId, {
    required this.nextPlanIntent,
    this.exitReason,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordPilotSettlementIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          nextPlanIntent == other.nextPlanIntent &&
          exitReason == other.exitReason;

  @override
  int get hashCode =>
      planId.hashCode ^ nextPlanIntent.hashCode ^ (exitReason?.hashCode ?? 0);
}
