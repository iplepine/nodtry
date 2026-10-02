import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/application/reminder_copy_refresh.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/services/notification_service.dart';
import 'package:nod_try/utils/context_free_l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Records extends Fake implements RecordRepository {
  _Records(this.plans);

  List<Plan> plans;
  int reads = 0;
  Object? failWith;

  @override
  Future<List<Plan>> getPlansByUserId(String userId) async {
    reads++;
    if (failWith != null) throw failWith!;
    return plans;
  }
}

class _Scheduler implements PlanReminderScheduler {
  final scheduled =
      <({String? plan, String title, String? body, bool skipToday})>[];

  @override
  Future<void> cancelPlanReminders(int planId) async {}

  @override
  Future<void> requestPermissions() async {}

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
    scheduled.add((
      plan: planIdentifier,
      title: title,
      body: body,
      skipToday: skipToday,
    ));
  }
}

final _now = DateTime(2026, 10, 3, 9);

Plan _plan(
  String id, {
  PlanState state = PlanState.active,
  List<DateTime> completed = const [],
  String? managerId = 'partner',
}) {
  return Plan(
    id: id,
    userId: 'me',
    managerId: managerId,
    startDate: DateTime(2026, 9, 28),
    endDate: DateTime(2026, 10, 25, 23, 59, 59),
    state: state,
    workoutType: 'gym',
    items: [
      PlanItem(
        title: '헬스장 가기',
        days: const [1, 3, 5, 6],
        count: 4,
        notificationTime: NotificationTime.custom(21, 0),
      ),
    ],
    createdAt: DateTime(2026, 9, 28),
    completedDates: completed,
  );
}

void main() {
  late SharedPreferences prefs;
  late _Scheduler scheduler;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    scheduler = _Scheduler();
    setContextFreeLocaleCode('ko');
  });

  tearDown(() => setContextFreeLocaleCode(null));

  ReminderCopyRefresher refresher(_Records records) => ReminderCopyRefresher(
    prefs: prefs,
    records: records,
    alarms: SettingAlarmUseCase(scheduler, partnerLabelFor: (_) => '자기'),
    clock: () => _now,
  );

  test('shouldRefreshReminderCopy: only before the pivot build', () {
    expect(kReminderCopyVersion, 81);
    expect(shouldRefreshReminderCopy(null), isTrue);
    expect(shouldRefreshReminderCopy(80), isTrue);
    expect(shouldRefreshReminderCopy(81), isFalse);
    expect(shouldRefreshReminderCopy(90), isFalse);
  });

  test('reschedules every running plan once, with the new copy', () async {
    final records = _Records([
      _plan('a'),
      _plan('b', managerId: null),
      _plan('pending', state: PlanState.pendingApproval),
    ]);

    expect(await refresher(records).runIfNeeded('me'), isTrue);

    expect(scheduler.scheduled.map((s) => s.plan), ['a', 'b']);
    expect(scheduler.scheduled.first.title, '오늘 🏋️ 헬스 했어?');
    expect(scheduler.scheduled.first.body, '기록이 없으면 곧 자기한테 알려져요');
    expect(scheduler.scheduled.last.body, isNull); // solo: default text
    expect(prefs.getInt(kReminderCopyVersionKey), kReminderCopyVersion);
  });

  test('runs only once', () async {
    final records = _Records([_plan('a')]);
    await refresher(records).runIfNeeded('me');
    scheduler.scheduled.clear();

    expect(await refresher(records).runIfNeeded('me'), isFalse);
    expect(scheduler.scheduled, isEmpty);
    expect(records.reads, 1);
  });

  test('a plan already recorded today keeps today silent', () async {
    final records = _Records([
      _plan('done', completed: [DateTime(2026, 10, 3, 8)]),
      _plan('open'),
    ]);
    await refresher(records).runIfNeeded('me');
    expect(
      {for (final s in scheduler.scheduled) s.plan: s.skipToday},
      {'done': true, 'open': false},
    );
  });

  test('an older flag is refreshed again', () async {
    await prefs.setInt(kReminderCopyVersionKey, 80);
    expect(await refresher(_Records([_plan('a')])).runIfNeeded('me'), isTrue);
    expect(prefs.getInt(kReminderCopyVersionKey), 81);
  });

  test('a failed or empty read is retried next time', () async {
    final failing = _Records([_plan('a')])..failWith = Exception('offline');
    expect(await refresher(failing).runIfNeeded('me'), isFalse);
    expect(prefs.getInt(kReminderCopyVersionKey), isNull);

    expect(await refresher(_Records([])).runIfNeeded('me'), isFalse);
    expect(prefs.getInt(kReminderCopyVersionKey), isNull);

    expect(await refresher(_Records([_plan('a')])).runIfNeeded('me'), isTrue);
    expect(prefs.getInt(kReminderCopyVersionKey), 81);
  });
}
