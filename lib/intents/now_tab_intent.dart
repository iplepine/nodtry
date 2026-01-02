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
  const CompletePlanIntent(this.planId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletePlanIntent &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
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
