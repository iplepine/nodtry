import '../l10n/app_localizations.dart';

class TimeFormatter {
  /// Time Chip용 시간 포맷팅
  static String formatForTimeChip(
    AppLocalizations l10n,
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
        return l10n.timeChipNow;
      }
      if (isPast) {
        if (absDiff.inMinutes < 5) return l10n.timeChipJustNow;
        if (absDiff.inMinutes < 60) {
          return l10n.timeChipMinutesAgo(absDiff.inMinutes);
        }
        return l10n.timeChipHoursAgo(absDiff.inHours);
      } else {
        // 미래
        if (absDiff.inMinutes < 60) {
          return l10n.timeChipMinutesLeft(absDiff.inMinutes);
        }
        return l10n.timeChipHoursLeft(absDiff.inHours);
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
      if (days == 1) return l10n.timeChipYesterday;
      return l10n.timeChipDaysAgo(days);
    }

    // 3. 미래 날짜
    final days = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;

    if (days == 1) return l10n.timeChipTomorrow;
    if (days == 2) return l10n.timeChipDayAfterTomorrow;
    if (days <= 7) return l10n.timeChipDaysLeft(days);

    // 4. 일주일 이상
    if (days <= 14) {
      return l10n.timeChipNextWeek(getWeekdayName(l10n, scheduledTime.weekday));
    }

    // 5. 그 외 (절대 날짜)
    return l10n.timeChipDate(scheduledTime.month, scheduledTime.day);
  }

  /// Vague Time 포맷팅 (아침에, 점심쯤, 저녁에 등)
  static String formatForVagueTime(
    AppLocalizations l10n,
    DateTime scheduledTime,
  ) {
    final hour = scheduledTime.hour;

    if (hour >= 5 && hour < 11) {
      return l10n.vagueTimeMorning;
    } else if (hour >= 11 && hour < 14) {
      return l10n.vagueTimeLunch;
    } else if (hour >= 14 && hour < 17) {
      return l10n.vagueTimeAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return l10n.vagueTimeEvening;
    } else if (hour >= 21 && hour < 24) {
      return l10n.vagueTimeNight;
    } else {
      return l10n.vagueTimeLateNight; // 00 ~ 05
    }
  }

  /// 정확한 시간 포맷팅 (HH:mm)
  static String formatExactTime(DateTime scheduledTime) {
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String getWeekdayName(AppLocalizations l10n, int weekday) {
    switch (weekday) {
      case 1:
        return l10n.weekdayMon;
      case 2:
        return l10n.weekdayTue;
      case 3:
        return l10n.weekdayWed;
      case 4:
        return l10n.weekdayThu;
      case 5:
        return l10n.weekdayFri;
      case 6:
        return l10n.weekdaySat;
      case 7:
        return l10n.weekdaySun;
      default:
        return '';
    }
  }
}
