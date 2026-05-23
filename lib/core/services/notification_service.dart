import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart' as local_notifications;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final local_notifications.NotificationService _localNotifications =
      local_notifications.NotificationService();

  NotificationService(this._ref);

  /// `runApp` 직후에 호출하는 비차단 초기화.
  /// 권한 다이얼로그를 띄우지 않고, 이미 권한이 grant된 경우에만 토큰을 등록한다.
  /// (Play Pre-launch / 첫 진입 시 권한 팝업이 splash 위에 떠 앱 로딩을 막는 문제 회피)
  Future<void> setupListenersAndMaybeRegister() async {
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      _showLocalNotification(message);
    });

    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      _saveTokenToFirestore(token);
    }
  }

  /// 알림이 의미 있는 시점(예: 약속 알림 설정)에 명시 호출.
  /// 권한이 새로 grant되면 토큰도 등록한다.
  Future<void> requestPermissionAndRegister() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      _saveTokenToFirestore(token);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    await _localNotifications.showRemoteMessageNotification(message);
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _ref.read(userRepositoryProvider).updateFcmToken(user.uid, token);
        debugPrint('FCM Token saved to Firestore for user: ${user.uid}');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }
}
