import 'package:flutter/widgets.dart';
import '../services/notification_service.dart';

class SetAlarmUseCase {
  final NotificationService _notificationService;

  SetAlarmUseCase(this._notificationService);

  /// 여러 개의 DateTime에 대해 알람을 예약합니다. (단일 책임: 알람 설정)
  Future<void> execute(List<DateTime> scheduledDates) async {
    await _notificationService.requestPermissions();

    final locale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final isKo = locale.startsWith('ko');
    final title = isKo ? '알람 테스트' : 'Alarm test';

    for (int i = 0; i < scheduledDates.length; i++) {
      final date = scheduledDates[i];
      final body = isKo
          ? '${date.toLocal()}에 예약된 알람입니다.'
          : 'Alarm scheduled for ${date.toLocal()}.';
      await _notificationService.scheduleNotificationAt(
        id: 99000 + i,
        title: title,
        body: body,
        scheduledDate: date,
      );
    }
  }
}
