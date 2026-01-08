import '../services/notification_service.dart';

class SetAlarmUseCase {
  final NotificationService _notificationService;

  SetAlarmUseCase(this._notificationService);

  /// 5초 뒤 등 특정 시간 이후에 울리는 테스트 알람 설정
  Future<void> setTestAlarm({
    required int id,
    required String title,
    required String body,
    required int secondsFromNow,
  }) async {
    await _notificationService.setTestAlarm(
      id: id,
      title: title,
      body: body,
      secondsFromNow: secondsFromNow,
    );
  }

  /// 즉시 울리는 알람 표시
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationService.showInstantNotification(
      id: id,
      title: title,
      body: body,
    );
  }

  /// 모든 알람 취소
  Future<void> cancelAll() async {
    await _notificationService.cancelAllNotifications();
  }
}
