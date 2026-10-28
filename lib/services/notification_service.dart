import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';

import '../utils/analytics.dart';
import '../utils/context_free_l10n.dart';
import 'notification_quick_actions.dart';

/// Notification system strings, resolved from the ARB copy.
/// Why: NotificationService runs outside the widget tree (incl. background
/// isolates), so we can't reach AppLocalizations through BuildContext here.
/// [contextFreeL10n] follows the Settings language when the app has reported
/// it, and the device language otherwise (e.g. in a background isolate).
String _notifString(String key) {
  final l10n = contextFreeL10n();
  switch (key) {
    case 'actionDidIt':
      return l10n.notifActionDidIt;
    case 'actionSkipToday':
      return l10n.notifActionSkipToday;
    case 'actionSnooze':
      return l10n.notifActionSnooze;
    case 'actionProps':
      return l10n.notifActionProps;
    case 'actionCheer':
      return l10n.notifActionCheer;
    case 'actionPokeComing':
      return l10n.nowPokeReplyComing;
    case 'actionPokePass':
      return l10n.nowPokeReplyPass;
    case 'reminderBody':
      return l10n.notifReminderBody;
    case 'fallbackTitle':
      return l10n.notifFallbackTitle;
    case 'channelRemindersName':
      return l10n.notifChannelRemindersName;
    case 'channelRemindersDesc':
      return l10n.notifChannelRemindersDesc;
    case 'channelGeneralName':
      return l10n.notifChannelGeneralName;
    case 'channelGeneralDesc':
      return l10n.notifChannelGeneralDesc;
    case 'channelScheduledName':
      return l10n.notifChannelScheduledName;
    case 'channelScheduledDesc':
      return l10n.notifChannelScheduledDesc;
    case 'channelDebugName':
      return l10n.notifChannelDebugName;
    case 'channelDebugDesc':
      return l10n.notifChannelDebugDesc;
    default:
      return key;
  }
}

/// Android status-bar icon: the monochrome 둘운완 mark from the brand lane
/// (android/app/src/main/res/drawable-*/ic_stat_duodone.png, also FCM's
/// default_notification_icon in AndroidManifest.xml).
const String kAndroidNotificationSmallIcon = '@drawable/ic_stat_duodone';

const String _snoozeActionId = 'snooze_10m';
const String _didItActionId = 'did_it_now';
const String _skipTodayActionId = 'skip_today';
const String _snoozeDarwinCategoryId = 'snooze_reminder';

// Plan-reminder ID layout
// ----------------------
// matchDateTimeComponents:dayOfWeekAndTime ignores the date portion of the
// scheduledDate on both iOS (UNCalendarNotificationTrigger only uses the
// extracted components) and Android (next-fire-date is rebuilt from "now").
// That made skipToday a no-op — today's instance still fired. We now schedule
// one-shot zonedSchedule entries for the next N weeks per day, so cancelling
// or re-scheduling can actually drop today's instance.
const int _planNotificationIdModulo = 10000000;
const int _planNotificationWeeksAhead = 4;
const int _planNotificationSlotsPerPlan = 100; // (day-1)*10 + week
const int _planNotificationSnoozeOffset = 1500000000;
const int _planNotificationSnoozeModulo = 200000000;

// Hourly-reminder ID layout
// -------------------------
// Weekly reminders occupy [0, ~1e9) (planId<1e7 * 100 + slot<100) and snooze
// lives at 1.5e9+, so [1e9, 1.5e9) is free for hourly reminders. An hourly
// plan fans out into many instances, so we schedule a bounded, contiguous
// block of the next N upcoming fires per plan and refill on every app launch
// (auto-login re-registers all reminders). N is capped to stay well under the
// iOS 64-pending-notification ceiling. Block layout:
//   _hourlyReminderBaseOffset + (planId % _hourlyPlanSlotModulo) * _maxHourlyRemindersPerPlan + index
// _hourlyPlanSlotModulo * _maxHourlyRemindersPerPlan (= 3e8) keeps every id
// inside [1e9, 1.3e9).
const int _hourlyReminderBaseOffset = 1000000000;
const int _maxHourlyRemindersPerPlan = 48;
const int _hourlyPlanSlotModulo = 5000000;
// How far ahead to look for the next hourly fires. The block cap usually bites
// first; this simply bounds the search for sparse day selections.
const int _hourlyReminderHorizonDays = 14;
// Legacy values kept so we can still cancel reminders scheduled by previous
// versions that used a different id layout.
const int _legacyPlanNotificationIdModulo = 200000000;
const int _legacySnoozeOffset = 1000000000;
const int _legacySnoozeModulo = 1000000000;

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

