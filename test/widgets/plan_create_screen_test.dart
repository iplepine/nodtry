import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/features/plan/domain/workout_template.dart';
import 'package:nod_try/features/plan/presentation/plan_create_state.dart';
import 'package:nod_try/features/plan/presentation/screens/plan_create_screen.dart';
import 'package:nod_try/features/plan/presentation/viewmodel/plan_create_viewmodel.dart';
import 'package:nod_try/l10n/app_localizations.dart';
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
  Plan? updatedPlan;

  @override
  Future<String> createPlan(Plan plan) async {
    createdPlan = plan;
    return 'new-plan-id';
  }

  @override
  Future<void> updatePlan(Plan plan) async {
    updatedPlan = plan;
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
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds}) {
    return Stream.value([]);
  }
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
  }) async {}
}

final _now = DateTime(2026, 5, 3);

UserModel _user(String uid, {String? name, String? nickname}) => UserModel(
  uid: uid,
  displayName: name,
  partnerNickname: nickname,
  createdAt: _now,
  updatedAt: _now,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeRecordRepository repository,
  Locale locale = const Locale('ko'),
  String? partnerName,
  String? nickname,
  Plan? planToEdit,
}) async {
  // A phone-sized viewport, so the layout is checked at real width.
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/create', extra: planToEdit),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) =>
            PlanCreateScreen(planToEdit: state.extra as Plan?),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recordRepositoryProvider.overrideWithValue(repository),
        settingAlarmUseCaseProvider.overrideWithValue(
          SettingAlarmUseCase(_NoopScheduler()),
        ),
        myProfileProvider.overrideWithValue(
          AsyncData(_user('user-1', nickname: nickname)),
        ),
        connectedProfilesProvider.overrideWith(
          (ref) async => [
            if (partnerName != null)
              ConnectedUser(
                user: _user('partner-1', name: partnerName),
                isSupported: true,
                isCheering: true,
              ),
          ],
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows every workout tile, days and deadline on one screen', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      repository: _FakeRecordRepository(),
      partnerName: '지민',
    );

    expect(find.text('지민한테 어떤 운동을 약속할까요?'), findsOneWidget);
    for (final type in WorkoutType.values) {
      expect(find.byKey(ValueKey('workout-tile-${type.id}')), findsOneWidget);
    }
    expect(find.text('헬스'), findsOneWidget);
    expect(find.text('식단·야식 참기'), findsOneWidget);
    expect(find.text('직접 입력'), findsOneWidget);
    for (final label in ['아침 7시', '점심 12시', '저녁 7시', '밤 9시', '밤 10시', '직접']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final day in ['월', '화', '수', '목', '금', '토', '일']) {
      expect(find.text(day), findsOneWidget, reason: day);
    }
    // No step header, no "turn the alarm off" or hourly mode in creation.
    expect(find.textContaining('1/3'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(PageView), findsNothing);

    // Sticky CTA uses the particle helper: 지민 ends in a consonant → 이랑.
    expect(find.text('🤙 지민이랑 손가락 걸기'), findsOneWidget);
    expect(find.text('못 하면 지민한테 알려져요'), findsOneWidget);
    expect(find.textContaining('님'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tile + pinky promise creates an active plan for the partner', (
    tester,
  ) async {
    final repository = _FakeRecordRepository();
    await _pumpScreen(tester, repository: repository, partnerName: '자기');

    // 자기 ends in a vowel → 랑.
    expect(find.text('🤙 자기랑 손가락 걸기'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const ValueKey('workout-tile-gym')));
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('plan-action-field')),
    );
    expect(field.controller!.text, '헬스장 가서 운동하기');

    await _tapVisible(tester, find.text('아침 7시'));
    await tester.tap(find.byKey(const ValueKey('plan-create-cta')));
    await tester.pumpAndSettle();

    final plan = repository.createdPlan!;
    expect(plan.state, PlanState.active);
    expect(plan.managerId, 'partner-1');
    expect(plan.workoutType, 'gym');
    expect(plan.items.single.title, '헬스장 가서 운동하기');
    expect(plan.items.single.notificationTime?.hour, 7);
    expect(find.text('자기한테 운동 약속을 걸었어요 🤙'), findsOneWidget);
    // Popped back to the previous screen.
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('my nickname for the partner wins over their name', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      repository: _FakeRecordRepository(),
      partnerName: '김지민',
      nickname: '여보',
    );

    expect(find.text('여보한테 어떤 운동을 약속할까요?'), findsOneWidget);
    expect(find.text('🤙 여보랑 손가락 걸기'), findsOneWidget);
    expect(find.text('못 하면 여보한테 알려져요'), findsOneWidget);
    expect(find.textContaining('김지민'), findsNothing);
  });

  testWidgets('solo: start button, connect card and a solo snackbar', (
    tester,
  ) async {
    final repository = _FakeRecordRepository();
    await _pumpScreen(tester, repository: repository);

    expect(find.text('어떤 운동을 약속할까요?'), findsOneWidget);
    expect(find.text('약속 시작하기'), findsOneWidget);
    expect(find.textContaining('알려져요'), findsNothing);
    expect(find.text('짝꿍 연결하기'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('workout-tile-walking')),
    );
    await tester.tap(find.byKey(const ValueKey('plan-create-cta')));
    await tester.pumpAndSettle();

    expect(repository.createdPlan!.managerId, isNull);
    expect(repository.createdPlan!.state, PlanState.active);
    expect(find.text('운동 약속을 시작했어요 💪'), findsOneWidget);
  });

  testWidgets('says what is missing instead of saving', (tester) async {
    final repository = _FakeRecordRepository();
    await _pumpScreen(tester, repository: repository, partnerName: '지민');

    await tester.tap(find.byKey(const ValueKey('plan-create-cta')));
    await tester.pump();
    expect(find.text('어떤 운동을 할지 알려 주세요!'), findsOneWidget);
    expect(repository.createdPlan, isNull);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('workout-tile-hiking')),
    );
    // Hiking is Saturday only; un-pick it.
    await _tapVisible(tester, find.byKey(const ValueKey('weekday-5')));
    expect(find.text('하루 이상 골라 주세요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('plan-create-cta')));
    await tester.pump();
    expect(find.text('하루 이상 골라 주세요'), findsNWidgets(2));
    expect(repository.createdPlan, isNull);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('editing restores the plan and keeps it running', (tester) async {
    final repository = _FakeRecordRepository();
    final plan = Plan(
      id: 'plan-1',
      userId: 'user-1',
      managerId: 'partner-1',
      startDate: DateTime(2026, 4, 20),
      endDate: DateTime(2026, 5, 17, 23, 59, 59),
      state: PlanState.active,
      createdAt: DateTime(2026, 4, 20),
      workoutType: 'running',
      items: [
        PlanItem(
          title: '한강 5km',
          days: const [2, 4],
          count: 2,
          notificationTime: NotificationTime.custom(20, 30),
          description: '비 오면 러닝머신',
        ),
      ],
    );
    await _pumpScreen(
      tester,
      repository: repository,
      partnerName: '지민',
      planToEdit: plan,
    );

    expect(find.text('약속 수정하기'), findsOneWidget);
    expect(find.text('저장하기'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('plan-action-field')),
    );
    expect(field.controller!.text, '한강 5km');
    // The memo is open because the plan has one.
    expect(find.text('비 오면 러닝머신'), findsOneWidget);
    // 20:30 is not a preset, so the custom chip shows the time.
    expect(find.text('오후 8시 30분'), findsOneWidget);
    bool tileSelected(String id) => tester
        .widget<Semantics>(
          find
              .descendant(
                of: find.byKey(ValueKey('workout-tile-$id')),
                matching: find.byType(Semantics),
              )
              .first,
        )
        .properties
        .selected!;
    expect(tileSelected('running'), isTrue);
    expect(tileSelected('gym'), isFalse);

    await tester.tap(find.byKey(const ValueKey('plan-create-cta')));
    await tester.pumpAndSettle();

    final saved = repository.updatedPlan!;
    expect(saved.id, 'plan-1');
    expect(saved.state, PlanState.active);
    expect(saved.startDate, plan.startDate);
    expect(saved.workoutType, 'running');
    expect(saved.lastUpdatedBy, 'user-1');
    expect(find.text('약속을 수정했어요'), findsOneWidget);
  });

  testWidgets('English copy has no Korean particles', (tester) async {
    await _pumpScreen(
      tester,
      repository: _FakeRecordRepository(),
      locale: const Locale('en'),
      partnerName: 'Jimin',
    );

    expect(find.text('🤙 Pinky promise with Jimin'), findsOneWidget);
    expect(find.text('Miss it and Jimin will know'), findsOneWidget);
    expect(find.text('Which workout will you promise Jimin?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the save error type stays exported for the screen', () {
    expect(
      const PlanCreateIncompleteException(PlanCreateMissing.days).missing,
      PlanCreateMissing.days,
    );
  });
}
