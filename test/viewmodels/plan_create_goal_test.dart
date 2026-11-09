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

/// D-day goal handling in [PlanCreateViewModel]: intents, what a new or edited
/// promise saves, and the explicit delete when a goal is removed on edit.
class _FakeRecordRepository extends Fake implements RecordRepository {
  Plan? createdPlan;
  Plan? updatedPlan;
  final List<({String planId, String? goalTitle, DateTime? goalDate})>
  goalUpdates = [];

  @override
  Future<String> createPlan(Plan plan) async {
    createdPlan = plan;
    return 'new-plan-id';
  }

  @override
  Future<void> updatePlan(Plan plan) async => updatedPlan = plan;

  @override
  Future<void> updatePlanGoal(
    String planId, {
    String? goalTitle,
    DateTime? goalDate,
  }) async {
    goalUpdates.add((planId: planId, goalTitle: goalTitle, goalDate: goalDate));
  }

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

class _NoopScheduler implements PlanReminderScheduler {
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
  }) async {}
}

final _created = DateTime(2026, 4, 20);

ProviderContainer _container(_FakeRecordRepository repository) {
  final me = UserModel(uid: 'user-1', createdAt: _created, updatedAt: _created);
  return ProviderContainer(
    overrides: [
      recordRepositoryProvider.overrideWithValue(repository),
      settingAlarmUseCaseProvider.overrideWithValue(
        SettingAlarmUseCase(_NoopScheduler()),
      ),
      myProfileProvider.overrideWithValue(AsyncData(me)),
      connectedProfilesProvider.overrideWith((ref) async => <ConnectedUser>[]),
    ],
  );
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Plan _plan({String? id = 'plan-1', String? goalTitle, DateTime? goalDate}) {
  return Plan(
    id: id,
    userId: 'user-1',
    startDate: _created,
    endDate: DateTime(2026, 5, 17, 23, 59, 59),
    state: PlanState.active,
    createdAt: _created,
    workoutType: 'running',
    goalTitle: goalTitle,
    goalDate: goalDate,
    items: [
      PlanItem(
        title: '30분 달리기',
        days: const [2, 4, 6],
        count: 3,
        notificationTime: NotificationTime.custom(21, 0),
      ),
    ],
  );
}

Future<({ProviderContainer container, PlanCreateViewModel notifier})> _setUp(
  _FakeRecordRepository repository,
) async {
  final container = _container(repository);
  addTearDown(container.dispose);
  await container.read(planCreateViewModelProvider.future);
  await container.read(myProfileProvider.future);
  return (
    container: container,
    notifier: container.read(planCreateViewModelProvider.notifier),
  );
}

PlanCreateState _state(ProviderContainer c) =>
    c.read(planCreateViewModelProvider).value!;

void main() {
  group('goal intents', () {
    test('a new promise starts without a goal', () async {
      final (:container, notifier: _) = await _setUp(_FakeRecordRepository());
      expect(_state(container).goalTitle, isEmpty);
      expect(_state(container).goalDate, isNull);
    });

    test('title, date (date part only) and clear', () async {
      final (:container, :notifier) = await _setUp(_FakeRecordRepository());

      await notifier.dispatch(const UpdateGoalTitleIntent('제주 여행'));
      await notifier.dispatch(
        UpdateGoalDateIntent(DateTime(2026, 12, 24, 18, 30)),
      );
      expect(_state(container).goalTitle, '제주 여행');
      expect(_state(container).goalDate, DateTime(2026, 12, 24));

      await notifier.dispatch(const ClearGoalIntent());
      expect(_state(container).goalTitle, isEmpty);
      expect(_state(container).goalDate, isNull);
    });

    test('editing a plan loads its goal', () async {
      final (:container, :notifier) = await _setUp(_FakeRecordRepository());
      final goal = DateTime(2020, 1, 5);

      await notifier.dispatch(
        InitializePlanIntent(_plan(goalTitle: '결혼식', goalDate: goal)),
      );

      // An existing plan keeps even a past goal; the card hides it by itself.
      expect(_state(container).goalTitle, '결혼식');
      expect(_state(container).goalDate, goal);
    });

    test(
      'a restart copy keeps an upcoming goal and drops a past one',
      () async {
        final (:container, :notifier) = await _setUp(_FakeRecordRepository());
        final ahead = _today().add(const Duration(days: 10));

        await notifier.dispatch(
          InitializePlanIntent(
            _plan(id: null, goalTitle: '여행', goalDate: ahead),
          ),
        );
        expect(_state(container).goalTitle, '여행');
        expect(_state(container).goalDate, ahead);

        await notifier.dispatch(
          InitializePlanIntent(
            _plan(
              id: null,
              goalTitle: '여행',
              goalDate: _today().subtract(const Duration(days: 1)),
            ),
          ),
        );
        expect(_state(container).goalTitle, isEmpty);
        expect(_state(container).goalDate, isNull);
      },
    );
  });

  group('saving a new promise', () {
    test('writes a normalized goal title with the date', () async {
      final repository = _FakeRecordRepository();
      final (container: _, :notifier) = await _setUp(repository);
      final date = _today().add(const Duration(days: 23));

      await notifier.dispatch(const UpdateActionIntent('한강 5km 달리기'));
      await notifier.dispatch(const UpdateGoalTitleIntent('  제주 여행  '));
      await notifier.dispatch(UpdateGoalDateIntent(date));
      await notifier.dispatch(const SavePlanIntent());

      final saved = repository.createdPlan!;
      expect(saved.goalTitle, '제주 여행');
      expect(saved.goalDate, date);
      expect(saved.toMap()['goalTitle'], '제주 여행');
      expect(saved.toMap().containsKey('goalDate'), isTrue);
    });

    test('a title without a date is not saved', () async {
      final repository = _FakeRecordRepository();
      final (container: _, :notifier) = await _setUp(repository);

      await notifier.dispatch(const UpdateActionIntent('한강 5km 달리기'));
      await notifier.dispatch(const UpdateGoalTitleIntent('제주 여행'));
      await notifier.dispatch(const SavePlanIntent());

      final saved = repository.createdPlan!;
      expect(saved.goalTitle, isNull);
      expect(saved.goalDate, isNull);
      final map = saved.toMap();
      expect(map.containsKey('goalTitle'), isFalse);
      expect(map.containsKey('goalDate'), isFalse);
    });

    test('without a goal no goal fields are written', () async {
      final repository = _FakeRecordRepository();
      final (container: _, :notifier) = await _setUp(repository);

      await notifier.dispatch(const UpdateActionIntent('한강 5km 달리기'));
      await notifier.dispatch(const SavePlanIntent());

      final map = repository.createdPlan!.toMap();
      expect(map.containsKey('goalTitle'), isFalse);
      expect(map.containsKey('goalDate'), isFalse);
    });
  });

  group('saving an edit', () {
    test('changing the goal goes through updatePlan only', () async {
      final repository = _FakeRecordRepository();
      final (container: _, :notifier) = await _setUp(repository);
      final next = _today().add(const Duration(days: 40));

      await notifier.dispatch(
        InitializePlanIntent(
          _plan(
            goalTitle: '여행',
            goalDate: _today().add(const Duration(days: 5)),
          ),
        ),
      );
      await notifier.dispatch(const UpdateGoalTitleIntent('바디프로필'));
      await notifier.dispatch(UpdateGoalDateIntent(next));
      await notifier.dispatch(const SavePlanIntent());

      expect(repository.updatedPlan!.goalTitle, '바디프로필');
      expect(repository.updatedPlan!.goalDate, next);
      expect(repository.goalUpdates, isEmpty);
    });

    test('removing the goal deletes both fields explicitly', () async {
      final repository = _FakeRecordRepository();
      final (container: _, :notifier) = await _setUp(repository);

      await notifier.dispatch(
        InitializePlanIntent(
          _plan(
            goalTitle: '여행',
            goalDate: _today().add(const Duration(days: 5)),
          ),
        ),
      );
      await notifier.dispatch(const ClearGoalIntent());
      await notifier.dispatch(const SavePlanIntent());

      expect(repository.updatedPlan!.goalDate, isNull);
      expect(repository.goalUpdates, hasLength(1));
      final update = repository.goalUpdates.single;
      expect(update.planId, 'plan-1');
      expect(update.goalDate, isNull);
      expect(update.goalTitle, isNull);
    });

    test('removing only the title deletes the title', () async {
      final repository = _FakeRecordRepository();
      final (container: _, :notifier) = await _setUp(repository);
      final date = _today().add(const Duration(days: 5));

      await notifier.dispatch(
        InitializePlanIntent(_plan(goalTitle: '여행', goalDate: date)),
      );
      await notifier.dispatch(const UpdateGoalTitleIntent('   '));
      await notifier.dispatch(const SavePlanIntent());

      expect(repository.updatedPlan!.goalTitle, isNull);
      expect(repository.goalUpdates.single.goalTitle, isNull);
      expect(repository.goalUpdates.single.goalDate, date);
    });

    test('a plan without a goal stays without one', () async {
      final repository = _FakeRecordRepository();
      final (container: _, :notifier) = await _setUp(repository);

      await notifier.dispatch(InitializePlanIntent(_plan()));
      await notifier.dispatch(const SavePlanIntent());

      expect(repository.updatedPlan!.goalDate, isNull);
      expect(repository.goalUpdates, isEmpty);
    });
  });
}
