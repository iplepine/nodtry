import '../services/notification_service.dart';

class CancelAllNotificationsUseCase {
  final NotificationService _notificationService;

  CancelAllNotificationsUseCase(this._notificationService);

  Future<void> execute() async {
    await _notificationService.cancelAllNotifications();
  }
}
