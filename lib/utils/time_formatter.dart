class TimeFormatter {
  /// Time Chip용 시간 포맷팅
  ///
  /// - 오늘 내:
  ///   - 1분 이내: "지금!"
  ///   - 5분 이내: "방금 전"
  ///   - 지나간 시간: "N분 지남" or "N시간 지남"
  ///   - 다가올 시간: "N분 전" or "N시간 전"
  /// - 일주일 내: "내일", "모레", "3일 뒤"...
  /// - 일주일 후: "다음주 X요일", "M월 D일"
  static String formatForTimeChip(
    DateTime scheduledTime, {
    DateTime? baseTime,
  }) {
    final now = baseTime ?? DateTime.now();
    final diff = scheduledTime.difference(now);
    final isPast = diff.isNegative;
    final absDiff = diff.abs();

    // 1. 오늘 내 (같은 날짜)
    if (_isSameDay(now, scheduledTime)) {
      if (absDiff.inMinutes < 1) {
        return '지금!';
      }
      if (isPast) {
        if (absDiff.inMinutes < 5) return '방금 전';
        if (absDiff.inMinutes < 60) return '${absDiff.inMinutes}분 지남';
        return '${absDiff.inHours}시간 지남';
      } else {
        // 미래
        if (absDiff.inMinutes < 60) return '${absDiff.inMinutes}분 전';
        return '${absDiff.inHours}시간 전';
      }
    }

    // 2. 과거 날짜 (어제 등)
    if (isPast) {
      final days = now
          .difference(
            DateTime(
              scheduledTime.year,
              scheduledTime.month,
              scheduledTime.day,
            ),
          )
          .inDays;
      if (days == 1) return '어제';
      return '${days}일 지남';
    }

    // 3. 미래 날짜
    final days = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;

    if (days == 1) return '내일';
    if (days == 2) return '모레';
    if (days <= 7) return '$days일 뒤';

    // 4. 일주일 이상
    if (days <= 14) {
      return '다음주 ${_getWeekdayName(scheduledTime.weekday)}';
    }

    // 5. 그 외 (절대 날짜)
    return '${scheduledTime.month}월 ${scheduledTime.day}일';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _getWeekdayName(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
  }
}