/// A notification the user opened (tapped its body): a partner push, by its
/// `data.type`, or a plan reminder ([reminderType]). Routed by the home
/// screen to the screen it is about.
@immutable
class NotificationOpenRequest {
  const NotificationOpenRequest({
    required this.type,
    this.planId,
    this.actionId,
    this.reason,
    this.actionDate,
    this.quickAction,
  });

  /// `type` of a local plan reminder (and of a snoozed / deferred one).
  static const String reminderType = 'reminder';

  /// A push's `data.type` (e.g. `poke`, `partner_connected`) or
  /// [reminderType].
  final String type;
  final String? planId;
  final String? actionId;

  /// `data.reason` of `partner_connect_failed` (owner_taken | self_taken |
  /// invalid_code).
  final String? reason;

  /// The day of the record the push is about (`data.actionDate`, epoch
  /// millis): a record of an earlier day is on the 기록 tab, not on today's
  /// cards. Null from servers that don't send it.
  final DateTime? actionDate;

  /// The button the push was answered with, or null for a body tap.
  final NotificationQuickAction? quickAction;

  /// The request for a push's `data` (or a shown push's payload), or null
  /// without a type. [actionId] is the tapped button's id, if any.
  static NotificationOpenRequest? fromData(
    Map<String, dynamic> data, {
    String? actionId,
  }) {
    String? str(Object? v) => v is String && v.isNotEmpty ? v : null;
    final type = str(data['type']);
    if (type == null) return null;
    return NotificationOpenRequest(
      type: type,
      planId: str(data['planId']),
      actionId: str(data['actionId']),
      reason: str(data['reason']),
      actionDate: _dateFromMillis(data['actionDate']),
      quickAction: NotificationQuickAction.fromId(actionId),
    );
  }

