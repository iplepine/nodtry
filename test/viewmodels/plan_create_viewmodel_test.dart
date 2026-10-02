import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/features/plan/domain/workout_template.dart';
import 'package:nod_try/features/plan/presentation/plan_create_state.dart';
import 'package:nod_try/features/plan/presentation/viewmodel/plan_create_viewmodel.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/promise_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/services/notification_service.dart';

class _FakeRecordRepository extends Fake implements RecordRepository {
  Plan? createdPlan;
  Plan? updatedPlan;
  int createPlanCalls = 0;
  int updatePlanCalls = 0;

  /// Plans returned for the partner when the screen asks for a day suggestion.
  final Map<String, List<Plan>> plansByUser = {};

  /// When set, `createPlan` blocks until it completes — lets a test hold a save
  /// in flight and fire a second one, the way a double-tap would.
  Completer<void>? createGate;

  @override
  Future<String> createPlan(Plan plan) async {
    createPlanCalls++;
    if (createGate != null) await createGate!.future;
    createdPlan = plan;
    return 'new-plan-id';
  }

  @override
  Future<void> updatePlan(Plan plan) async {
    updatePlanCalls++;
    updatedPlan = plan;
  }

  @override
  Future<List<Plan>> getPlansByUserId(String userId) async {
    return plansByUser[userId] ?? const [];
  }

  @override
  Future<List<HomeCardModel>> getHomeCardStates() async => [];

  @override
  Stream<List<HomeCardModel>> getHomeCardStatesStream() => Stream.value([]);

  @override
  Future<List<HistoryItem>> getHistoryItems() async => [];

  @override
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds}) {
    return Stream.value([]);
  }
}

class _FakePlanReminderScheduler implements PlanReminderScheduler {
  List<int>? scheduledDays;
  int? scheduledHour;
  int? scheduledMinute;

  /// Fails the first schedule attempt only — models the realistic case where
  /// the plan is written but the alarm hand-off blows up afterwards.
  bool failOnce = false;

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
    if (failOnce) {
      failOnce = false;
      throw Exception('scheduling failed');
    }
    scheduledDays = days;
    scheduledHour = hour;
    scheduledMinute = minute;
  }
}

final _now = DateTime(2026, 5, 3);

UserModel _user(String uid, {String? name}) {
  return UserModel(
    uid: uid,
    displayName: name,
    createdAt: _now,
    updatedAt: _now,
  );
}

ConnectedUser _partner() => ConnectedUser(
  user: _user('partner-1', name: '지민'),
  isSupported: true,
  isCheering: true,
);

ProviderContainer _container(
  _FakeRecordRepository repository, {
  _FakePlanReminderScheduler? scheduler,
  bool withPartner = false,
}) {
  return ProviderContainer(
    overrides: [
      recordRepositoryProvider.overrideWithValue(repository),
      settingAlarmUseCaseProvider.overrideWithValue(
        SettingAlarmUseCase(scheduler ?? _FakePlanReminderScheduler()),
      ),
      myProfileProvider.overrideWithValue(AsyncData(_user('user-1'))),
      connectedProfilesProvider.overrideWith(
        (ref) async => withPartner ? [_partner()] : <ConnectedUser>[],
      ),
    ],
  );
}

Future<AppLocalizations> _ko() =>
    AppLocalizations.delegate.load(const Locale('ko'));

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

Plan _activePlan({
  String id = 'plan-1',
  String? workoutType = 'running',
  PlanState state = PlanState.active,
  NotificationTime? time,
  List<int> days = const [2, 4, 6],
}) {
  return Plan(
    id: id,
    userId: 'user-1',
    managerId: 'partner-1',
    startDate: DateTime(2026, 4, 20),
    endDate: DateTime(2026, 5, 17, 23, 59, 59),
    state: state,
    createdAt: DateTime(2026, 4, 20),
    completedDates: [DateTime(2026, 4, 21), DateTime(2026, 4, 23)],
    verifiedDates: [DateTime(2026, 4, 21)],
    lastActionId: 'action-9',
    lastUpdatedBy: 'partner-1',
    promise: Promise(
      status: PromiseStatus.active,
      proposerId: 'user-1',
      proposedAt: DateTime(2026, 4, 20),
    ),
    workoutType: workoutType,
    items: [
      PlanItem(
        title: '30분 달리기',
        days: days,
        count: days.length,
        notificationTime: time ?? NotificationTime.custom(21, 0),
      ),
    ],
  );
}

