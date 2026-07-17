import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/study_plan_template.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/l10n/app_localizations.dart';
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

class _FakeRecordRepository extends Fake implements RecordRepository {
  Plan? createdPlan;
  int createPlanCalls = 0;
  int updatePlanCalls = 0;

  /// When set, `createPlan` blocks until it completes — lets a test hold a save
  /// in flight and fire a second one, the way a double-tap would.
  Completer<void>? createGate;

  @override
  Future<String> createPlan(Plan plan) async {
    createPlanCalls++;
    if (createGate != null) await createGate!.future;
    createdPlan = plan;
    return 'study-plan-id';
  }

  @override
  Future<void> updatePlan(Plan plan) async {
    updatePlanCalls++;
    createdPlan = plan;
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
  int? scheduledIntervalHours;
  int? scheduledStartHour;
  int? scheduledEndHour;

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
    scheduledIntervalHours = intervalHours;
    scheduledStartHour = startHour;
    scheduledEndHour = endHour;
  }
}

UserModel _buildUser() {
  final now = DateTime(2026, 5, 3);
  return UserModel(uid: 'user-1', createdAt: now, updatedAt: now);
}

void main() {
  test('initial state uses study sprint defaults', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(planCreateViewModelProvider.future);

    expect(state.selectedDays, {0, 2, 4});
    expect(state.notificationTime.hour, 21);
    expect(state.notificationTime.minute, 0);
    expect(state.currentStep, 1);
    expect(state.selectedCategoryId, planCategoryStudy);
  });

  test(
    'apply recommendation fills action, category, days, and reminder',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

      final template = studyPlanTemplatesFor(l10n).firstWhere(
        (template) => template.id == 'english_sentences',
      );

      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(ApplyStudyTemplateIntent(template));

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.selectedCategoryId, planCategoryStudy);
      expect(state.selectedTemplateId, 'english_sentences');
      expect(state.action, '영어 문장 10개 소리내어 읽기');
      expect(state.description, contains('영어'));
      expect(state.selectedDays, {0, 1, 2, 3, 4});
      expect(state.notificationTime.hour, 21);
      expect(state.notificationTime.minute, 0);
    },
  );

  test(
    'selecting exercise category clears action and waits for a choice',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(const UpdateActionIntent('이전 입력'));
      final category = planCategoriesFor(l10n).firstWhere(
        (category) => category.id == planCategoryExercise,
      );

      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(SelectPlanCategoryIntent(category));

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.selectedCategoryId, planCategoryExercise);
      expect(state.selectedTemplateId, isNull);
      expect(state.action, isEmpty);
      expect(state.selectedDays, {0, 2, 4});
      expect(state.notificationTime.hour, 21);
    },
  );

  test(
    'selecting direct input clears recommendations and focuses custom flow',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

      final template = studyPlanTemplatesFor(l10n).first;
      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(ApplyStudyTemplateIntent(template));
      final category = planCategoriesFor(l10n).firstWhere(
        (category) => category.id == planCategoryCustom,
      );

      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(SelectPlanCategoryIntent(category));

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.selectedCategoryId, planCategoryCustom);
      expect(state.selectedTemplateId, isNull);
      expect(state.action, isEmpty);
      expect(state.description, isEmpty);
    },
  );

  test('exercise recommendation uses exercise category', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(planCreateViewModelProvider.future);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    final template = studyPlanTemplatesFor(l10n).firstWhere(
      (template) => template.id == 'walking',
    );

    await container
        .read(planCreateViewModelProvider.notifier)
        .dispatch(ApplyStudyTemplateIntent(template));

    final state = container.read(planCreateViewModelProvider).value!;
    expect(state.selectedCategoryId, planCategoryExercise);
    expect(state.selectedTemplateId, 'walking');
    expect(state.action, '30분 걷기');
    expect(state.selectedDays, {0, 2, 4});
  });

  test('manual edits clear the selected template marker', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(planCreateViewModelProvider.future);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    final template = studyPlanTemplatesFor(l10n).first;
    await container
        .read(planCreateViewModelProvider.notifier)
        .dispatch(ApplyStudyTemplateIntent(template));
    await container
        .read(planCreateViewModelProvider.notifier)
        .dispatch(const UpdateActionIntent('내 방식으로 바꾼 공부'));

    final state = container.read(planCreateViewModelProvider).value!;
    expect(state.action, '내 방식으로 바꾼 공부');
    expect(state.selectedCategoryId, planCategoryCustom);
    expect(state.selectedTemplateId, isNull);
  });

  test(
    'day preset changes keep the selected category but clear template',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

      final template = studyPlanTemplatesFor(l10n).firstWhere(
        (template) => template.id == 'english_sentences',
      );
      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(ApplyStudyTemplateIntent(template));

      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(const UpdateSelectedDaysIntent({0, 2, 4}));

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.selectedCategoryId, planCategoryStudy);
      expect(state.selectedTemplateId, isNull);
      expect(state.selectedDays, {0, 2, 4});
    },
  );

  test(
    'save creates a 28-day study plan with sorted week days '
    '(active when the user has no partner to approve it)',
    () async {
      final repository = _FakeRecordRepository();
      final scheduler = _FakePlanReminderScheduler();
      final container = ProviderContainer(
        overrides: [
          recordRepositoryProvider.overrideWithValue(repository),
          settingAlarmUseCaseProvider.overrideWithValue(
            SettingAlarmUseCase(scheduler),
          ),
          myProfileProvider.overrideWithValue(AsyncData(_buildUser())),
          connectedProfilesProvider.overrideWith(
            (ref) async => <ConnectedUser>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      await container.read(myProfileProvider.future);

      final template = studyPlanTemplatesFor(l10n).firstWhere(
        (template) => template.id == 'certificate_questions',
      );
      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(ApplyStudyTemplateIntent(template));
      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(const SavePlanIntent());

      final plan = repository.createdPlan!;
      final item = plan.items.single;
      final startDay = DateTime(
        plan.startDate.year,
        plan.startDate.month,
        plan.startDate.day,
      );
      final endDay = DateTime(
        plan.endDate.year,
        plan.endDate.month,
        plan.endDate.day,
      );

      expect(plan.userId, 'user-1');
      // No connected partner → no one to approve, so the plan starts active.
      expect(plan.state, PlanState.active);
      expect(endDay, startDay.add(const Duration(days: 27)));
      expect(plan.endDate.hour, 23);
      expect(plan.endDate.minute, 59);
      expect(item.days, [1, 2, 3, 4, 5]);
      expect(item.notificationTime?.hour, 21);
      expect(item.notificationTime?.minute, 0);
      expect(scheduler.scheduledDays, [1, 2, 3, 4, 5]);
      expect(scheduler.scheduledHour, 21);
      expect(scheduler.scheduledMinute, 0);
    },
  );

  test(
    'a second send while the first is in flight creates only one plan',
    () async {
      final repository = _FakeRecordRepository()..createGate = Completer<void>();
      final container = _buildSaveContainer(repository);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

      final notifier = container.read(planCreateViewModelProvider.notifier);
      await notifier.dispatch(
        ApplyStudyTemplateIntent(
          studyPlanTemplatesFor(l10n).firstWhere((t) => t.id == 'walking'),
        ),
      );

      // The send button only pops the screen once the round-trip completes, so
      // an impatient user can land a second tap while the first is saving.
      final first = notifier.dispatch(const SavePlanIntent());
      final second = notifier.dispatch(const SavePlanIntent());
      repository.createGate!.complete();
      await Future.wait([first, second]);

      // Regression: both taps reached createPlan with existingPlanId still null,
      // writing two plans and sending the partner two approval requests.
      expect(repository.createPlanCalls, 1);
    },
  );

  test(
    'reset clears the id kept from the last save, so the next plan is new',
    () async {
      final repository = _FakeRecordRepository();
      final container = _buildSaveContainer(repository);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

      final notifier = container.read(planCreateViewModelProvider.notifier);
      await notifier.dispatch(
        ApplyStudyTemplateIntent(
          studyPlanTemplatesFor(l10n).firstWhere((t) => t.id == 'walking'),
        ),
      );
      await notifier.dispatch(const SavePlanIntent());
      expect(
        container.read(planCreateViewModelProvider).value!.existingPlanId,
        'study-plan-id',
      );

      // The provider outlives the screen, which resets it on open. Saving now
      // remembers the created id, so that reset is what stops the next new
      // promise from overwriting the one just created.
      await notifier.dispatch(const ResetIntent());

      expect(
        container.read(planCreateViewModelProvider).value!.existingPlanId,
        isNull,
      );
    },
  );

  test(
    'starting a follow-up plan from a finished one creates it, not overwrites',
    () async {
      final repository = _FakeRecordRepository();
      final container = _buildSaveContainer(repository);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

      final notifier = container.read(planCreateViewModelProvider.notifier);
      await notifier.dispatch(
        ApplyStudyTemplateIntent(
          studyPlanTemplatesFor(l10n).firstWhere((t) => t.id == 'walking'),
        ),
      );
      await notifier.dispatch(const SavePlanIntent());
      expect(repository.createPlanCalls, 1);

      // "Continue after settlement" pushes the plan-create screen with the old
      // plan copied as a *template* — same content, no id. That screen sees a
      // non-null planToEdit, so it initializes rather than resetting.
      final template = Plan(
        userId: 'user-1',
        startDate: DateTime(2026, 5, 3),
        endDate: DateTime(2026, 5, 31),
        state: PlanState.active,
        createdAt: DateTime(2026, 5, 3),
        items: [
          PlanItem(
            title: '30분 걷기',
            days: const [1, 3, 5],
            count: 3,
            notificationTime: NotificationTime.custom(21, 0),
          ),
        ],
      );
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
    },
  );

  test(
    'retrying after a failed save updates the plan instead of duplicating it',
    () async {
      final repository = _FakeRecordRepository();
      // Alarm scheduling runs after the plan document is already written.
      final scheduler = _FakePlanReminderScheduler()..failOnce = true;
      final container = _buildSaveContainer(repository, scheduler: scheduler);
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);
      await container.read(myProfileProvider.future);
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

      final notifier = container.read(planCreateViewModelProvider.notifier);
      await notifier.dispatch(
        ApplyStudyTemplateIntent(
          studyPlanTemplatesFor(l10n).firstWhere((t) => t.id == 'walking'),
        ),
      );

      await expectLater(
        notifier.dispatch(const SavePlanIntent()),
        throwsA(isA<Exception>()),
      );
      expect(repository.createPlanCalls, 1);

      // The user sees the error and taps send again.
      await notifier.dispatch(const SavePlanIntent());

      // Regression: the created id was never kept, so the retry wrote a second
      // plan rather than updating the one that already exists.
      expect(repository.createPlanCalls, 1);
      expect(repository.updatePlanCalls, 1);
    },
  );
}

ProviderContainer _buildSaveContainer(
  _FakeRecordRepository repository, {
  _FakePlanReminderScheduler? scheduler,
}) {
  return ProviderContainer(
    overrides: [
      recordRepositoryProvider.overrideWithValue(repository),
      settingAlarmUseCaseProvider.overrideWithValue(
        SettingAlarmUseCase(scheduler ?? _FakePlanReminderScheduler()),
      ),
      myProfileProvider.overrideWithValue(AsyncData(_buildUser())),
      connectedProfilesProvider.overrideWith((ref) async => <ConnectedUser>[]),
    ],
  );
}
