import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
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
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

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
  Future<void> schedulePlanReminder({
    required int planId, // Using plan.hashCode or similar as base
    required String title,
    required int hour,
    required int minute,
    required List<int> days,
    bool skipToday = false,
  }) async {
    // Cancel existing notifications for this plan (simple strategy: cancel all range)
    // Use modulo to prevent integer overflow (32-bit limit for Notification ID)
    // Max Int32 is ~2.14 billion.
    // 200,000,000 * 10 = 2,000,000,000 (Safe)
    // 200 million seconds is approx 6.3 years.

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
        id: (planId % 200000000) * 10 + day,
        title: title,
        body: "오늘 약속, 같이 이어갈까요?", // Warm Accountability Copy
        hour: hour,
        minute: minute,
        day: day,
        scheduledDate: scheduledDate,
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
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'plan_reminders', // channel Id
          'Plan Reminders', // channel Name
          channelDescription: 'Notifications for your daily plans',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: await canScheduleExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
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

  Future<void> cancelPlanReminders(int planId) async {
    // Naively cancel a range, or store IDs.
    // For MVP, assuming max 7 days
    for (int i = 1; i <= 7; i++) {
      await flutterLocalNotificationsPlugin.cancel(
        (planId % 200000000) * 10 + i,
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
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'debug_notifications',
          'Debug Notifications',
          channelDescription: 'Notifications for testing purposes',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// 특정 시각에 알람 예약 (범용)
  Future<void> scheduleNotificationAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    debugPrint(
      '[Notification] Scheduling at specific time: $tzScheduledDate (ID: $id)',
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_notifications',
          'Scheduled Notifications',
          channelDescription: 'Specific time notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: await canScheduleExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
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
}
