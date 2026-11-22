import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/challenge/domain/duo_challenge.dart';
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

/// A challenge running around the real clock (the view model reads it).
DuoChallenge _running({int startedDaysAgo = 2, int daysLeft = 10}) {
  final now = DateTime.now();
  return DuoChallenge(
    id: 'test_challenge',
    start: DateTime(now.year, now.month, now.day - startedDaysAgo),
    end: DateTime(now.year, now.month, now.day + daysLeft),
    teaserFrom: DateTime(now.year, now.month, now.day - startedDaysAgo - 14),
  );
}

void main() {
  test('a promise made for a running challenge runs to its last day', () async {
    final records = _Records();
    final container = _container(records, _Scheduler());
    addTearDown(container.dispose);
    await container.read(planCreateViewModelProvider.future);
    await container.read(myProfileProvider.future);
    final vm = container.read(planCreateViewModelProvider.notifier);
    final challenge = _running();

    await vm.dispatch(ResetIntent(challenge: challenge));
    await vm.dispatch(const UpdateActionIntent('러닝 30분'));
    expect(
      container.read(planCreateViewModelProvider).value!.challenge,
      same(challenge),
      reason: 'typing keeps the challenge',
    );
    await vm.dispatch(const SavePlanIntent());

    final now = DateTime.now();
    final plan = records.createdPlan!;
    expect(plan.challengeId, 'test_challenge');
    expect(plan.startDate, DateTime(now.year, now.month, now.day));
    expect(
      plan.endDate,
      DateTime(
        challenge.end.year,
        challenge.end.month,
        challenge.end.day,
        23,
        59,
        59,
      ),
    );
    expect(plan.state, PlanState.active);
    expect(plan.toMap()['challengeId'], 'test_challenge');
    expect(
      planCreatedAnalyticsParams(
        container.read(planCreateViewModelProvider).value!,
        plan,
        isEdit: false,
      )['challenge'],
      'test_challenge',
    );
  });

  test('an ordinary promise is 28 days and in no challenge', () async {
    final records = _Records();
    final container = _container(records, _Scheduler());
    addTearDown(container.dispose);
    await container.read(planCreateViewModelProvider.future);
    await container.read(myProfileProvider.future);
    final vm = container.read(planCreateViewModelProvider.notifier);

    await vm.dispatch(const ResetIntent());
    await vm.dispatch(const UpdateActionIntent('러닝 30분'));
    await vm.dispatch(const SavePlanIntent());

    final plan = records.createdPlan!;
    final period = Plan.periodStartingOn(DateTime.now());
    expect(plan.challengeId, isNull);
    expect(plan.startDate, period.start);
    expect(plan.endDate, period.end);
    expect(plan.toMap().containsKey('challengeId'), isFalse);
  });

  test('a challenge that is not running is dropped at save time', () {
    final now = DateTime(2027, 1, 22, 9);
    PlanCreateState state(DuoChallenge? challenge) => PlanCreateState(
      notificationTime: NotificationTime.custom(21, 0),
      challenge: challenge,
    );
    expect(PlanCreateViewModel.challengeInEffect(state(null), now), isNull);
    // Over since yesterday.
    expect(
      PlanCreateViewModel.challengeInEffect(state(kNewYear2027Challenge), now),
      isNull,
    );
    // Not started yet.
    expect(
      PlanCreateViewModel.challengeInEffect(
        state(kNewYear2027Challenge),
        DateTime(2026, 12, 30),
      ),
      isNull,
    );
    expect(
      PlanCreateViewModel.challengeInEffect(
        state(kNewYear2027Challenge),
        DateTime(2027, 1, 21, 23),
      ),
      same(kNewYear2027Challenge),
    );
  });

  test('editing an entered promise keeps it entered', () async {
    final records = _Records();
    final container = _container(records, _Scheduler());
    addTearDown(container.dispose);
    await container.read(planCreateViewModelProvider.future);
    await container.read(myProfileProvider.future);
    final vm = container.read(planCreateViewModelProvider.notifier);
    final period = _running().planPeriodFrom(DateTime.now());
    final entered = Plan(
      id: 'plan-1',
      userId: 'user-1',
      managerId: 'partner-1',
      startDate: period.start,
      endDate: period.end,
      state: PlanState.active,
      items: [
        PlanItem(
          title: '러닝 30분',
          days: const [1, 3, 5],
          count: 3,
          notificationTime: NotificationTime.custom(21, 0),
        ),
      ],
      createdAt: period.start,
      workoutType: 'running',
      challengeId: 'test_challenge',
    );

    await vm.dispatch(InitializePlanIntent(entered));
    await vm.dispatch(const UpdateActionIntent('러닝 40분'));
    await vm.dispatch(const SavePlanIntent());

    final updated = records.updatedPlan!;
    expect(updated.challengeId, 'test_challenge');
    expect(updated.endDate, period.end, reason: 'the period is untouched');
    expect(records.createdPlan, isNull);
  });
}
