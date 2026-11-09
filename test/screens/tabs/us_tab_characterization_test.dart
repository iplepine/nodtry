// Characterization tests for the 우리 tab pieces that had no coverage before
// us_screen.dart was split into part files: the guest warning + link sheet,
// the profile editor dialog, the plan-delete confirm and the partner menu.
// They pin today's behaviour; they are not a spec for new behaviour.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/features/us/presentation/screens/us_screen.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/plan_list_provider.dart';
import 'package:nod_try/providers/repository_provider.dart';

UserModel _user(
  String uid,
  String name, {
  LoginType loginType = LoginType.google,
  String? status,
}) {
  final now = DateTime.now();
  return UserModel(
    uid: uid,
    displayName: name,
    statusMessage: status,
    loginType: loginType,
    createdAt: now,
    updatedAt: now,
  );
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
  required UserModel me,
  List<ConnectedUser> partners = const [],
  List<Plan> myPlans = const [],
}) async {
  final profile = StreamController<UserModel?>();
  addTearDown(profile.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myProfileProvider.overrideWith((ref) => profile.stream),
        connectedProfilesProvider.overrideWith((ref) async => partners),
        activePlansProvider(
          me.uid,
        ).overrideWith((ref) => Stream.value(myPlans)),
        for (final p in partners)
          activePlansProvider(
            p.user.uid,
          ).overrideWith((ref) => Stream.value(const <Plan>[])),
        duoStatsProvider.overrideWith((ref) => null),
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
  profile.add(me);
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('a guest sees the warning and its link sheet', (tester) async {
    await _pumpUs(tester, me: _user('me', '나', loginType: LoginType.guest));

    expect(find.text(l10n.usGuestWarningMessage), findsOneWidget);
    expect(find.text(l10n.usGuestWarningAction), findsOneWidget);

    await tester.tap(find.text(l10n.usGuestWarningAction));
    await tester.pumpAndSettle();

    // The sheet repeats the action as its title.
    expect(find.text(l10n.usGuestWarningAction), findsNWidgets(2));
  });

  testWidgets('a linked account shows no guest warning', (tester) async {
    await _pumpUs(tester, me: _user('me', '나'));

    expect(find.text(l10n.usGuestWarningMessage), findsNothing);
  });

  testWidgets('편집 opens the profile editor prefilled, 취소 closes it', (
    tester,
  ) async {
    await _pumpUs(tester, me: _user('me', '민수', status: '오늘도 화이팅'));

    expect(find.text('오늘도 화이팅'), findsOneWidget);

    await tester.tap(find.text(l10n.usProfileEdit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.usEditProfile), findsOneWidget);
    expect(find.text(l10n.usNameLabel), findsOneWidget);
    expect(find.text(l10n.usStatusLabel), findsOneWidget);
    expect(find.widgetWithText(TextField, '민수'), findsOneWidget);
    expect(find.widgetWithText(TextField, '오늘도 화이팅'), findsOneWidget);
    expect(find.text(l10n.usSave), findsOneWidget);

    await tester.tap(find.text(l10n.usCancel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.usEditProfile), findsNothing);
  });

  testWidgets('without a status the placeholder is shown', (tester) async {
    await _pumpUs(tester, me: _user('me', '민수'));

    expect(find.text(l10n.usStatusMessagePlaceholder), findsOneWidget);
  });

  testWidgets('my plan card offers delete behind a confirm dialog', (
    tester,
  ) async {
    await _pumpUs(
      tester,
      me: _user('me', '나'),
      myPlans: [_plan('p1', '아침 러닝', 'me')],
    );

    expect(find.text(l10n.usMyPlanTitle), findsOneWidget);
    expect(find.text('아침 러닝'), findsOneWidget);
    expect(find.text(l10n.usCreatePlan), findsOneWidget);

    final planMenu = find.byTooltip(l10n.planCardMenuTooltip);
    await tester.ensureVisible(planMenu);
    await tester.pumpAndSettle();
    await tester.tap(planMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.planCardDelete));
    await tester.pumpAndSettle();

    expect(find.text(l10n.usDeletePlanTitle), findsOneWidget);
    expect(find.text(l10n.usDeletePlanBody), findsOneWidget);

    await tester.tap(find.text(l10n.usCancel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.usDeletePlanTitle), findsNothing);
    expect(find.text('아침 러닝'), findsOneWidget);
  });

  testWidgets('the partner card menu holds report and disconnect', (
    tester,
  ) async {
    await _pumpUs(
      tester,
      me: _user('me', '나'),
      partners: [
        ConnectedUser(
          user: _user('partner', '지은'),
          isSupported: true,
          isCheering: true,
        ),
      ],
    );

    final menu = find.byTooltip(l10n.usDisconnectTooltip);
    await tester.ensureVisible(menu);
    await tester.pumpAndSettle();
    await tester.tap(menu);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('us-report-partner')), findsOneWidget);
    expect(find.text(l10n.usReportPartner), findsOneWidget);
    expect(find.text(l10n.usDisconnectTooltip), findsOneWidget);
  });
}
