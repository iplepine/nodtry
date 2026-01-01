import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/utils/time_formatter.dart';
import 'package:nod_try/l10n/app_localizations.dart';

void main() {
  group('TimeFormatter', () {
    final baseTime = DateTime(2025, 1, 1, 12, 0, 0); // Noon
    final l10n = FakeAppLocalizations();

    test('오늘 - 1분 미만', () {
      final target = baseTime.add(const Duration(seconds: 30));
      expect(
        TimeFormatter.formatForTimeChip(l10n, target, baseTime: baseTime),
        '지금!',
      );
    });

    test('오늘 - 5분 미만 (과거)', () {
      final target = baseTime.subtract(const Duration(minutes: 3));
      expect(
        TimeFormatter.formatForTimeChip(l10n, target, baseTime: baseTime),
        '방금 전',
      );
    });

    test('오늘 - 30분 전 (미래)', () {
      final target = baseTime.add(const Duration(minutes: 30));
      expect(
        TimeFormatter.formatForTimeChip(l10n, target, baseTime: baseTime),
        '30분 전',
      );
    });

    test('오늘 - 30분 지남 (과거)', () {
      final target = baseTime.subtract(const Duration(minutes: 30));
      expect(
        TimeFormatter.formatForTimeChip(l10n, target, baseTime: baseTime),
        '30분 지남',
      );
    });

    test('오늘 - 2시간 전 (미래)', () {
      final target = baseTime.add(const Duration(hours: 2));
      expect(
        TimeFormatter.formatForTimeChip(l10n, target, baseTime: baseTime),
        '2시간 전',
      );
    });

    test('내일', () {
      final target = baseTime.add(const Duration(days: 1));
      expect(
        TimeFormatter.formatForTimeChip(l10n, target, baseTime: baseTime),
        '내일',
      );
    });

    test('모레', () {
      final target = baseTime.add(const Duration(days: 2));
      expect(
        TimeFormatter.formatForTimeChip(l10n, target, baseTime: baseTime),
        '모레',
      );
    });

    test('3일 뒤', () {
      final target = baseTime.add(const Duration(days: 3));
      expect(
        TimeFormatter.formatForTimeChip(l10n, target, baseTime: baseTime),
        '3일 뒤',
      );
    });
  });
}

class FakeAppLocalizations extends Fake implements AppLocalizations {
  @override
  String get timeChipNow => '지금!';
  @override
  String get timeChipJustNow => '방금 전';
  @override
  String timeChipMinutesAgo(int m) => '$m분 지남';
  @override
  String timeChipHoursAgo(int h) => '$h시간 지남';
  @override
  String timeChipMinutesLeft(int m) => '$m분 전';
  @override
  String timeChipHoursLeft(int h) => '$h시간 전';
  @override
  String get timeChipYesterday => '어제';
  @override
  String timeChipDaysAgo(int d) => '$d일 지남';
  @override
  String get timeChipTomorrow => '내일';
  @override
  String get timeChipDayAfterTomorrow => '모레';
  @override
  String timeChipDaysLeft(int d) => '$d일 뒤';
  @override
  String timeChipNextWeek(String w) => '다음주 $w';
  @override
  String timeChipDate(int m, int d) => '$m월 $d일'; // 테스트에 없지만 구현

  @override
  String get weekdayMon => '월';
  @override
  String get weekdayTue => '화';
  @override
  String get weekdayWed => '수';
  @override
  String get weekdayThu => '목';
  @override
  String get weekdayFri => '금';
  @override
  String get weekdaySat => '토';
  @override
  String get weekdaySun => '일';
}
