import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart' as local_notifications;
import '../../utils/analytics.dart';

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
    _messaging.onTokenRefresh.listen(
      _saveTokenToFirestore,
      onError: (Object error, StackTrace stack) {
        _logMessagingError('onTokenRefresh', error, stack);
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      _showLocalNotification(message);
    });

    // 알림 탭으로 앱이 열린 경우(백그라운드 → 포그라운드) 재참여 신호 기록.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AnalyticsService.log(AnalyticsEvent.notificationOpened, {
        'type': message.data['type']?.toString() ?? 'unknown',
      });
    });

    // 종료 상태에서 알림 탭으로 콜드 스타트된 경우.
    final initialMessage = await _getInitialMessage();
    if (initialMessage != null) {
      AnalyticsService.log(AnalyticsEvent.notificationOpened, {
        'type': initialMessage.data['type']?.toString() ?? 'unknown',
        'cold_start': true,
      });
    }

    final settings = await _getNotificationSettings();
    if (settings == null) return;
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerCurrentToken();
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // The user has declined / revoked notifications. The app's core loop
      // (knocks, cheers, missed-action nudges) is delivered via FCM, so a stale
      // token left in Firestore would just generate dead sends. Clear it; the
      // token re-registers automatically if the user re-enables notifications.
      _clearTokenFromFirestore();
    }
    // notDetermined: we haven't asked yet — leave it for the explicit
    // permission request at the meaningful moment (e.g. setting a reminder).
  }

  /// Whether the OS currently grants notification permission. Lets the UI nudge
  /// the user to re-enable, since partner signals depend on it.
  Future<bool> hasPermission() async {
    final settings = await _getNotificationSettings();
    if (settings == null) return false;
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// 알림이 의미 있는 시점(예: 약속 알림 설정)에 명시 호출.
  /// 권한이 새로 grant되면 토큰도 등록한다.
  Future<void> requestPermissionAndRegister() async {
    final NotificationSettings settings;
    try {
      settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (error, stack) {
      _logMessagingError('requestPermission', error, stack);
      return;
    }
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    AnalyticsService.log(AnalyticsEvent.notificationPermissionResult, {
      'granted': granted,
    });
    if (granted) {
      await _registerCurrentToken();
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

  Future<RemoteMessage?> _getInitialMessage() async {
    try {
      return await _messaging.getInitialMessage();
    } catch (error, stack) {
      _logMessagingError('getInitialMessage', error, stack);
      return null;
    }
  }

  Future<NotificationSettings?> _getNotificationSettings() async {
    try {
      return await _messaging.getNotificationSettings();
    } catch (error, stack) {
      _logMessagingError('getNotificationSettings', error, stack);
      return null;
    }
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      await _saveTokenToFirestore(token);
    } catch (error, stack) {
      // Devices without a usable Firebase Instance ID service can throw
      // MISSING_INSTANCEID_SERVICE here. Push delivery may be unavailable on
      // that device, but app startup and local reminders must keep working.
      _logMessagingError('getToken', error, stack);
    }
  }

  void _logMessagingError(String operation, Object error, [StackTrace? stack]) {
    debugPrint('[Notification] FirebaseMessaging.$operation failed: $error');
    if (stack != null) {
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> _clearTokenFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _ref.read(userRepositoryProvider).clearFcmToken(user.uid);
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }
  }
}
