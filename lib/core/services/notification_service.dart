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

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Get Token
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // 3. Save Token if user is logged in
      _saveTokenToFirestore(token);

      // 4. Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');
        _showLocalNotification(message);
      });
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
