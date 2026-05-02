import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nod_try/features/now/presentation/now_tab_viewmodel.dart';
import 'package:nod_try/features/now/presentation/now_tab_intent.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/features/now/presentation/now_tab_state.dart';

import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/features/now/domain/usecases/get_now_cards_use_case.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/services/notification_service.dart';
import 'dart:async';

class MockRecordRepository extends Fake implements RecordRepository {
  int reportCompletionCallCount = 0;
  String? lastReportedPlanId;
  int reportSkipCallCount = 0;
  String? lastSkippedPlanId;
  int cheerPartnerCallCount = 0;
  String? lastCheeredPlanId;
  int passPlanCallCount = 0;
  String? lastPassedPlanId;
  int rejectPlanCallCount = 0;
  String? lastRejectedPlanId;

  // Stream Controller for testing real-time updates
  final _controller = StreamController<List<HomeCardModel>>.broadcast();
  List<HomeCardModel> _currentValue = [];

  void emit(List<HomeCardModel> data) {
    _currentValue = data;
    _controller.add(data);
  }

  @override
  Future<void> reportCompletion(String planId, {String? note}) async {
    reportCompletionCallCount++;
    lastReportedPlanId = planId;
    emit(_currentValue); // Emit current (or updated) value to trigger stream
  }

  @override
  Future<void> reportSkip(String planId) async {
    reportSkipCallCount++;
    lastSkippedPlanId = planId;
    emit(_currentValue);
  }

  @override
  Future<void> cheerPartner(
    String planId,
    String reactionType, {
    String? message,
  }) async {
    cheerPartnerCallCount++;
    lastCheeredPlanId = planId;
    emit(_currentValue);
  }

  @override
  Future<void> passPlan(String planId) async {
    passPlanCallCount++;
    lastPassedPlanId = planId;
    emit(_currentValue);
  }

  @override
  Future<void> rejectPlan(String planId, {String? reason}) async {
    rejectPlanCallCount++;
    lastRejectedPlanId = planId;
    emit(_currentValue);
  }

  @override
  Future<List<HomeCardModel>> getHomeCardStates() => Future.value([]);

  @override
  Stream<List<HomeCardModel>> getHomeCardStatesStream() async* {
    yield _currentValue;
    yield* _controller.stream;
  }

  @override
  Future<List<HistoryItem>> getHistoryItems() => Future.value([]);
  @override
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds}) =>
      Stream.value([]);

  @override
  Future<List<Plan>> getPlansByUserId(String userId) => Future.value([]);
  @override
  Stream<List<Plan>> getPlansByUserIdStream(String userId) => Stream.value([]);

  @override
  Future<String> createPlan(Plan plan) => Future.value('mock-id');
  @override
  Future<void> updatePlan(Plan plan) => Future.value();
  @override
  Future<void> deletePlan(String planId) => Future.value();
  @override
  Future<void> deletePlansByUserId(String uid) => Future.value();

  @override
  Future<void> reconcilePlan(String planId, HistoryStatus status) =>
      Future.value();
  @override
  Future<void> verifyHistoryItem(String historyId, {String? message}) =>
      Future.value();
  @override
  Future<void> reconcileHistoryItem(String historyId, HistoryStatus status) =>
      Future.value();

  @override
  Future<void> assignManagerToActivePlans(String managerId) => Future.value();
  @override
  Future<void> approvePlan(String planId) => Future.value();
  @override
  Future<void> verifyPlan(String planId) => Future.value();
  @override
  Future<List<String>> completeOverduePlans() => Future.value(const []);
}

class MockGetNowCardsUseCase extends Fake implements GetNowCardsUseCase {
  int executeCallCount = 0;
  final _controller = StreamController<List<HomeCardModel>>.broadcast();
  List<HomeCardModel> _currentValue = [];

  void emit(List<HomeCardModel> data) {
    _currentValue = data;
    _controller.add(data);
  }

  @override
  Future<List<HomeCardModel>> execute() async {
    return [];
  }

  @override
  Stream<List<HomeCardModel>> executeStream() async* {
    executeCallCount++;
    yield _currentValue;
    yield* _controller.stream;
  }
}

class FakePlanReminderScheduler implements PlanReminderScheduler {
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
  }) async {}
}

