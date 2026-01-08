import '../services/notification_service.dart';

class SetAlarmUseCase {
  final NotificationService _notificationService;

  SetAlarmUseCase(this._notificationService);

  /// 여러 개의 DateTime에 대해 알람을 예약합니다. (단일 책임: 알람 설정)
  Future<void> execute(List<DateTime> scheduledDates) async {
    for (int i = 0; i < scheduledDates.length; i++) {
      final date = scheduledDates[i];
      await _notificationService.scheduleNotificationAt(
        id: 99000 + i, // 고정 기초 ID + 인덱스
        title: '알람 테스트',
        body: '${date.toLocal()}에 예약된 알람입니다.',
        scheduledDate: date,
      );
    }
  }
}
