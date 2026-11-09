// Characterization tests for the 지금 tab's primary (my own) card in the
// states the other now-tab suites don't reach: no plan, a quiet day, a
// finished day (single + checklist), a rejected plan, a promise proposal, a
// settled promise, the 4-week pilot settlement and a later-today promise.
// Written before primary_executor_card.dart was split into part files so the
// split is checked against today's behaviour; they are not a spec.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/domain/usecases/get_now_cards_use_case.dart';
import 'package:nod_try/features/now/presentation/now_tab_screen.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/promise_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/widgets/reaction_icon.dart';

/// Status lines go through [ReactionText] (emoji drawn as icons).
Finder _reactionText(String text) =>
    find.byWidgetPredicate((w) => w is ReactionText && w.text == text);

class _FakeRecordRepository extends Fake implements RecordRepository {
  @override
  Future<List<String>> completeOverduePlans() async => const [];
}

class _FakeGetNowCards extends Fake implements GetNowCardsUseCase {
  _FakeGetNowCards(this.cards);

  final List<HomeCardModel> cards;

  @override
  Stream<List<HomeCardModel>> executeStream() => Stream.value(cards);
}

Plan _plan({
  String id = 'mine-1',
  String title = '아침 러닝',
  PlanState state = PlanState.active,
  List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  NotificationTime? time,
  List<DateTime> completedDates = const [],
  Promise? promise,
}) {
  final now = DateTime.now();
  return Plan(
    id: id,
    userId: 'me',
    startDate: now.subtract(const Duration(days: 28)),
    endDate: now.add(const Duration(days: 1)),
    state: state,
    createdAt: now.subtract(const Duration(days: 28)),
    completedDates: completedDates,
    promise: promise,
    items: [
      PlanItem(
        title: title,
        days: days,
        count: days.length,
        notificationTime: time ?? NotificationTime.custom(21, 0),
      ),
    ],
  );
}

Promise _promise(
  PromiseStatus status, {
  SettlementResult? result,
  int? success,
  int? fail,
}) {
  return Promise(
    status: status,
    proposerId: 'partner-uid',
    reward: PromiseReward(description: '치킨', targetDays: 2),
    penalty: PromisePenalty(description: '커피', targetDays: 5),
    proposedAt: DateTime.now().subtract(const Duration(days: 1)),
    settlementResult: result,
    settledSuccessDays: success,
    settledFailDays: fail,
  );
}

ConnectedUser _partner() {
  final now = DateTime.now();
  return ConnectedUser(
    user: UserModel(
      uid: 'partner-uid',
      displayName: 'Jimin',
      createdAt: now,
      updatedAt: now,
    ),
    isSupported: true,
    isCheering: true,
  );
}

