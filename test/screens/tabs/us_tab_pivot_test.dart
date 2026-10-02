import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/features/duo/presentation/duo_share_card.dart';
import 'package:nod_try/features/us/presentation/screens/us_screen.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/plan_list_provider.dart';
import 'package:nod_try/providers/repository_provider.dart';

UserModel _user(String uid, String name) {
  final now = DateTime.now();
  return UserModel(uid: uid, displayName: name, createdAt: now, updatedAt: now);
}

Plan _plan(String id, String title, String userId) {
  final now = DateTime.now();
  return Plan(
    id: id,
    userId: userId,
    startDate: now,
    endDate: now.add(const Duration(days: 7)),
    state: PlanState.active,
    createdAt: now,
    items: [
      PlanItem(
        title: title,
        days: const [1, 2, 3],
        count: 3,
        notificationTime: NotificationTime.custom(9, 0),
      ),
    ],
  );
}

Future<void> _pumpUs(
  WidgetTester tester, {
  required ConnectedUser partner,
  String? nickname,
  DuoStats? stats,
}) async {
  final profile = StreamController<UserModel?>();
  addTearDown(profile.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myProfileProvider.overrideWith((ref) => profile.stream),
        connectedProfilesProvider.overrideWith((ref) async => [partner]),
        activePlansProvider('me').overrideWith((ref) => Stream.value([])),
        activePlansProvider(partner.user.uid).overrideWith(
          (ref) =>
              Stream.value([_plan('p-partner', '파트너 운동 약속', partner.user.uid)]),
        ),
        duoStatsProvider.overrideWith((ref) => stats),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('ko')],
        locale: Locale('ko'),
        home: Scaffold(body: UsScreen()),
      ),
    ),
  );
  await tester.pump();
  final now = DateTime.now();
  profile.add(
    UserModel(
      uid: 'me',
      displayName: '나',
      partnerNickname: nickname,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('one-way relation badges are not shown', (tester) async {
    await _pumpUs(
      tester,
      partner: ConnectedUser(
        user: _user('partner', '짝꿍'),
        isSupported: true,
        isCheering: false,
      ),
    );

    expect(find.text('파트너 운동 약속'), findsOneWidget);
    // The one-way badges' copy keys were deleted with the badges; their old
    // labels must not come back.
    expect(find.text('지지받는 중'), findsNothing);
    expect(find.text('응원하는 중'), findsNothing);
    expect(find.text(l10n.usBadgeMutual), findsNothing);
  });

  testWidgets('a mutual pair keeps its single badge', (tester) async {
    await _pumpUs(
      tester,
      partner: ConnectedUser(
        user: _user('partner', '짝꿍'),
        isSupported: true,
        isCheering: true,
      ),
    );

    expect(find.text(l10n.usBadgeMutual), findsOneWidget);
    expect(find.text('지지받는 중'), findsNothing);
    expect(find.text('응원하는 중'), findsNothing);
  });

  testWidgets('the partner plan card has no fake cheer button', (tester) async {
    await _pumpUs(
      tester,
      partner: ConnectedUser(
        user: _user('partner', '짝꿍'),
        isSupported: true,
        isCheering: true,
      ),
    );

    expect(find.text('파트너 운동 약속'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(find.byTooltip(l10n.usCheerTooltip), findsNothing);
  });

  testWidgets('the partner is called by my nickname, real name underneath', (
    tester,
  ) async {
    await _pumpUs(
      tester,
      partner: ConnectedUser(
        user: _user('partner', '지민'),
        isSupported: true,
        isCheering: true,
      ),
      nickname: '여보',
    );

    expect(find.text('나 · 여보'), findsOneWidget); // hero
    expect(find.text('여보'), findsOneWidget); // partner card title
    expect(find.text('지민'), findsOneWidget); // real name underneath
    expect(find.text(l10n.usPartnerPlanTitle('여보')), findsOneWidget);
    expect(find.text(l10n.usEditNickname), findsOneWidget);
  });

  testWidgets('without a nickname the card offers to set one', (tester) async {
    await _pumpUs(
      tester,
      partner: ConnectedUser(
        user: _user('partner', '지민'),
        isSupported: true,
        isCheering: true,
      ),
    );

    expect(find.text('나 · 지민'), findsOneWidget);
    expect(find.text(l10n.usPartnerPlanTitle('지민')), findsOneWidget);
    await tester.ensureVisible(find.text(l10n.usSetNickname));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.usSetNickname));
    await tester.pumpAndSettle();
    expect(find.text(l10n.nicknameSheetTitle), findsOneWidget);
    // Default chip is 짝꿍, then the presets.
    expect(find.text(l10n.nicknamePresetPartner), findsWidgets);
    expect(find.text(l10n.nicknamePresetJagi), findsOneWidget);
    expect(find.text(l10n.nicknamePresetCustom), findsOneWidget);
  });

  group('the hero with the 둘운완 stats', () {
    DuoStats stats({required bool duoToday}) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monday = DateTime(
        today.year,
        today.month,
        today.day - (today.weekday - 1),
      );
      return DuoStats(
        streak: 3,
        streakStart: today,
        today: DuoDay(
          date: today,
          me: const DuoPersonDay(status: DuoDayStatus.done),
          partner: DuoPersonDay(
            status: duoToday ? DuoDayStatus.done : DuoDayStatus.pending,
          ),
          isToday: true,
        ),
        week: [
          for (var i = 0; i < 7; i++)
            DuoDay(
              date: DateTime(monday.year, monday.month, monday.day + i),
              me: i < 3
                  ? const DuoPersonDay(status: DuoDayStatus.done)
                  : DuoPersonDay.off,
              partner: DuoPersonDay.off,
              isToday:
                  DateTime(monday.year, monday.month, monday.day + i) == today,
            ),
        ],
        hasPartner: true,
      );
    }

    final partner = ConnectedUser(
      user: _user('partner', '지민'),
      isSupported: true,
      isCheering: true,
    );

    testWidgets('shows 둘이 함께 N일째, this week and the share button', (
      tester,
    ) async {
      await _pumpUs(tester, partner: partner, stats: stats(duoToday: false));

      expect(find.text('둘이 함께 3일째'), findsOneWidget);
      expect(find.text(l10n.usHeroSubtitle), findsNothing);
      expect(find.text('둘운완 3일'), findsOneWidget);
      expect(find.byKey(const ValueKey('duo-share-button')), findsOneWidget);
      expect(find.byType(DuoShareButton), findsOneWidget);
    });

    testWidgets('says so when today is a duo day', (tester) async {
      await _pumpUs(tester, partner: partner, stats: stats(duoToday: true));
      expect(find.text('오늘 둘운완이에요 🎉'), findsOneWidget);
    });

    testWidgets('without stats it keeps the plain subtitle', (tester) async {
      await _pumpUs(tester, partner: partner);
      expect(find.text(l10n.usHeroSubtitle), findsOneWidget);
      expect(find.byType(DuoShareButton), findsNothing);
    });
  });
}
