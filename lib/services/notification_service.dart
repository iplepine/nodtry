import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

const String _snoozeActionId = 'snooze_10m';
const String _didItActionId = 'did_it_now';
const String _skipTodayActionId = 'skip_today';
const String _snoozeDarwinCategoryId = 'snooze_reminder';
const int _planNotificationIdModulo = 200000000;

@immutable
class NotificationInputRequest {
  final String? planId;
  final String? title;

  const NotificationInputRequest({this.planId, this.title});
}

@immutable
class NotificationSkipRequest {
  final String? planId;
  final String? title;

  const NotificationSkipRequest({this.planId, this.title});
}

abstract class PlanReminderScheduler {
  Future<void> requestPermissions();

  Future<void> schedulePlanReminder({
    required int planId,
    String? planIdentifier,
    required String title,
    required int hour,
    required int minute,
    required List<int> days,
    bool skipToday,
  });

  Future<void> cancelPlanReminders(int planId);
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService().handleNotificationResponse(response);
}

class NotificationService implements PlanReminderScheduler {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationInputRequest> _inputRequestController =
      StreamController<NotificationInputRequest>.broadcast();
  final StreamController<NotificationSkipRequest> _skipRequestController =
      StreamController<NotificationSkipRequest>.broadcast();

  bool _isInitialized = false;
  NotificationInputRequest? _pendingInputRequest;
  NotificationSkipRequest? _pendingSkipRequest;

  Stream<NotificationInputRequest> get inputRequests =>
      _inputRequestController.stream;
  Stream<NotificationSkipRequest> get skipRequests =>
      _skipRequestController.stream;

  NotificationInputRequest? takePendingInputRequest() {
    final request = _pendingInputRequest;
    _pendingInputRequest = null;
    return request;
  }

