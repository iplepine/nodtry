/// 시간 표현 유틸리티
/// 
/// 스펙: '지금' 탭에서는 날짜 대신 상대적 시간 표현만 사용
/// - D-2, D-1
/// - 3시간 남음, 30분 남음
/// - 곧 다가와요
class TimeFormatter {
  /// Duration을 상대적 시간 문자열로 변환
  /// 
  /// 예시:
  /// - "3시간 남음"
  /// - "30분 남음"
  /// - "곧 다가와요" (1시간 미만)
  static String formatTimeRemaining(Duration remaining) {
    if (remaining.inDays > 0) {
      return '${remaining.inDays}일 남음';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}시간 남음';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}분 남음';
    } else {
      return '곧 다가와요';
    }
  }

  /// 과거 시간을 상대적 시간 문자열로 변환
  /// 
  /// 예시:
  /// - "3시간 전"
  /// - "30분 전"
  /// - "어제"
  /// - "2일 전"
  static String formatTimePast(Duration past) {
    final days = past.inDays;
    final hours = past.inHours;
    final minutes = past.inMinutes;
    
    if (days > 0) {
      if (days == 1) {
        return '어제';
      } else {
        return '$days일 전';
      }
    } else if (hours > 0) {
      return '$hours시간 전';
    } else if (minutes > 0) {
      return '$minutes분 전';
    } else {
      return '방금 전';
    }
  }

  /// 날짜 차이를 D-X 형식으로 변환
  /// 
  /// 예시:
  /// - "D-2"
  /// - "D-1"
  static String formatDaysRemaining(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    final days = difference.inDays;
    
    if (days < 0) {
      return 'D+${-days}';
    } else if (days == 0) {
      return '오늘';
    } else {
      return 'D-$days';
    }
  }

  /// 다음 행동까지의 시간을 포맷팅
  /// 
  /// 스펙: "다음 행동까지 3시간 남았어요"
  static String formatNextActionTime(Duration remaining) {
    return formatTimeRemaining(remaining);
  }

  /// 다음 일정까지의 일수를 포맷팅
  /// 
  /// 스펙: "다음 일정까지 D-2예요"
  static String formatNextScheduleDays(DateTime targetDate) {
    final days = formatDaysRemaining(targetDate);
    return days.startsWith('D-') ? days : 'D-0';
  }
}