Widget _wrap(List<HomeCardModel> cards) {
  return ProviderScope(
    overrides: [
      recordRepositoryProvider.overrideWithValue(_FakeRecordRepository()),
      getNowCardsUseCaseProvider.overrideWithValue(_FakeGetNowCards(cards)),
      connectedProfilesProvider.overrideWith((ref) async => [_partner()]),
    ],
    child: const MaterialApp(
      locale: Locale('ko'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: NowTab()),
    ),
  );
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  Future<void> pump(WidgetTester tester, List<HomeCardModel> cards) async {
    await tester.pumpWidget(_wrap(cards));
    await tester.pumpAndSettle();
  }

  testWidgets('no plan: asks for one with the create button', (tester) async {
    await pump(tester, const [HomeCardModel(state: HomeCardState.emptyPlan)]);

    expect(find.text(l10n.nowNoPlan), findsOneWidget);
    expect(find.text(l10n.nowNoPlanSubtitle), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, l10n.nowCreatePlan), findsOne);
  });

  testWidgets('a quiet day offers the small add-more link', (tester) async {
    await pump(tester, const [HomeCardModel(state: HomeCardState.todayEmpty)]);

    expect(find.text(l10n.nowQuietRest), findsOneWidget);
    expect(find.text(l10n.nowAddMorePlan), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('one finished promise reads as done today', (tester) async {
    final plan = _plan(completedDates: [DateTime.now()]);
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.todayComplete,
        plan: plan,
        completedPlans: [plan],
        streakCount: 3,
      ),
    ]);

    expect(find.text('아침 러닝'), findsOneWidget);
    expect(_reactionText(l10n.nowTodayDone), findsOneWidget);
    expect(find.text(l10n.nowStreakCount(3)), findsOneWidget);
    expect(find.text(l10n.nowAddMorePlan), findsOneWidget);
    expect(find.byKey(const ValueKey('now-hero-photo')), findsNothing);
  });

  testWidgets('two finished promises show the checklist with streaks', (
    tester,
  ) async {
    final today = DateTime.now();
    final a = _plan(id: 'a', title: '아침 러닝', completedDates: [today]);
    final b = _plan(
      id: 'b',
      title: '저녁 스쿼트',
      completedDates: [
        for (var i = 0; i < 4; i++) today.subtract(Duration(days: i)),
      ],
    );
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.todayComplete,
        plan: a,
        completedPlans: [a, b],
      ),
    ]);

    expect(find.text(l10n.nowTodayAllDone(2)), findsOneWidget);
    expect(find.text('아침 러닝'), findsOneWidget);
    expect(find.text('저녁 스쿼트'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(find.text('4'), findsOneWidget);
    expect(_reactionText(l10n.nowTodayDone), findsNothing);
  });

  testWidgets('a rejected plan asks to adjust it', (tester) async {
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.rejected,
        plan: _plan(state: PlanState.rejected),
      ),
    ]);

    expect(find.text(l10n.nowHeaderAdjustNeeded), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, l10n.nowModify), findsOne);
  });

  testWidgets('a proposed promise shows its terms with 거절/수락', (tester) async {
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.promiseProposed,
        plan: _plan(promise: _promise(PromiseStatus.proposed)),
      ),
    ]);

    expect(find.text(l10n.nowHeaderPromiseProposed), findsOneWidget);
    expect(find.text(l10n.nowRewardCondition(2, '치킨')), findsOneWidget);
    expect(find.text(l10n.nowPenaltyCondition(5, '커피')), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, l10n.nowDecline), findsOne);
    expect(find.widgetWithText(ElevatedButton, l10n.nowAccept), findsOne);
    // No result badges before settlement.
    expect(find.text(l10n.nowAchieved), findsNothing);
    expect(find.text(l10n.nowNotMet), findsNothing);
  });

  testWidgets('a settled promise shows badges, result and 확인 button', (
    tester,
  ) async {
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.promiseSettled,
        plan: _plan(
          promise: _promise(
            PromiseStatus.settled,
            result: SettlementResult.rewardAchieved,
            success: 6,
            fail: 1,
          ),
        ),
      ),
    ]);

    expect(find.text(l10n.nowHeaderPromiseSettled), findsOneWidget);
    expect(find.text(l10n.nowAchieved), findsOneWidget);
    expect(find.text(l10n.nowNotMet), findsOneWidget);
    expect(find.text(l10n.nowPromiseResult(6, 1)), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, l10n.nowPromiseAckButton),
      findsOne,
    );
  });

  testWidgets('the pilot settlement shows metrics and continue/stop', (
    tester,
  ) async {
    final today = DateTime.now();
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.pilotSettlement,
        plan: _plan(
          promise: _promise(PromiseStatus.active),
          completedDates: [
            today.subtract(const Duration(days: 1)),
            today.subtract(const Duration(days: 2)),
            today.subtract(const Duration(days: 3)),
          ],
        ),
      ),
    ]);

    expect(find.text(l10n.nowHeaderSettlementNeeded), findsOneWidget);
    expect(find.text(l10n.nowHeaderSettlementSub), findsOneWidget);
    expect(find.text(l10n.nowMetricCompleted), findsOneWidget);
    expect(find.text(l10n.nowMetricPartnerReact), findsOneWidget);
    expect(find.text(l10n.nowMetricMissed), findsOneWidget);
    expect(find.text(l10n.nowMetricDaysSuffix(3)), findsOneWidget);
    expect(find.text(l10n.nowSettlementWinMessage), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, l10n.nowContinueNext4Weeks),
      findsOne,
    );
    expect(find.text(l10n.nowStopHere), findsOneWidget);
  });

  testWidgets('a promise not due today offers the soft 미리 하기 button', (
    tester,
  ) async {
    final notToday = [1, 2, 3, 4, 5, 6, 7]..remove(DateTime.now().weekday);
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.nextAction,
        plan: _plan(days: notToday),
      ),
    ]);

    expect(find.text(l10n.nowNextActionLater), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, l10n.nowDoEarly), findsOne);
    expect(find.byKey(const ValueKey('now-hero-question')), findsNothing);
  });

  testWidgets('a promise with no reminder time can be done anytime', (
    tester,
  ) async {
    final notToday = [1, 2, 3, 4, 5, 6, 7]..remove(DateTime.now().weekday);
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.nextAction,
        plan: _plan(
          days: notToday,
          time: NotificationTime(type: 'none', value: '', hour: 0, minute: 0),
        ),
      ),
    ]);

    expect(find.text(l10n.nowNextActionAnytime), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, l10n.nowDoAnytime), findsOne);
  });

  testWidgets('the card\'s X opens the defer sheet: later / rest / skip', (
    tester,
  ) async {
    await pump(tester, [
      HomeCardModel(state: HomeCardState.nowAction, plan: _plan()),
    ]);

    await tester.tap(find.byTooltip(l10n.nowDeferMenuTooltip));
    await tester.pumpAndSettle();

    expect(find.text(l10n.nowDeferLaterTitle), findsOneWidget);
    expect(find.text(l10n.nowDeferLaterSubtitle), findsOneWidget);
    expect(find.byKey(const ValueKey('defer-skip')), findsOneWidget);
    expect(find.text(l10n.nowSkipTodayTitle), findsOneWidget);
    // A fresh plan still has its rest pass, offered before skipping.
    expect(find.byKey(const ValueKey('defer-rest')), findsOneWidget);
    expect(find.text(l10n.nowDeferRestSubtitle), findsOneWidget);
  });

  testWidgets('조정하기 on a partner proposal asks why, 취소 closes', (tester) async {
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.partnerPlanCreate,
        plan: _plan(
          state: PlanState.pendingApproval,
        ).copyWith(userId: 'partner-uid', managerId: 'me'),
        partnerUid: 'partner-uid',
      ),
    ]);

    await tester.tap(find.text(l10n.nowAdjust));
    await tester.pumpAndSettle();

    expect(find.text(l10n.nowRejectDialogTitle), findsOneWidget);
    expect(find.text(l10n.nowRejectLessFrequent), findsOneWidget);
    expect(find.text(l10n.nowRejectDifferentTime), findsOneWidget);
    expect(find.text(l10n.nowRejectCustom), findsOneWidget);

    await tester.tap(find.text(l10n.nowCancel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.nowRejectDialogTitle), findsNothing);
  });

  testWidgets('그만하기 after the pilot asks for a reason first', (tester) async {
    await pump(tester, [
      HomeCardModel(
        state: HomeCardState.pilotSettlement,
        plan: _plan(promise: _promise(PromiseStatus.active)),
      ),
    ]);

    await tester.tap(find.text(l10n.nowStopHere));
    await tester.pumpAndSettle();

    expect(find.text(l10n.nowExitDialogTitle), findsOneWidget);
    expect(find.text(l10n.nowExitReasonWeakPoke), findsOneWidget);
    expect(find.text(l10n.nowExitReasonTooBig), findsOneWidget);
    expect(find.text(l10n.nowExitReasonPartnerBurden), findsOneWidget);
    expect(find.text(l10n.nowExitReasonCustomLabel), findsOneWidget);

    await tester.tap(find.text(l10n.nowCancel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.nowExitDialogTitle), findsNothing);
    // Still on the settlement card: nothing was recorded.
    expect(find.text(l10n.nowContinueNext4Weeks), findsOneWidget);
  });
}
