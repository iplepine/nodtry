import '../services/notification_service.dart';

class ShowInstantNotificationUseCase {
  final NotificationService _notificationService;

  ShowInstantNotificationUseCase(this._notificationService);

  Future<void> execute({
    required int id,
    required String title,
    required String body,
  }) async {
    // 권한 확인 및 요청
    await _notificationService.requestPermissions();

    await _notificationService.showInstantNotification(
      id: id,
      title: title,
      body: body,
    );
  }
}