  NotificationSkipRequest? takePendingSkipRequest() {
    final request = _pendingSkipRequest;
    _pendingSkipRequest = null;
    return request;
  }

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones(); // Ensure timezones are loaded first
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    debugPrint(
      'NotificationService initialized with timezone: ${timezoneInfo.identifier}',
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
          notificationCategories: <DarwinNotificationCategory>[
            DarwinNotificationCategory(
              _snoozeDarwinCategoryId,
              actions: <DarwinNotificationAction>[
                DarwinNotificationAction.plain(
                  _didItActionId,
                  '했어',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
                DarwinNotificationAction.plain(
                  _skipTodayActionId,
                  '오늘은 패스',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
                DarwinNotificationAction.plain(_snoozeActionId, '10분 후 다시 묻기'),
              ],
            ),
          ],
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _isInitialized = true;

    final launchDetails = await flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse != null) {
      await handleNotificationResponse(launchResponse);
    }
  }

  @override
  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.requestNotificationsPermission();

    // Exact Alarm permission for Android 13+
    if (Platform.isAndroid) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      return await Permission.scheduleExactAlarm.isGranted;
    }
    return true; // iOS doesn't have this specific exact alarm permission
  }

  /// Schedule a notification for a plan
  /// [id] should be unique per plan-day combination or plan ID base
  /// [days] 1=Mon, 7=Sun (compatible with DateTime.weekday)
  /// [skipToday] if true, and the next instance is today, it will schedule for next week instead
  @override
  Future<void> schedulePlanReminder({
    required int planId, // Using plan.hashCode or similar as base
    String? planIdentifier,
    required String title,
    required int hour,
    required int minute,
    required List<int> days,
    bool skipToday = false,
  }) async {
    final normalizedPlanId = _normalizePlanNotificationBaseId(planId);

    await cancelPlanReminders(normalizedPlanId);

    for (int day in days) {
      final tz.TZDateTime scheduledDate = _nextInstanceOfDayAndTime(
        day,
        hour,
        minute,
        skipToday: skipToday,
      );
      debugPrint(
        '[Notification] Scheduling for plan $planId, day $day at $hour:$minute. Calculated time: $scheduledDate (Local now: ${tz.TZDateTime.now(tz.local)})',
      );

      await _scheduleWeekly(
        id: _buildPlanDayNotificationId(normalizedPlanId, day),
        title: title,
        body: "오늘 약속, 같이 이어갈까요?", // Warm Accountability Copy
        hour: hour,
        minute: minute,
        day: day,
        scheduledDate: scheduledDate,
        planIdentifier: planIdentifier,
      );
    }
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int day, // 1=Mon, 7=Sun
    required tz.TZDateTime scheduledDate,
    String? planIdentifier,
  }) async {
    final notificationDetails = _buildNotificationDetails(
      channelId: 'plan_reminders',
      channelName: 'Plan Reminders',
      channelDescription: 'Notifications for your daily plans',
      includeReminderActions: true,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: await canScheduleExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: _buildPayload(
        originalId: id,
        title: title,
        body: body,
        planId: planIdentifier,
        opensInput: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(
    int day,
    int hour,
    int minute, {
    bool skipToday = false,
  }) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now) ||
        (skipToday &&
            scheduledDate.year == now.year &&
            scheduledDate.month == now.month &&
            scheduledDate.day == now.day)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  @override
  Future<void> cancelPlanReminders(int planId) async {
    final normalizedPlanId = _normalizePlanNotificationBaseId(planId);

    for (int i = 1; i <= 7; i++) {
      final notificationId = _buildPlanDayNotificationId(normalizedPlanId, i);
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      await flutterLocalNotificationsPlugin.cancel(
        _buildSnoozedNotificationId(notificationId),
      );
    }
  }

  /// Get list of all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Show an instant notification
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      _buildNotificationDetails(
        channelId: 'debug_notifications',
        channelName: 'Debug Notifications',
        channelDescription: 'Notifications for testing purposes',
      ),
      payload: _buildPayload(originalId: id, title: title, body: body),
    );
  }

  Future<void> showRemoteMessageNotification(RemoteMessage message) async {
    await _ensureInitializedForActionHandling();

    final title =
        message.data['title'] ?? message.notification?.title ?? '새 알림';
    final body = message.data['body'] ?? message.notification?.body ?? '';
    final notificationId = _notificationIdForRemoteMessage(message);
    final planId = message.data['planId'];
    final opensInput = _remoteMessageOpensInput(message);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      _buildNotificationDetails(
        channelId: 'general_notifications',
        channelName: 'General Notifications',
        channelDescription:
            'Notifications for cheer messages and partner actions',
        includeReminderActions: opensInput,
      ),
      payload: _buildPayload(
        originalId: notificationId,
        title: title,
        body: body,
        planId: planId,
        opensInput: opensInput,
      ),
    );
  }

  /// 특정 시각에 알람 예약 (범용)
  Future<void> scheduleNotificationAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? planId,
    bool opensInput = false,
  }) async {
    final notificationDetails = _buildNotificationDetails(
      channelId: 'scheduled_notifications',
      channelName: 'Scheduled Notifications',
      channelDescription: 'Specific time notifications',
      includeReminderActions: opensInput,
    );
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    debugPrint(
      '[Notification] Scheduling at specific time: $tzScheduledDate (ID: $id)',
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: await canScheduleExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _buildPayload(
        originalId: id,
        title: title,
        body: body,
        planId: planId,
        opensInput: opensInput,
      ),
    );
  }

  /// Test alarm: set one in X seconds (Internal use/Legacy support)
  Future<void> setTestAlarm({
    required int id,
    required String title,
    required String body,
    required int secondsFromNow,
  }) async {
    final scheduledDate = DateTime.now().add(Duration(seconds: secondsFromNow));
    await scheduleNotificationAt(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    await _ensureInitializedForActionHandling();

    final payload = _parsePayload(response.payload);
    if (response.actionId == _didItActionId ||
        (response.actionId == null &&
            _payloadOpensInputOnNotificationTap(payload))) {
      _emitInputRequest(
        NotificationInputRequest(
          planId: payload['planId'] as String?,
          title: payload['title'] as String?,
        ),
      );
      return;
    }

    if (response.actionId == _skipTodayActionId) {
      _emitSkipRequest(
        NotificationSkipRequest(
          planId: payload['planId'] as String?,
          title: payload['title'] as String?,
        ),
      );
      return;
    }

    if (response.actionId != _snoozeActionId) {
      return;
    }

    final title = payload['title'] as String?;
    final body = payload['body'] as String?;
    final originalId = payload['originalId'] as int?;
    if (title == null || body == null || originalId == null) {
      debugPrint(
        '[Notification] Missing snooze payload. actionId=${response.actionId}',
      );
      return;
    }

    final snoozedId = _buildSnoozedNotificationId(originalId);
    final scheduledDate = DateTime.now().add(const Duration(minutes: 10));

    debugPrint(
      '[Notification] Snoozing notification $originalId until $scheduledDate with new ID $snoozedId',
    );

    await scheduleNotificationAt(
      id: snoozedId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      planId: payload['planId'] as String?,
      opensInput: _payloadOpensInput(payload),
    );
  }

  void _emitInputRequest(NotificationInputRequest request) {
    if (_inputRequestController.hasListener) {
      _inputRequestController.add(request);
      return;
    }

    _pendingInputRequest = request;
  }

  void _emitSkipRequest(NotificationSkipRequest request) {
    if (_skipRequestController.hasListener) {
      _skipRequestController.add(request);
      return;
    }

    _pendingSkipRequest = request;
  }

  Future<void> _ensureInitializedForActionHandling() async {
    if (!_isInitialized) {
      await init();
    }
  }

  NotificationDetails _buildNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    bool includeReminderActions = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        actions: includeReminderActions
            ? const <AndroidNotificationAction>[
                AndroidNotificationAction(
                  _didItActionId,
                  '했어',
                  showsUserInterface: true,
                ),
                AndroidNotificationAction(
                  _skipTodayActionId,
                  '오늘은 패스',
                  showsUserInterface: true,
                ),
                AndroidNotificationAction(_snoozeActionId, '10분 후 다시 묻기'),
              ]
            : null,
      ),
      iOS: includeReminderActions
          ? const DarwinNotificationDetails(
              categoryIdentifier: _snoozeDarwinCategoryId,
            )
          : null,
    );
  }

  String _buildPayload({
    required int originalId,
    required String title,
    required String body,
    String? planId,
    bool opensInput = false,
  }) {
    return jsonEncode(<String, Object?>{
      'originalId': originalId,
      'title': title,
      'body': body,
      if (planId != null && planId.isNotEmpty) 'planId': planId,
      'opensInput': opensInput,
    });
  }

  Map<String, Object?> _parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return const <String, Object?>{};
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (error) {
      debugPrint('[Notification] Failed to parse payload: $error');
    }

    return const <String, Object?>{};
  }

  int _buildSnoozedNotificationId(int originalId) {
    final normalizedId = originalId.abs() % 1000000000;
    return 1000000000 + normalizedId;
  }

  int _normalizePlanNotificationBaseId(int planId) {
    return planId.abs() % _planNotificationIdModulo;
  }

  int _buildPlanDayNotificationId(int normalizedPlanId, int day) {
    return normalizedPlanId * 10 + day;
  }

  int _notificationIdForRemoteMessage(RemoteMessage message) {
    final source =
        message.messageId ??
        '${message.data['type'] ?? ''}:${message.data['planId'] ?? ''}:${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
    return source.hashCode & 0x7fffffff;
  }

  bool _remoteMessageOpensInput(RemoteMessage message) {
    final type = message.data['type'];
    final planId = message.data['planId'];
    return type == 'poke' && planId != null && planId.isNotEmpty;
  }

  bool _payloadOpensInputOnNotificationTap(Map<String, Object?> payload) {
    return _payloadOpensInput(payload) && payload['planId'] is String;
  }

  bool _payloadOpensInput(Map<String, Object?> payload) {
    return payload['opensInput'] == true;
  }
}
