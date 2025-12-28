import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

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
  }

  /// Schedule a notification for a plan
  /// [id] should be unique per plan-day combination or plan ID base
  /// [days] 1=Mon, 7=Sun (compatible with DateTime.weekday)
  Future<void> schedulePlanReminder({
    required int planId, // Using plan.hashCode or similar as base
    required String title,
    required int hour,
    required int minute,
    required List<int> days,
  }) async {
    // Cancel existing notifications for this plan (simple strategy: cancel all range)
    // Use modulo to prevent integer overflow (32-bit limit for Notification ID)
    // Max Int32 is ~2.14 billion.
    // 200,000,000 * 10 = 2,000,000,000 (Safe)
    // 200 million seconds is approx 6.3 years.

    for (int day in days) {
      // 0-based index for logic if needed, but TZ uses weekday
      await _scheduleWeekly(
        id: (planId % 200000000) * 10 + day,
        title: title,
        body: "오늘 약속, 같이 이어갈까요?", // Warm Accountability Copy
        hour: hour,
        minute: minute,
        day: day,
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
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDayAndTime(day, hour, minute),
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation:
      //     UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
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

    if (scheduledDate.isBefore(now)) {
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
}
