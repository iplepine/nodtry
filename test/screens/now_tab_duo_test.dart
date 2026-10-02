import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/features/now/application/poke_reply_store.dart';
import 'package:nod_try/features/now/domain/usecases/get_now_cards_use_case.dart';
import 'package:nod_try/features/now/presentation/now_tab_screen.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/services/notification_service.dart';
import 'package:nod_try/widgets/quiet_header.dart';

class _Records extends Fake implements RecordRepository {
  final replies = <({String planId, String to, String message})>[];
  final cheers =
      <({String to, String? planId, String emoji, String? message})>[];
  final verifications = <String>[];
  final knocks = <String>[];

  @override
  Future<List<String>> completeOverduePlans() async => const [];

  @override
  Future<void> replyToPoke(
    String planId, {
    required String toUserId,
    required String message,
  }) async {
    replies.add((planId: planId, to: toUserId, message: message));
  }

  @override
  Future<void> sendCheer(
    String toUserId, {
    String? planId,
    required String emoji,
    String? message,
  }) async {
    cheers.add((to: toUserId, planId: planId, emoji: emoji, message: message));
  }

  @override
  Future<void> cheerPartner(
    String planId,
    String reactionType, {
    String? message,
  }) async {
    verifications.add(planId);
  }

  @override
  Future<void> pokePartner(String planId, {String? message}) async {
    knocks.add(planId);
  }

  @override
  Future<void> acknowledgePoke(String planId) async {}
}

class _Cards extends Fake implements GetNowCardsUseCase {
  _Cards(this.cards);
  final List<HomeCardModel> cards;

  @override
  Stream<List<HomeCardModel>> executeStream() => Stream.value(cards);
}