  static DateTime? _dateFromMillis(Object? value) {
    final millis = value is num
        ? value.toInt()
        : int.tryParse('${value ?? ''}');
    if (millis == null || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  String toString() =>
      'NotificationOpenRequest($type, plan: $planId, action: $quickAction)';
}

abstract class PlanReminderScheduler {
  Future<void> requestPermissions();

  /// [body] null means the default reminder text (`notifReminderBody`).
  Future<void> schedulePlanReminder({
    required int planId,
    String? planIdentifier,
    required String title,
    String? body,
    required int hour,
    required int minute,
    required List<int> days,
    bool skipToday,
    int intervalHours,
    int startHour,
    int endHour,
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
  final StreamController<NotificationOpenRequest> _openRequestController =
      StreamController<NotificationOpenRequest>.broadcast();

  bool _isInitialized = false;
  NotificationInputRequest? _pendingInputRequest;
  NotificationSkipRequest? _pendingSkipRequest;
  NotificationOpenRequest? _pendingOpenRequest;

  Stream<NotificationInputRequest> get inputRequests =>
      _inputRequestController.stream;
  Stream<NotificationSkipRequest> get skipRequests =>
      _skipRequestController.stream;

  /// Opened notifications (body taps), for the home screen to route.
  Stream<NotificationOpenRequest> get openRequests =>
      _openRequestController.stream;

  NotificationOpenRequest? takePendingOpenRequest() {
    final request = _pendingOpenRequest;
    _pendingOpenRequest = null;
    return request;
  }

  /// A push opened from the background or a cold start
  /// (`onMessageOpenedApp` / `getInitialMessage`): routed like a tap on the
  /// same push shown in the foreground. [actionIdentifier] is the button it
  /// was answered with (iOS; null or the default action for a body tap).
  void emitPushOpen(Map<String, dynamic> data, {String? actionIdentifier}) {
    final request = NotificationOpenRequest.fromData(
      data,
      actionId: actionIdentifier,
    );
    if (request != null) _emitOpenRequest(request);
  }

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

    await _configureLocalTimezone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(kAndroidNotificationSmallIcon);

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
                  _notifString('actionDidIt'),
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
                DarwinNotificationAction.plain(
                  _skipTodayActionId,
                  _notifString('actionSkipToday'),
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
                DarwinNotificationAction.plain(
                  _snoozeActionId,
                  _notifString('actionSnooze'),
                ),
              ],
            ),
            // Partner pushes: the server sets these as `aps.category`.
            for (final MapEntry(key: category, value: actions)
                in kQuickActionCategories.entries)
              DarwinNotificationCategory(
                category,
                actions: <DarwinNotificationAction>[
                  for (final action in actions)
                    DarwinNotificationAction.plain(
                      action.id,
                      _quickActionLabel(action),
                      options: <DarwinNotificationActionOption>{
                        DarwinNotificationActionOption.foreground,
                      },
                    ),
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

  Future<void> _configureLocalTimezone() async {
    String? rawIdentifier;
    try {
      tz.initializeTimeZones(); // Ensure timezones are loaded first.
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      rawIdentifier = timezoneInfo.identifier;
      final location = _locationForTimezoneIdentifier(rawIdentifier);
      tz.setLocalLocation(location);
      debugPrint(
        'NotificationService initialized with timezone: ${location.name}',
      );
    } catch (error) {
      // Some Android devices report aliases such as Etc/UTC or vendor-specific
      // IDs that the embedded TZ database may not resolve. Local reminders
      // should degrade to UTC instead of crashing app startup.
      tz.setLocalLocation(tz.UTC);
      debugPrint(
        '[Notification] Timezone "$rawIdentifier" unavailable; using UTC. $error',
      );
    }
  }

  tz.Location _locationForTimezoneIdentifier(String identifier) {
    final normalized = _canonicalTimezoneIdentifier(identifier);
    try {
      return tz.getLocation(normalized);
    } catch (error) {
      debugPrint(
        '[Notification] Unknown timezone "$identifier" normalized to "$normalized": $error',
      );
      return tz.UTC;
    }
  }

  String _canonicalTimezoneIdentifier(String identifier) {
    switch (identifier.trim()) {
      case '':
      case 'Etc/UTC':
      case 'Etc/UCT':
      case 'Etc/GMT':
      case 'GMT':
      case 'UCT':
      case 'Universal':
      case 'Zulu':
        return 'UTC';
      default:
        return identifier.trim();
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
  /// [planId] should be unique per plan (hash-derived)
  /// [days] 1=Mon, 7=Sun (compatible with DateTime.weekday)
  /// [skipToday] if true and an instance falls on today, that single instance
  /// is dropped while next week's and later remain scheduled.
  @override
  Future<void> schedulePlanReminder({
    required int planId,
    String? planIdentifier,
    required String title,
    String? body,
    required int hour,
    required int minute,
    required List<int> days,
    bool skipToday = false,
    int intervalHours = 0,
    int startHour = 0,
    int endHour = 0,
  }) async {
    final normalizedPlanId = _normalizePlanNotificationBaseId(planId);
    final reminderBody = body ?? _notifString('reminderBody');

    await cancelPlanReminders(planId);

    if (intervalHours >= 1) {
      await _scheduleHourlyPlanReminders(
        normalizedPlanId: normalizedPlanId,
        planIdentifier: planIdentifier,
        title: title,
        body: reminderBody,
        minute: minute,
        days: days,
        intervalHours: intervalHours,
        startHour: startHour,
        endHour: endHour,
        skipToday: skipToday,
      );
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (final int day in days) {
      final tz.TZDateTime firstInstance = _firstInstanceOfDayAndTime(
        now,
        day,
        hour,
        minute,
      );
      for (int week = 0; week < _planNotificationWeeksAhead; week++) {
        final tz.TZDateTime scheduledDate = firstInstance.add(
          Duration(days: 7 * week),
        );
        if (scheduledDate.isBefore(now)) continue;
        if (skipToday && _isSameLocalDay(scheduledDate, now)) continue;

        final int id = _buildPlanDayWeekNotificationId(
          normalizedPlanId,
          day,
          week,
        );
        debugPrint(
          '[Notification] Scheduling plan=$planId day=$day week=$week at $scheduledDate (id=$id)',
        );
        await _scheduleSinglePlanReminder(
          id: id,
          title: title,
          body: reminderBody,
          scheduledDate: scheduledDate,
          planIdentifier: planIdentifier,
        );
      }
    }
  }

  /// Schedule the next [_maxHourlyRemindersPerPlan] upcoming fires for a plan
  /// that repeats every [intervalHours] hours between [startHour] and [endHour]
  /// on the selected [days]. The remaining fires are refilled the next time the
  /// app re-registers reminders (auto-login on launch).
  Future<void> _scheduleHourlyPlanReminders({
    required int normalizedPlanId,
    String? planIdentifier,
    required String title,
    required String body,
    required int minute,
    required List<int> days,
    required int intervalHours,
    required int startHour,
    required int endHour,
    required bool skipToday,
  }) async {
    if (days.isEmpty) return;

    final step = intervalHours < 1 ? 1 : intervalHours;
    final start = startHour.clamp(0, 23);
    final end = endHour.clamp(0, 23);
    if (end < start) return;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final daySet = days.toSet();

    final List<tz.TZDateTime> instances = [];
    for (
      int dayOffset = 0;
      dayOffset <= _hourlyReminderHorizonDays &&
          instances.length < _maxHourlyRemindersPerPlan;
      dayOffset++
    ) {
      final tz.TZDateTime base = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: dayOffset));
      if (!daySet.contains(base.weekday)) continue;
      if (skipToday && _isSameLocalDay(base, now)) continue;

      for (int h = start; h <= end; h += step) {
        final tz.TZDateTime fire = tz.TZDateTime(
          tz.local,
          base.year,
          base.month,
          base.day,
          h,
          minute,
        );
        if (fire.isBefore(now)) continue;
        instances.add(fire);
        if (instances.length >= _maxHourlyRemindersPerPlan) break;
      }
    }

    for (int index = 0; index < instances.length; index++) {
      final int id = _buildHourlyReminderId(normalizedPlanId, index);
      debugPrint(
        '[Notification] Scheduling hourly plan=$normalizedPlanId #$index at ${instances[index]} (id=$id)',
      );
      await _scheduleSinglePlanReminder(
        id: id,
        title: title,
        body: body,
        scheduledDate: instances[index],
        planIdentifier: planIdentifier,
      );
    }
  }

  Future<void> _scheduleSinglePlanReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? planIdentifier,
  }) async {
    final notificationDetails = _buildNotificationDetails(
      channelId: 'plan_reminders',
      channelName: _notifString('channelRemindersName'),
      channelDescription: _notifString('channelRemindersDesc'),
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
      payload: _buildPayload(
        originalId: id,
        title: title,
        body: body,
        planId: planIdentifier,
        opensInput: true,
      ),
    );
  }

  tz.TZDateTime _firstInstanceOfDayAndTime(
    tz.TZDateTime now,
    int day,
    int hour,
    int minute,
  ) {
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
    return scheduledDate;
  }

  bool _isSameLocalDay(tz.TZDateTime a, tz.TZDateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Future<void> cancelPlanReminders(int planId) async {
    final normalizedPlanId = _normalizePlanNotificationBaseId(planId);

    for (int day = 1; day <= 7; day++) {
      for (int week = 0; week < _planNotificationWeeksAhead; week++) {
        final int id = _buildPlanDayWeekNotificationId(
          normalizedPlanId,
          day,
          week,
        );
        await flutterLocalNotificationsPlugin.cancel(id);
        await flutterLocalNotificationsPlugin.cancel(
          _buildSnoozedNotificationId(id),
        );
      }
    }

    // Also clear the hourly-reminder block for this plan. We don't know here
    // whether the plan is hourly, so cancel the whole block unconditionally —
    // the id region is disjoint from the weekly grid, so this is safe.
    for (int index = 0; index < _maxHourlyRemindersPerPlan; index++) {
      final int id = _buildHourlyReminderId(normalizedPlanId, index);
      await flutterLocalNotificationsPlugin.cancel(id);
      await flutterLocalNotificationsPlugin.cancel(
        _buildSnoozedNotificationId(id),
      );
    }

    // Best-effort cleanup of any reminders left over from the previous id
    // layout. Same plan seed but a different modulo, so the legacy id won't
    // collide with the new one — safe to cancel unconditionally.
    final int legacyPlanId = planId.abs() % _legacyPlanNotificationIdModulo;
    for (int day = 1; day <= 7; day++) {
      final int legacyId = legacyPlanId * 10 + day;
      await flutterLocalNotificationsPlugin.cancel(legacyId);
      await flutterLocalNotificationsPlugin.cancel(
        _buildLegacySnoozedNotificationId(legacyId),
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
        channelName: _notifString('channelDebugName'),
        channelDescription: _notifString('channelDebugDesc'),
      ),
      payload: _buildPayload(originalId: id, title: title, body: body),
    );
  }

  Future<void> showRemoteMessageNotification(RemoteMessage message) async {
    await _ensureInitializedForActionHandling();

    final title =
        message.data['title'] ??
        message.notification?.title ??
        _notifString('fallbackTitle');
    final body = message.data['body'] ?? message.notification?.body ?? '';
    final notificationId = _notificationIdForRemoteMessage(message);
    final planId = message.data['planId'];
    final opensInput = _remoteMessageOpensInput(message);
    final category = message.data['category']?.toString();

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      _buildNotificationDetails(
        channelId: 'general_notifications',
        channelName: _notifString('channelGeneralName'),
        channelDescription: _notifString('channelGeneralDesc'),
        // A knock is answered with its reply buttons, not the reminder's.
        includeReminderActions:
            opensInput && quickActionsForCategory(category).isEmpty,
        quickActionCategory: category,
      ),
      payload: _buildPayload(
        originalId: notificationId,
        title: title,
        body: body,
        planId: planId,
        opensInput: opensInput,
        type: message.data['type']?.toString(),
        actionId: message.data['actionId']?.toString(),
        reason: message.data['reason']?.toString(),
        actionDate: message.data['actionDate']?.toString(),
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
      channelName: _notifString('channelScheduledName'),
      channelDescription: _notifString('channelScheduledDesc'),
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
    final quickAction = NotificationQuickAction.fromId(response.actionId);
    // A partner push this app drew itself (foreground, or data-only on
    // Android): logged like one the OS drew (see core NotificationService).
    final pushType = payload['type'];
    if (pushType is String &&
        pushType != NotificationOpenRequest.reminderType &&
        (response.actionId == null || quickAction != null)) {
      AnalyticsService.log(AnalyticsEvent.notificationOpened, {
        'type': pushType,
        'action': quickAction?.analyticsId ?? 'none',
      });
    }

    // A partner push's button: open the app on that card and act there.
    if (quickAction != null) {
      final request = NotificationOpenRequest.fromData(
        payload,
        actionId: response.actionId,
      );
      if (request != null) _emitOpenRequest(request);
      return;
    }

    // The explicit 했어 action: the quick note-only record.
    if (response.actionId == _didItActionId) {
      _emitInputRequest(
        NotificationInputRequest(
          planId: payload['planId'] as String?,
          title: payload['title'] as String?,
        ),
      );
      return;
    }

    // A body tap opens the screen the notification is about: a partner push
    // by its type; a plan reminder focuses that promise on the Now tab with
    // the check-in choices (📸 인증샷 찍기 first) instead of a note dialog.
    if (response.actionId == null) {
      final pushRequest = NotificationOpenRequest.fromData(payload);
      if (pushRequest != null) {
        _emitOpenRequest(pushRequest);
        return;
      }
      if (_payloadOpensInputOnNotificationTap(payload)) {
        _emitOpenRequest(
          NotificationOpenRequest(
            type: NotificationOpenRequest.reminderType,
            planId: payload['planId'] as String?,
          ),
        );
        return;
      }
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

  void _emitOpenRequest(NotificationOpenRequest request) {
    if (_openRequestController.hasListener) {
      _openRequestController.add(request);
      return;
    }

    _pendingOpenRequest = request;
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
    String? quickActionCategory,
  }) {
    final quickActions = quickActionsForCategory(quickActionCategory);
    if (quickActions.isNotEmpty) {
      return NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            for (final action in quickActions)
              AndroidNotificationAction(
                action.id,
                _quickActionLabel(action),
                showsUserInterface: true,
              ),
          ],
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: quickActionCategory),
      );
    }
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        actions: includeReminderActions
            ? <AndroidNotificationAction>[
                AndroidNotificationAction(
                  _didItActionId,
                  _notifString('actionDidIt'),
                  showsUserInterface: true,
                ),
                AndroidNotificationAction(
                  _skipTodayActionId,
                  _notifString('actionSkipToday'),
                  showsUserInterface: true,
                ),
                AndroidNotificationAction(
                  _snoozeActionId,
                  _notifString('actionSnooze'),
                ),
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
    String? type,
    String? actionId,
    String? reason,
    String? actionDate,
  }) {
    return jsonEncode(<String, Object?>{
      'originalId': originalId,
      'title': title,
      'body': body,
      if (planId != null && planId.isNotEmpty) 'planId': planId,
      'opensInput': opensInput,
      if (type != null && type.isNotEmpty) 'type': type,
      if (actionId != null && actionId.isNotEmpty) 'actionId': actionId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (actionDate != null && actionDate.isNotEmpty) 'actionDate': actionDate,
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
    final normalizedId = originalId.abs() % _planNotificationSnoozeModulo;
    return _planNotificationSnoozeOffset + normalizedId;
  }

  int _buildLegacySnoozedNotificationId(int originalId) {
    final normalizedId = originalId.abs() % _legacySnoozeModulo;
    return _legacySnoozeOffset + normalizedId;
  }

  int _normalizePlanNotificationBaseId(int planId) {
    return planId.abs() % _planNotificationIdModulo;
  }

  int _buildPlanDayWeekNotificationId(
    int normalizedPlanId,
    int day, // 1..7
    int week, // 0..(_planNotificationWeeksAhead - 1)
  ) {
    return normalizedPlanId * _planNotificationSlotsPerPlan +
        (day - 1) * 10 +
        week;
  }

  int _buildHourlyReminderId(
    int normalizedPlanId,
    int index, // 0..(_maxHourlyRemindersPerPlan - 1)
  ) {
    return _hourlyReminderBaseOffset +
        (normalizedPlanId % _hourlyPlanSlotModulo) *
            _maxHourlyRemindersPerPlan +
        index;
  }

  int _notificationIdForRemoteMessage(RemoteMessage message) {
    final source =
        message.messageId ??
        '${message.data['type'] ?? ''}:${message.data['planId'] ?? ''}:${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
    return source.hashCode & 0x7fffffff;
  }

  String _quickActionLabel(NotificationQuickAction action) => switch (action) {
    NotificationQuickAction.props => _notifString('actionProps'),
    NotificationQuickAction.pokeComing => _notifString('actionPokeComing'),
    NotificationQuickAction.pokePass => _notifString('actionPokePass'),
    NotificationQuickAction.cheer => _notifString('actionCheer'),
  };

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
