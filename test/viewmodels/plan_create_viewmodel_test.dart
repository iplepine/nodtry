import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/study_plan_template.dart';
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

class _FakeRecordRepository extends Fake implements RecordRepository {
  Plan? createdPlan;

  @override
  Future<String> createPlan(Plan plan) async {
    createdPlan = plan;
    return 'study-plan-id';
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

  @override
  Future<void> cancelPlanReminders(int planId) async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> schedulePlanReminder({
    required int planId,
    required String title,
    required int hour,
    required int minute,
    required List<int> days,
    bool skipToday = false,
  }) async {
    scheduledDays = days;
    scheduledHour = hour;
    scheduledMinute = minute;
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
  });

  test(
    'apply study template fills action, description, days, and reminder',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(planCreateViewModelProvider.future);

      final template = studyPlanTemplates.firstWhere(
        (template) => template.id == 'english_sentences',
      );

      await container
          .read(planCreateViewModelProvider.notifier)
          .dispatch(ApplyStudyTemplateIntent(template));

      final state = container.read(planCreateViewModelProvider).value!;
      expect(state.selectedTemplateId, 'english_sentences');
      expect(state.action, '영어 문장 10개 소리내어 읽기');
      expect(state.description, contains('영어'));
      expect(state.selectedDays, {0, 1, 2, 3, 4});
      expect(state.notificationTime.hour, 21);
      expect(state.notificationTime.minute, 0);
    },
  );

  test('manual edits clear the selected template marker', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(planCreateViewModelProvider.future);

    final template = studyPlanTemplates.first;
    await container
        .read(planCreateViewModelProvider.notifier)
        .dispatch(ApplyStudyTemplateIntent(template));
    await container
        .read(planCreateViewModelProvider.notifier)
        .dispatch(const UpdateActionIntent('내 방식으로 바꾼 공부'));

    final state = container.read(planCreateViewModelProvider).value!;
    expect(state.action, '내 방식으로 바꾼 공부');
    expect(state.selectedTemplateId, isNull);
  });

  test(
    'save creates a 28-day pending study plan with sorted week days',
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
      await container.read(myProfileProvider.future);

      final template = studyPlanTemplates.firstWhere(
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
      expect(plan.state, PlanState.pendingApproval);
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
}