void main() {
  late MockRecordRepository mockRecordRepository;
  late MockGetNowCardsUseCase mockGetNowCardsUseCase;
  late ProviderContainer container;

  setUp(() {
    mockRecordRepository = MockRecordRepository();
    mockGetNowCardsUseCase = MockGetNowCardsUseCase();
    container = ProviderContainer(
      overrides: [
        recordRepositoryProvider.overrideWithValue(mockRecordRepository),
        getNowCardsUseCaseProvider.overrideWithValue(mockGetNowCardsUseCase),
        settingAlarmUseCaseProvider.overrideWithValue(
          SettingAlarmUseCase(FakePlanReminderScheduler()),
        ),
        connectedProfilesProvider.overrideWith(
          (ref) async => <ConnectedUser>[],
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<NowTabState> readNowState() async {
    final completer = Completer<NowTabState>();
    final subscription = container.listen(nowTabViewModelProvider, (_, next) {
      if (next.hasValue && !completer.isCompleted) {
        completer.complete(next.value!);
      } else if (next.hasError && !completer.isCompleted) {
        completer.completeError(next.error!, next.stackTrace);
      }
    }, fireImmediately: true);
    addTearDown(subscription.close);
    return completer.future.timeout(const Duration(seconds: 5));
  }

  test('Initial state should be loading then data', () async {
    // Arrange
    final state = NowTabState(
      allCards: [],
      primaryCard: const HomeCardModel(state: HomeCardState.todayEmpty),
      secondaryCards: [],
      managerCards: const [],
    );
    final expectedCards = [state.primaryCard!];
    mockGetNowCardsUseCase.emit(expectedCards); // Pre-set value

    // Act
    final result = await readNowState();

    // Assert
    expect(result.allCards, expectedCards);
    expect(mockGetNowCardsUseCase.executeCallCount, greaterThanOrEqualTo(1));
  });

  test('CompletePlanIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await readNowState();
    mockRecordRepository.reportCompletionCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CompletePlanIntent('plan-123'));

    expect(mockRecordRepository.reportCompletionCallCount, 1);
    expect(mockRecordRepository.lastReportedPlanId, 'plan-123');
  });

  test('CheckPartnerActionIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await readNowState();
    mockRecordRepository.reportCompletionCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CheckPartnerActionIntent('plan-456'));

    expect(mockRecordRepository.reportCompletionCallCount, 1);
    expect(mockRecordRepository.lastReportedPlanId, 'plan-456');
  });

  test('CheerPartnerActionIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await readNowState();
    mockRecordRepository.cheerPartnerCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const CheerPartnerActionIntent('plan-cheer', 'fire'));

    expect(mockRecordRepository.cheerPartnerCallCount, 1);
    expect(mockRecordRepository.lastCheeredPlanId, 'plan-cheer');
  });

  test('PassPlanIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await readNowState();
    mockRecordRepository.passPlanCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const PassPlanIntent('plan-pass'));

    expect(mockRecordRepository.passPlanCallCount, 1);
    expect(mockRecordRepository.lastPassedPlanId, 'plan-pass');
  });

  test('RefreshIntent should re-subscribe to stream', () async {
    mockGetNowCardsUseCase.emit([]);
    await readNowState();
    mockGetNowCardsUseCase.executeCallCount = 0; // Reset

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const RefreshIntent());

    // Invalidate re-triggers build, which calls executeStream
    // We wait for microtask cycle
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    await container.pump();

    expect(mockGetNowCardsUseCase.executeCallCount, greaterThanOrEqualTo(1));
  });

  test('SkipPlanIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await readNowState();
    mockRecordRepository.reportSkipCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(const SkipPlanIntent('plan-skip-123'));

    expect(mockRecordRepository.reportSkipCallCount, 1);
    expect(mockRecordRepository.lastSkippedPlanId, 'plan-skip-123');
  });

  test('RejectPlanIntent should call repository', () async {
    mockGetNowCardsUseCase.emit([]);
    await readNowState();
    mockRecordRepository.rejectPlanCallCount = 0;

    await container
        .read(nowTabViewModelProvider.notifier)
        .dispatch(
          const RejectPlanIntent('plan-reject-123', reason: 'Too frequent'),
        );

    expect(mockRecordRepository.rejectPlanCallCount, 1);
    expect(mockRecordRepository.lastRejectedPlanId, 'plan-reject-123');
  });
}
