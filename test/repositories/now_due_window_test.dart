import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/repositories/real_record_repository.dart';

/// "지금 탭"에서 아직 시간이 안 된 항목이 nowAction(지금 실천)으로 떠
/// 즉시 압박을 주던 문제를 막는 분류 경계 로직 검증.
void main() {
  group('RealRecordRepository.isDueNowItem', () {
    const lead = RealRecordRepository.nowActionLeadWindowMinutes; // 60

    test('시간 미지정 항목은 항상 due가 아니다 (오늘 아무 때나)', () {
      expect(
        RealRecordRepository.isDueNowItem(
          hasTime: false,
          timeInMin: 9 * 60,
          nowInMinutes: 9 * 60,
        ),
        isFalse,
      );
    });

    test('예정시각이 정확히 지금이면 due', () {
      expect(
        RealRecordRepository.isDueNowItem(
          hasTime: true,
          timeInMin: 9 * 60,
          nowInMinutes: 9 * 60,
        ),
        isTrue,
      );
    });

    test('예정시각이 윈도우 경계(now + lead)면 due', () {
      final now = 9 * 60;
      expect(
        RealRecordRepository.isDueNowItem(
          hasTime: true,
          timeInMin: now + lead,
          nowInMinutes: now,
        ),
        isTrue,
      );
    });

    test('예정시각이 윈도우보다 1분이라도 멀면 due 아님 (이따)', () {
      final now = 9 * 60;
      expect(
        RealRecordRepository.isDueNowItem(
          hasTime: true,
          timeInMin: now + lead + 1,
          nowInMinutes: now,
        ),
        isFalse,
      );
    });

    test('아침 9시에 밤 10시 예정 항목은 due 아님', () {
      expect(
        RealRecordRepository.isDueNowItem(
          hasTime: true,
          timeInMin: 22 * 60,
          nowInMinutes: 9 * 60,
        ),
        isFalse,
      );
    });

    test('leadWindow 0이면 예정시각 정각 이후에만 due', () {
      final now = 9 * 60;
      expect(
        RealRecordRepository.isDueNowItem(
          hasTime: true,
          timeInMin: now + 30,
          nowInMinutes: now,
          leadWindowMinutes: 0,
        ),
        isFalse,
      );
      expect(
        RealRecordRepository.isDueNowItem(
          hasTime: true,
          timeInMin: now,
          nowInMinutes: now,
          leadWindowMinutes: 0,
        ),
        isTrue,
      );
    });
  });
}
