import 'package:flutter_test/flutter_test.dart';
import 'package:mind_gardener/utils/time_formatter.dart';

void main() {
  group('TimeFormatter', () {
    final baseTime = DateTime(2025, 1, 1, 12, 0, 0); // Noon

    test('오늘 - 1분 미만', () {
      final target = baseTime.add(const Duration(seconds: 30));
      expect(
        TimeFormatter.formatForTimeChip(target, baseTime: baseTime),
        '지금!',
      );
    });

    test('오늘 - 5분 미만 (과거)', () {
      final target = baseTime.subtract(const Duration(minutes: 3));
      expect(
        TimeFormatter.formatForTimeChip(target, baseTime: baseTime),
        '방금 전',
      );
    });

    test('오늘 - 30분 전 (미래)', () {
      final target = baseTime.add(const Duration(minutes: 30));
      expect(
        TimeFormatter.formatForTimeChip(target, baseTime: baseTime),
        '30분 전',
      );
    });

    test('오늘 - 30분 지남 (과거)', () {
      final target = baseTime.subtract(const Duration(minutes: 30));
      expect(
        TimeFormatter.formatForTimeChip(target, baseTime: baseTime),
        '30분 지남',
      );
    });

    test('오늘 - 2시간 전 (미래)', () {
      final target = baseTime.add(const Duration(hours: 2));
      expect(
        TimeFormatter.formatForTimeChip(target, baseTime: baseTime),
        '2시간 전',
      );
    });

    test('내일', () {
      final target = baseTime.add(const Duration(days: 1));
      expect(TimeFormatter.formatForTimeChip(target, baseTime: baseTime), '내일');
    });

    test('모레', () {
      final target = baseTime.add(const Duration(days: 2));
      expect(TimeFormatter.formatForTimeChip(target, baseTime: baseTime), '모레');
    });

    test('3일 뒤', () {
      final target = baseTime.add(const Duration(days: 3));
      expect(
        TimeFormatter.formatForTimeChip(target, baseTime: baseTime),
        '3일 뒤',
      );
    });
  });
}