class _Scheduler implements PlanReminderScheduler {
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

Plan _plan({
  String id = 'plan-1',
  String userId = 'me',
  String? managerId = 'partner-uid',
  DateTime? lastPokeAt,
  List<DateTime> completedDates = const [],
}) {
  final now = DateTime.now();
  return Plan(
    id: id,
    userId: userId,
    managerId: managerId,
    startDate: now.subtract(const Duration(days: 3)),
    endDate: now.add(const Duration(days: 20)),
    state: PlanState.active,
    createdAt: now.subtract(const Duration(days: 3)),
    workoutType: 'running',
    lastPokeAt: lastPokeAt,
    completedDates: completedDates,
    items: [
      PlanItem(
        title: '러닝 30분',
        days: const [1, 2, 3, 4, 5, 6, 7],
        count: 7,
        notificationTime: NotificationTime.custom(23, 0),
      ),
    ],
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

DuoStats _stats({required bool duoToday, int streak = 5}) {
  final today = DateTime.now();
  final date = DateTime(today.year, today.month, today.day);
  final day = DuoDay(
    date: date,
    me: const DuoPersonDay(
      status: DuoDayStatus.done,
      verification: DuoVerification.waiting,
    ),
    partner: DuoPersonDay(
      status: duoToday ? DuoDayStatus.done : DuoDayStatus.pending,
    ),
    isToday: true,
  );
  final monday = DateTime(date.year, date.month, date.day - (date.weekday - 1));
  return DuoStats(
    streak: streak,
    streakStart: date,
    today: day,
    week: [
      for (var i = 0; i < 7; i++)
        DateTime(monday.year, monday.month, monday.day + i) == date
            ? day
            : DuoDay(
                date: DateTime(monday.year, monday.month, monday.day + i),
                me: DuoPersonDay.off,
                partner: DuoPersonDay.off,
                isToday: false,
              ),
    ],
    hasPartner: true,
  );
}

Widget _wrap(
  List<HomeCardModel> cards, {
  required _Records records,
  DuoStats? stats,
  PokeReplyStore? replyStore,
  Locale locale = const Locale('ko'),
}) {
  return ProviderScope(
    overrides: [
      recordRepositoryProvider.overrideWithValue(records),
      getNowCardsUseCaseProvider.overrideWithValue(_Cards(cards)),
      settingAlarmUseCaseProvider.overrideWithValue(
        SettingAlarmUseCase(_Scheduler()),
      ),
      connectedProfilesProvider.overrideWith((ref) async => [_partner()]),
      duoStatsProvider.overrideWith((ref) => stats),
      pokeReplyStoreProvider.overrideWithValue(replyStore ?? PokeReplyStore()),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: NowTab()),
    ),
  );
}

void main() {
  group('duo header', () {
    testWidgets('shows the streak and today for both of us', (tester) async {
      await tester.pumpWidget(
        _wrap(
          [HomeCardModel(state: HomeCardState.nextAction, plan: _plan())],
          records: _Records(),
          stats: _stats(duoToday: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('duo-header')), findsOneWidget);
      expect(find.byType(QuietHeader), findsNothing);
      expect(find.text('둘이 함께 5일째'), findsOneWidget);
      expect(find.text('나 인정 대기'), findsOneWidget);
      expect(find.text('Jimin 아직'), findsOneWidget);
    });

    testWidgets('celebrates once today is a duo day', (tester) async {
      await tester.pumpWidget(
        _wrap(
          [HomeCardModel(state: HomeCardState.nextAction, plan: _plan())],
          records: _Records(),
          stats: _stats(duoToday: true, streak: 6),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('둘이 함께 6일째'), findsOneWidget);
      expect(find.text('오늘 둘운완이에요 🎉'), findsOneWidget);
    });

    testWidgets('streak 0 nudges toward day one (en)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          [HomeCardModel(state: HomeCardState.nextAction, plan: _plan())],
          records: _Records(),
          stats: _stats(duoToday: false, streak: 0),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Both check in today for day 1'), findsOneWidget);
    });

    testWidgets('without stats the quiet header stays', (tester) async {
      await tester.pumpWidget(
        _wrap([
          HomeCardModel(state: HomeCardState.nextAction, plan: _plan()),
        ], records: _Records()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QuietHeader), findsOneWidget);
      expect(find.byKey(const ValueKey('duo-header')), findsNothing);
    });
  });

  group('knock replies', () {
    testWidgets('a knock today offers 지금 간다 / 오늘은 봐줘', (tester) async {
      final records = _Records();
      await tester.pumpWidget(
        _wrap([
          HomeCardModel(
            state: HomeCardState.nextAction,
            plan: _plan(lastPokeAt: DateTime.now()),
            partnerName: 'Jimin',
          ),
        ], records: records),
      );
      await tester.pumpAndSettle();

      expect(find.text('지금 간다 🏃'), findsOneWidget);
      expect(find.text('오늘은 봐줘 🙏'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('poke-reply-coming')));
      await tester.pumpAndSettle();

      expect(records.replies, hasLength(1));
      expect(records.replies.single.planId, 'plan-1');
      expect(records.replies.single.to, 'partner-uid');
      expect(records.replies.single.message, '지금 간다 🏃');
      expect(find.text('답장 보냈어요'), findsOneWidget);
      // One reply per knock: the buttons are gone.
      expect(find.byKey(const ValueKey('poke-reply-coming')), findsNothing);
      expect(find.byKey(const ValueKey('poke-reply-pass')), findsNothing);
    });

    testWidgets('오늘은 봐줘 sends the pass reply', (tester) async {
      final records = _Records();
      await tester.pumpWidget(
        _wrap([
          HomeCardModel(
            state: HomeCardState.poked,
            plan: _plan(lastPokeAt: DateTime.now()),
          ),
        ], records: records),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('poke-reply-pass')));
      await tester.pumpAndSettle();
      expect(records.replies.single.message, '오늘은 봐줘 🙏');
    });

    testWidgets('no replies without a knock today, or once answered', (
      tester,
    ) async {
      final store = PokeReplyStore();
      await store.markReplied('plan-1', DateTime.now());
      await tester.pumpWidget(
        _wrap(
          [
            HomeCardModel(
              state: HomeCardState.nextAction,
              plan: _plan(lastPokeAt: DateTime.now()),
            ),
          ],
          records: _Records(),
          replyStore: store,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('poke-reply-coming')), findsNothing);

      await tester.pumpWidget(
        _wrap([
          HomeCardModel(
            state: HomeCardState.nextAction,
            plan: _plan(
              lastPokeAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ),
        ], records: _Records()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('poke-reply-coming')), findsNothing);
    });
  });

  group('partner missed-workout card', () {
    HomeCardModel missed({required bool notice, DateTime? lastPokeAt}) =>
        HomeCardModel(
          state: HomeCardState.partnerPoke,
          plan: _plan(
            userId: 'partner-uid',
            managerId: 'me',
            lastPokeAt: lastPokeAt,
          ),
          partnerUid: 'partner-uid',
          partnerName: 'Jimin',
          hasMissedNotice: notice,
        );

    testWidgets('leads with 응원 보내기 and keeps 똑똑 second', (tester) async {
      final records = _Records();
      await tester.pumpWidget(_wrap([missed(notice: true)], records: records));
      await tester.pumpAndSettle();

      final cheer = find.byKey(const ValueKey('partner-cheer'));
      final knock = find.byKey(const ValueKey('partner-knock'));
      expect(tester.widget(cheer), isA<ElevatedButton>());
      expect(tester.widget(knock), isA<OutlinedButton>());
      expect(
        tester.getTopLeft(cheer).dy,
        lessThan(tester.getTopLeft(knock).dy),
      );
      expect(find.text('응원 보내기'), findsOneWidget);
      expect(find.text('똑똑 보내기'), findsOneWidget);

      await tester.tap(cheer);
      await tester.pumpAndSettle();

      expect(records.cheers, hasLength(1));
      expect(records.cheers.single.to, 'partner-uid');
      expect(records.cheers.single.planId, 'plan-1');
      expect(records.cheers.single.emoji, '💪');
      expect(records.cheers.single.message, '할 수 있어! 기다릴게 💪');
      // Encouragement is not 인정.
      expect(records.verifications, isEmpty);
      expect(
        tester.widget<ElevatedButton>(cheer).onPressed,
        isNull,
        reason: 'one cheer from this card',
      );
      expect(find.text('응원을 보냈어요'), findsWidgets);
      // 똑똑 is still available once.
      expect(tester.widget<OutlinedButton>(knock).onPressed, isNotNull);
    });

    testWidgets('without a forwarded miss 똑똑 stays the action', (tester) async {
      await tester.pumpWidget(
        _wrap([missed(notice: false)], records: _Records()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('partner-cheer')), findsNothing);
      expect(
        tester.widget(find.byKey(const ValueKey('partner-knock'))),
        isA<ElevatedButton>(),
      );
    });

    testWidgets('똑똑 is off after one knock today', (tester) async {
      final records = _Records();
      await tester.pumpWidget(
        _wrap([
          missed(notice: true, lastPokeAt: DateTime.now()),
        ], records: records),
      );
      await tester.pumpAndSettle();

      final knock = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('partner-knock')),
      );
      expect(knock.onPressed, isNull);
      expect(find.text('오늘 똑똑 보냈어요'), findsOneWidget);
    });
  });
}
