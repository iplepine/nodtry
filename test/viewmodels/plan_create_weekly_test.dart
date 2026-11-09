import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/features/plan/presentation/plan_create_state.dart';
import 'package:nod_try/features/plan/presentation/viewmodel/plan_create_viewmodel.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/services/notification_service.dart';

class _Records extends Fake implements RecordRepository {
  Plan? createdPlan;
  Plan? updatedPlan;
  final clearedWeekly = <String>[];

  @override
  Future<String> createPlan(Plan plan) async {
    createdPlan = plan;
    return 'new-plan';
  }

  @override
  Future<void> updatePlan(Plan plan) async => updatedPlan = plan;

  @override
  Future<void> clearWeeklyTarget(String planId) async =>
      clearedWeekly.add(planId);

  @override
  Future<List<Plan>> getPlansByUserId(String userId) async => const [];

  @override
  Future<List<HomeCardModel>> getHomeCardStates() async => [];

  @override
  Stream<List<HomeCardModel>> getHomeCardStatesStream() => Stream.value([]);

  @override
  Future<List<HistoryItem>> getHistoryItems() async => [];

  @override
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds}) =>
      Stream.value([]);
}

class _Scheduler implements PlanReminderScheduler {
  List<int>? days;
  List<DateTime>? onlyDates;
  bool scheduled = false;

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
    List<DateTime>? onlyDates,
  }) async {
    scheduled = true;
    this.days = days;
    this.onlyDates = onlyDates;
  }
}

UserModel _user(String uid) => UserModel(
  uid: uid,
  createdAt: DateTime(2026, 5, 3),
  updatedAt: DateTime(2026, 5, 3),
);

ProviderContainer _container(_Records records, _Scheduler scheduler) {
  return ProviderContainer(
    overrides: [
      recordRepositoryProvider.overrideWithValue(records),
      settingAlarmUseCaseProvider.overrideWithValue(
        SettingAlarmUseCase(scheduler),
      ),
      myProfileProvider.overrideWithValue(AsyncData(_user('user-1'))),
      connectedProfilesProvider.overrideWith(
        (ref) async => [
          ConnectedUser(
            user: _user('partner-1'),
            isSupported: true,
            isCheering: true,
          ),
        ],
      ),
    ],
  );
}

Plan _plan({int? weeklyTarget, List<int> days = const [1, 3, 5]}) {
  final now = DateTime.now();
  final period = Plan.periodStartingOn(now);
  return Plan(
    id: 'plan-1',
    userId: 'user-1',
    managerId: 'partner-1',
    startDate: period.start,
    endDate: period.end,
    state: PlanState.active,
    items: [
      PlanItem(
        title: '러닝 30분',
        days: days,
        count: days.length,
        notificationTime: NotificationTime.custom(21, 0),
      ),
    ],
    createdAt: period.start,
    workoutType: 'running',
    weeklyTarget: weeklyTarget,
  );
}