void main() {
  group('initial state', () {
    test('has no workout yet, Mon/Wed/Fri and a 9 PM deadline', () async {
      final container = _container(_FakeRecordRepository());
      addTearDown(container.dispose);

      final state = await container.read(planCreateViewModelProvider.future);

      expect(state.workoutType, isNull);
      expect(state.selectedTemplateId, isNull);
      expect(state.action, isEmpty);
      expect(state.selectedDays, {0, 2, 4});
      expect(state.notificationTime.type, isNot('none'));
      expect(state.notificationTime.hour, 21);
      expect(state.notificationTime.minute, 0);
      expect(state.missingField, PlanCreateMissing.action);
    });
  });

  group('workout tiles', () {
    test('a tile fills the promise line, days and deadline', () async {
      final container = _container(_FakeRecordRepository());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await _ko();

      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(
            SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.gym)),
          );

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.workoutType, WorkoutType.gym);
      expect(state.selectedTemplateId, 'gym');
      expect(state.action, '헬스장 가서 운동하기');
      expect(state.selectedDays, {0, 2, 4});
      expect(state.notificationTime.hour, 22);
      expect(state.canSave, isTrue);
    });

    test('switching tiles replaces an untouched line', () async {
      final container = _container(_FakeRecordRepository());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await _ko();
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.gym)),
      );
      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.cycling)),
      );

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.workoutType, WorkoutType.cycling);
      expect(state.action, '자전거 40분 타기');
      expect(state.selectedDays, {5, 6});
      expect(state.notificationTime.hour, 19);
    });

    test('a tile keeps a line typed by hand and days picked by hand', () async {
      final container = _container(_FakeRecordRepository());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await _ko();
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(const UpdateActionIntent('퇴근하고 PT 받기'));
      await notifier.dispatch(const UpdateSelectedDaysIntent({1, 3}));
      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.gym)),
      );

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.workoutType, WorkoutType.gym);
      expect(state.action, '퇴근하고 PT 받기');
      expect(state.selectedDays, {1, 3});
      // The deadline was never touched, so the tile's default applies.
      expect(state.notificationTime.hour, 22);
    });

    test('the free-form tile clears a pre-filled line', () async {
      final container = _container(_FakeRecordRepository());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await _ko();
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.walking)),
      );
      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.other)),
      );

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.workoutType, WorkoutType.other);
      expect(state.action, isEmpty);
      expect(state.missingField, PlanCreateMissing.action);
    });

    test(
      'typing keeps the selected workout and template (no reset on edit)',
      () async {
        final container = _container(_FakeRecordRepository());
        addTearDown(container.dispose);
        await container.read(planCreateViewModelProvider.future);
        final l10n = await _ko();
        final notifier = container.read(planCreateViewModelProvider.notifier);

        await notifier.dispatch(
          SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.running)),
        );
        await notifier.dispatch(const UpdateActionIntent('한강 5km 달리기'));

        final state = container.read(planCreateViewModelProvider).value!;
        expect(state.action, '한강 5km 달리기');
        expect(state.workoutType, WorkoutType.running);
        expect(state.selectedTemplateId, 'running');
      },
    );
  });

  group('required fields', () {
    test('a promise needs at least one day', () async {
      final repository = _FakeRecordRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final l10n = await _ko();
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.hiking)),
      );
      // Hiking defaults to Saturday only; un-picking it leaves no day.
      await notifier.dispatch(const ToggleDayIntent(5));

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.selectedDays, isEmpty);
      expect(state.missingField, PlanCreateMissing.days);
      await expectLater(
        notifier.dispatch(const SavePlanIntent()),
        throwsA(
          isA<PlanCreateIncompleteException>().having(
            (e) => e.missing,
            'missing',
            PlanCreateMissing.days,
          ),
        ),
      );
      expect(repository.createPlanCalls, 0);
    });

    test('an empty promise line is not saved', () async {
      final repository = _FakeRecordRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await expectLater(
        notifier.dispatch(const SavePlanIntent()),
        throwsA(isA<PlanCreateIncompleteException>()),
      );
      expect(repository.createPlanCalls, 0);
    });
  });

  group('saving a new promise', () {
    test('with a partner it is active right away, no approval step', () async {
      final repository = _FakeRecordRepository();
      final scheduler = _FakePlanReminderScheduler();
      final container = _container(
        repository,
        scheduler: scheduler,
        withPartner: true,
      );
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final l10n = await _ko();
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(
        SelectWorkoutIntent(
          workoutTemplateFor(l10n, WorkoutType.homeTraining),
        ),
      );
      await notifier.dispatch(const SavePlanIntent());

      final plan = repository.createdPlan!;
      final item = plan.items.single;
      final today = _day(DateTime.now());

      expect(plan.id, isNull);
      expect(plan.userId, 'user-1');
      expect(plan.managerId, 'partner-1');
      expect(plan.state, PlanState.active);
      expect(plan.lastUpdatedBy, 'user-1');
      expect(plan.workoutType, 'home_training');
      expect(plan.startDate, today);
      expect(_day(plan.endDate), today.add(const Duration(days: 27)));
      expect(plan.endDate.hour, 23);
      expect(plan.endDate.minute, 59);
      expect(item.title, '홈트 20분 하기');
      expect(item.days, [1, 2, 3, 4, 5]);
      expect(item.count, 5);
      expect(item.notificationTime?.type, isNot('none'));
      expect(item.notificationTime?.hour, 22);
      expect(scheduler.scheduledDays, [1, 2, 3, 4, 5]);
      expect(scheduler.scheduledHour, 22);
      expect(scheduler.scheduledMinute, 0);
      expect(plan.toMap()['workoutType'], 'home_training');

      final saved = container.read(planCreateViewModelProvider).value!;
      expect(saved.existingPlanId, 'new-plan-id');
      expect(saved.originalPlan?.managerId, 'partner-1');
    });

    test('solo it is active without a manager', () async {
      final repository = _FakeRecordRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final l10n = await _ko();
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.diet)),
      );
      await notifier.dispatch(const SavePlanIntent());

      final plan = repository.createdPlan!;
      expect(plan.state, PlanState.active);
      expect(plan.managerId, isNull);
      expect(plan.workoutType, 'diet');
      expect(plan.items.single.title, '야식 참기');
      expect(plan.items.single.days, [1, 2, 3, 4, 5, 6, 7]);
    });

    test('a promise typed without a tile is saved as "other"', () async {
      final repository = _FakeRecordRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(const UpdateActionIntent('  줄넘기 500개  '));
      await notifier.dispatch(const SavePlanIntent());

      final plan = repository.createdPlan!;
      expect(plan.workoutType, 'other');
      expect(plan.items.single.title, '줄넘기 500개');
      expect(plan.items.single.days, [1, 3, 5]);
    });

    test('a second send while the first is in flight creates one plan', () async {
      final repository = _FakeRecordRepository()..createGate = Completer<void>();
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final l10n = await _ko();

      final notifier = container.read(planCreateViewModelProvider.notifier);
      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.walking)),
      );

      // The button only pops the screen once the round-trip completes, so an
      // impatient user can land a second tap while the first is saving.
      final first = notifier.dispatch(const SavePlanIntent());
      final second = notifier.dispatch(const SavePlanIntent());
      repository.createGate!.complete();
      await Future.wait([first, second]);

      expect(repository.createPlanCalls, 1);
    });

    test(
      'reset clears the id kept from the last save, so the next plan is new',
      () async {
        final repository = _FakeRecordRepository();
        final container = _container(repository);
        addTearDown(container.dispose);
        await container.read(planCreateViewModelProvider.future);
        await container.read(myProfileProvider.future);
        final l10n = await _ko();

        final notifier = container.read(planCreateViewModelProvider.notifier);
        await notifier.dispatch(
          SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.walking)),
        );
        await notifier.dispatch(const SavePlanIntent());
        expect(
          container.read(planCreateViewModelProvider).value!.existingPlanId,
          'new-plan-id',
        );

        // The provider outlives the screen, which resets it on open.
        await notifier.dispatch(const ResetIntent());

        final state = container.read(planCreateViewModelProvider).value!;
        expect(state.existingPlanId, isNull);
        expect(state.originalPlan, isNull);
        expect(state.workoutType, isNull);
      },
    );

    test(
      'retrying after a failed save updates the plan instead of duplicating '
      'it, without restarting it',
      () async {
        final repository = _FakeRecordRepository();
        // Alarm scheduling runs after the plan document is already written.
        final scheduler = _FakePlanReminderScheduler()..failOnce = true;
        final container = _container(repository, scheduler: scheduler);
        addTearDown(container.dispose);
        await container.read(planCreateViewModelProvider.future);
        await container.read(myProfileProvider.future);
        final l10n = await _ko();

        final notifier = container.read(planCreateViewModelProvider.notifier);
        await notifier.dispatch(
          SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.walking)),
        );

        await expectLater(
          notifier.dispatch(const SavePlanIntent()),
          throwsA(isA<Exception>()),
        );
        expect(repository.createPlanCalls, 1);
        final created = repository.createdPlan!;

        // The user sees the error and taps send again.
        await notifier.dispatch(const SavePlanIntent());

        expect(repository.createPlanCalls, 1);
        expect(repository.updatePlanCalls, 1);
        final updated = repository.updatedPlan!;
        expect(updated.id, 'new-plan-id');
        expect(updated.state, PlanState.active);
        expect(updated.startDate, created.startDate);
        expect(updated.endDate, created.endDate);
        expect(updated.workoutType, 'walking');
      },
    );
  });

  group('editing', () {
    test('restores the workout, days and deadline of the plan', () async {
      final container = _container(_FakeRecordRepository());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);

      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(InitializePlanIntent(_activePlan()));

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.existingPlanId, 'plan-1');
      expect(state.workoutType, WorkoutType.running);
      expect(state.action, '30분 달리기');
      expect(state.selectedDays, {1, 3, 5});
      expect(state.notificationTime.hour, 21);
      expect(state.selectedTemplateId, isNull);
    });

    test('an old plan without a deadline or days gets explicit ones', () async {
      final container = _container(_FakeRecordRepository());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);

      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(
            InitializePlanIntent(
              _activePlan(
                workoutType: null,
                time: NotificationTime.none(),
                days: const [],
              ),
            ),
          );

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.workoutType, isNull);
      // Old "no day" plans meant every day.
      expect(state.selectedDays, {0, 1, 2, 3, 4, 5, 6});
      expect(state.notificationTime.type, isNot('none'));
      expect(state.notificationTime.hour, 21);
      expect(state.canSave, isTrue);
    });

    test(
      'an active plan keeps its period, state, history and bet',
      () async {
        final repository = _FakeRecordRepository();
        final container = _container(repository, withPartner: true);
        addTearDown(container.dispose);
        await container.read(planCreateViewModelProvider.future);
        await container.read(myProfileProvider.future);
        final l10n = await _ko();
        final original = _activePlan();
        final notifier = container.read(planCreateViewModelProvider.notifier);

        await notifier.dispatch(InitializePlanIntent(original));
        await notifier.dispatch(const UpdateActionIntent('40분 달리기'));
        await notifier.dispatch(
          SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.gym)),
        );
        await notifier.dispatch(
          UpdateNotificationTimeIntent(NotificationTime.custom(7, 0)),
        );
        await notifier.dispatch(const SavePlanIntent());

        expect(repository.createPlanCalls, 0);
        expect(repository.updatePlanCalls, 1);
        final saved = repository.updatedPlan!;
        expect(saved.id, 'plan-1');
        expect(saved.state, PlanState.active);
        expect(saved.startDate, original.startDate);
        expect(saved.endDate, original.endDate);
        expect(saved.createdAt, original.createdAt);
        expect(saved.completedDates, original.completedDates);
        expect(saved.verifiedDates, original.verifiedDates);
        expect(saved.lastActionId, 'action-9');
        expect(saved.promise?.status, PromiseStatus.active);
        expect(saved.managerId, 'partner-1');
        // The partner gets the "changed" push only if the editor wrote last.
        expect(saved.lastUpdatedBy, 'user-1');
        // A typed title survives picking a tile; the tile sets the type.
        expect(saved.items.single.title, '40분 달리기');
        expect(saved.workoutType, 'gym');
        // Days of the edited plan are kept; the deadline was changed by hand.
        expect(saved.items.single.days, [2, 4, 6]);
        expect(saved.items.single.notificationTime?.hour, 7);
      },
    );

    test('a legacy plan without a workout stays without one', () async {
      final repository = _FakeRecordRepository();
      final container = _container(repository, withPartner: true);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(
        InitializePlanIntent(_activePlan(workoutType: null)),
      );
      await notifier.dispatch(const SavePlanIntent());

      expect(repository.updatedPlan!.workoutType, isNull);
      expect(repository.updatedPlan!.toMap().containsKey('workoutType'), false);
    });

    for (final legacyState in [
      PlanState.pendingApproval,
      PlanState.rejected,
    ]) {
      test(
        'a legacy ${legacyState.toMap()} plan becomes active from today',
        () async {
          final repository = _FakeRecordRepository();
          final container = _container(repository, withPartner: true);
          addTearDown(container.dispose);
          await container.read(planCreateViewModelProvider.future);
          await container.read(myProfileProvider.future);
          final notifier = container.read(
            planCreateViewModelProvider.notifier,
          );

          await notifier.dispatch(
            InitializePlanIntent(_activePlan(state: legacyState)),
          );
          await notifier.dispatch(const SavePlanIntent());

          final saved = repository.updatedPlan!;
          final today = _day(DateTime.now());
          expect(saved.state, PlanState.active);
          expect(saved.startDate, today);
          expect(_day(saved.endDate), today.add(const Duration(days: 27)));
          expect(saved.lastUpdatedBy, 'user-1');
        },
      );
    }

    test(
      'starting a follow-up plan from a finished one creates it, not overwrites',
      () async {
        final repository = _FakeRecordRepository();
        final container = _container(repository);
        addTearDown(container.dispose);
        await container.read(planCreateViewModelProvider.future);
        await container.read(myProfileProvider.future);
        final l10n = await _ko();

        final notifier = container.read(planCreateViewModelProvider.notifier);
        await notifier.dispatch(
          SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.walking)),
        );
        await notifier.dispatch(const SavePlanIntent());
        expect(repository.createPlanCalls, 1);

        // "Continue after settlement" pushes the screen with the old plan
        // copied as a template — same content, no id.
        final template = _activePlan(
          state: PlanState.completed,
        ).asRestartTemplate();
        expect(template.id, isNull, reason: 'a template carries no id');
        await notifier.dispatch(InitializePlanIntent(template));

        // An id-less template must clear the id left over from the last save,
        // otherwise the follow-up plan silently overwrites the finished one.
        expect(
          container.read(planCreateViewModelProvider).value!.existingPlanId,
          isNull,
        );

        await notifier.dispatch(const SavePlanIntent());
        expect(repository.createPlanCalls, 2);
        expect(repository.updatePlanCalls, 0);
        final created = repository.createdPlan!;
        expect(created.id, isNull);
        expect(created.state, PlanState.active);
        expect(created.workoutType, 'running');
        expect(created.items.single.title, '30분 달리기');
        expect(created.completedDates, isEmpty);
        expect(created.startDate, _day(DateTime.now()));
      },
    );

    test('restarting an old non-workout plan keeps it untyped', () async {
      final repository = _FakeRecordRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(
        InitializePlanIntent(
          _activePlan(
            workoutType: null,
            state: PlanState.completed,
          ).asRestartTemplate(),
        ),
      );
      await notifier.dispatch(const SavePlanIntent());

      expect(repository.createdPlan!.workoutType, isNull);
    });
  });

  group('partner weekday suggestion', () {
    test('uses the newest active plan of the partner', () {
      Plan partnerPlan(
        DateTime createdAt,
        List<int> days, {
        PlanState state = PlanState.active,
      }) {
        return Plan(
          userId: 'partner-1',
          startDate: createdAt,
          endDate: createdAt.add(const Duration(days: 27)),
          state: state,
          createdAt: createdAt,
          items: [PlanItem(title: 'x', days: days, count: days.length)],
        );
      }

      expect(PlanCreateViewModel.partnerDaySuggestion(const []), isNull);
      expect(
        PlanCreateViewModel.partnerDaySuggestion([
          partnerPlan(DateTime(2026, 4, 1), [1, 3, 5]),
          partnerPlan(DateTime(2026, 4, 10), [2, 4]),
          partnerPlan(
            DateTime(2026, 4, 20),
            [6, 7],
            state: PlanState.pendingApproval,
          ),
        ]),
        {1, 3},
      );
    });

    test('prefills a new promise with the partner\'s days', () async {
      final repository = _FakeRecordRepository();
      repository.plansByUser['partner-1'] = [
        _activePlan(id: 'partner-plan', days: const [2, 4]),
      ];
      final container = _container(repository, withPartner: true);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await _ko();
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(const PrefillPartnerDaysIntent());
      var state = container.read(planCreateViewModelProvider).value!;
      expect(state.selectedDays, {1, 3});
      expect(state.showsPartnerDays, isTrue);

      // Picking a tile keeps the shared days.
      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.gym)),
      );
      state = container.read(planCreateViewModelProvider).value!;
      expect(state.selectedDays, {1, 3});
      expect(state.action, '헬스장 가서 운동하기');

      await notifier.dispatch(const ToggleDayIntent(5));
      state = container.read(planCreateViewModelProvider).value!;
      expect(state.showsPartnerDays, isFalse);
    });

    test('never overrides the plan being edited', () async {
      final repository = _FakeRecordRepository();
      repository.plansByUser['partner-1'] = [
        _activePlan(id: 'partner-plan', days: const [7]),
      ];
      final container = _container(repository, withPartner: true);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(InitializePlanIntent(_activePlan()));
      await notifier.dispatch(const PrefillPartnerDaysIntent());

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.selectedDays, {1, 3, 5});
      expect(state.partnerSuggestedDays, isNull);
    });
  });

  group('plan_created analytics', () {
    test('reports workout type, template and whether it was edited', () async {
      final l10n = await _ko();
      final template = workoutTemplateFor(l10n, WorkoutType.yoga);
      final plan = Plan(
        userId: 'user-1',
        managerId: 'partner-1',
        startDate: _now,
        endDate: _now,
        state: PlanState.active,
        createdAt: _now,
        workoutType: 'yoga',
        items: [PlanItem(title: template.action, days: [1, 3, 5], count: 3)],
      );
      final untouched = PlanCreateState(
        action: template.action,
        selectedDays: template.selectedDayIndexes,
        notificationTime: template.deadline,
        workoutType: WorkoutType.yoga,
        appliedTemplate: template,
      );

      expect(planCreatedAnalyticsParams(untouched, plan, isEdit: false), {
        'is_edit': false,
        'frequency': 3,
        'has_partner': true,
        'workout_type': 'yoga',
        'template_id': 'yoga',
        'template_edited': false,
      });
      expect(
        planCreatedAnalyticsParams(
          untouched.copyWith(action: '요가 1시간'),
          plan,
          isEdit: false,
        )['template_edited'],
        isTrue,
      );
      expect(
        planCreatedAnalyticsParams(
          untouched.copyWith(editedAfterTemplate: true),
          plan,
          isEdit: false,
        )['template_edited'],
        isTrue,
      );

      final noTemplate = PlanCreateState(
        action: 'x',
        selectedDays: const {0},
        notificationTime: NotificationTime.custom(21, 0),
      );
      final legacy = Plan(
        userId: 'user-1',
        startDate: _now,
        endDate: _now,
        state: PlanState.active,
        createdAt: _now,
        items: [PlanItem(title: 'x', days: [1], count: 1)],
      );
      expect(planCreatedAnalyticsParams(noTemplate, legacy, isEdit: true), {
        'is_edit': true,
        'frequency': 1,
        'has_partner': false,
        'workout_type': 'none',
        'template_id': 'none',
        'template_edited': false,
      });
    });

    test('changing days after picking a tile marks the template edited', () async {
      final container = _container(_FakeRecordRepository());
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await _ko();
      final notifier = container.read(planCreateViewModelProvider.notifier);

      await notifier.dispatch(
        SelectWorkoutIntent(workoutTemplateFor(l10n, WorkoutType.yoga)),
      );
      expect(
        container.read(planCreateViewModelProvider).value!.editedAfterTemplate,
        isFalse,
      );
      await notifier.dispatch(const ToggleDayIntent(6));
      expect(
        container.read(planCreateViewModelProvider).value!.editedAfterTemplate,
        isTrue,
      );
    });
  });
}