void main() {
  group('주 N회 자유롭게', () {
    test('the toggle starts the stepper at the picked day count', () async {
      final container = _container(_Records(), _Scheduler());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final vm = container.read(planCreateViewModelProvider.notifier);

      await vm.dispatch(const UpdateActionIntent('러닝'));
      await vm.dispatch(const SetWeeklyModeIntent(true));
      var state = container.read(planCreateViewModelProvider).value!;
      expect(state.isWeekly, isTrue);
      expect(state.weeklyTarget, 3); // Mon/Wed/Fri by default

      // No weekday is needed in this mode.
      await vm.dispatch(const UpdateSelectedDaysIntent({}));
      state = container.read(planCreateViewModelProvider).value!;
      expect(state.missingField, isNull);

      // Back to fixed days: the target goes, the days need picking again.
      await vm.dispatch(const SetWeeklyModeIntent(false));
      state = container.read(planCreateViewModelProvider).value!;
      expect(state.weeklyTarget, isNull);
      expect(state.missingField, PlanCreateMissing.days);
    });

    test('the stepper stays within 1–6', () async {
      final container = _container(_Records(), _Scheduler());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final vm = container.read(planCreateViewModelProvider.notifier);

      // Ignored outside weekly mode.
      await vm.dispatch(const UpdateWeeklyTargetIntent(5));
      expect(
        container.read(planCreateViewModelProvider).value!.weeklyTarget,
        isNull,
      );

      await vm.dispatch(const SetWeeklyModeIntent(true));
      await vm.dispatch(const UpdateWeeklyTargetIntent(9));
      expect(
        container.read(planCreateViewModelProvider).value!.weeklyTarget,
        6,
      );
      await vm.dispatch(const UpdateWeeklyTargetIntent(0));
      expect(
        container.read(planCreateViewModelProvider).value!.weeklyTarget,
        1,
      );
    });

    test('saves weeklyTarget with all seven weekdays and a deadline', () async {
      final records = _Records();
      final scheduler = _Scheduler();
      final container = _container(records, scheduler);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final vm = container.read(planCreateViewModelProvider.notifier);

      await vm.dispatch(const UpdateActionIntent('러닝 30분'));
      await vm.dispatch(const SetWeeklyModeIntent(true));
      await vm.dispatch(const UpdateWeeklyTargetIntent(4));
      await vm.dispatch(const SavePlanIntent());

      final plan = records.createdPlan!;
      expect(plan.weeklyTarget, 4);
      expect(plan.items.single.days, [1, 2, 3, 4, 5, 6, 7]);
      expect(plan.items.single.notificationTime!.type, isNot('none'));
      expect(plan.toMap()['weeklyTarget'], 4);
      // Reminders only on predicted must-do days, never every weekday.
      expect(scheduler.scheduled, isTrue);
      expect(scheduler.onlyDates, isNotNull);

      final params = planCreatedAnalyticsParams(
        container.read(planCreateViewModelProvider).value!,
        plan,
        isEdit: false,
      );
      expect(params['frequency'], 4);
      expect(params['schedule_mode'], 'weekly');
    });

    test('editing restores the mode and keeps the target', () async {
      final records = _Records();
      final container = _container(records, _Scheduler());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final vm = container.read(planCreateViewModelProvider.notifier);

      await vm.dispatch(
        InitializePlanIntent(
          _plan(weeklyTarget: 2, days: const [1, 2, 3, 4, 5, 6, 7]),
        ),
      );
      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.weeklyTarget, 2);
      // Switching to fixed days later starts from the usual default, not 매일.
      expect(state.selectedDays, {0, 2, 4});

      await vm.dispatch(const SavePlanIntent());
      expect(records.updatedPlan!.weeklyTarget, 2);
      expect(records.clearedWeekly, isEmpty);
    });

    test(
      'switching an edited weekly plan to fixed days deletes the field',
      () async {
        final records = _Records();
        final container = _container(records, _Scheduler());
        addTearDown(container.dispose);
        await container.read(planCreateViewModelProvider.future);
        await container.read(myProfileProvider.future);
        final vm = container.read(planCreateViewModelProvider.notifier);

        await vm.dispatch(
          InitializePlanIntent(
            _plan(weeklyTarget: 3, days: const [1, 2, 3, 4, 5, 6, 7]),
          ),
        );
        await vm.dispatch(const SetWeeklyModeIntent(false));
        await vm.dispatch(const SavePlanIntent());

        expect(records.updatedPlan!.weeklyTarget, isNull);
        expect(records.updatedPlan!.items.single.days, [1, 3, 5]);
        expect(records.clearedWeekly, ['plan-1']);
      },
    );

    test('a partner weekly plan is not offered as fixed weekdays', () {
      expect(
        PlanCreateViewModel.partnerDaySuggestion([
          _plan(weeklyTarget: 3, days: const [1, 2, 3, 4, 5, 6, 7]),
        ]),
        isNull,
      );
    });
  });

  group('weeklyReminderDates', () {
    // 2026-09-28 is a Monday.
    Plan weekly({List<DateTime> completed = const []}) => Plan(
      id: 'w',
      userId: 'me',
      startDate: DateTime(2026, 9, 28),
      endDate: DateTime(2026, 10, 25, 23, 59, 59),
      state: PlanState.active,
      items: [
        PlanItem(
          title: '러닝',
          days: const [1, 2, 3, 4, 5, 6, 7],
          count: 7,
          notificationTime: NotificationTime.custom(21, 0),
        ),
      ],
      createdAt: DateTime(2026, 9, 28),
      completedDates: completed,
      weeklyTarget: 3,
    );

    test('only the predicted must-do days of each week', () {
      final dates = weeklyReminderDates(
        weekly(),
        now: DateTime(2026, 9, 30, 10),
      )!;
      expect(dates.first, DateTime(2026, 10, 2));
      expect(dates.where((x) => x.weekday < DateTime.friday), isEmpty);
      expect(dates.length, 3 * 4); // Fri–Sun of the four weeks
    });

    test('a record just written moves this week\'s must-do days', () {
      final plan = weekly(completed: [DateTime(2026, 9, 28, 19)]);
      final before = weeklyReminderDates(plan, now: DateTime(2026, 9, 29, 22))!;
      expect(before.take(2), [DateTime(2026, 10, 3), DateTime(2026, 10, 4)]);
      final after = weeklyReminderDates(
        plan,
        now: DateTime(2026, 9, 29, 22),
        creditedToday: true,
      )!;
      expect(after.first, DateTime(2026, 10, 4));
    });

    test('null for a fixed-weekday plan', () {
      expect(weeklyReminderDates(_plan(), now: DateTime.now()), isNull);
    });
  });
}
