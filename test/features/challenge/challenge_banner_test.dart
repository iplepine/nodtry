import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/challenge/application/challenge_providers.dart';
import 'package:nod_try/features/challenge/presentation/challenge_banner.dart';
import 'package:nod_try/features/connect/application/partner_label_provider.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Records extends Fake implements RecordRepository {
  final entered = <({String planId, String challengeId})>[];
  bool fail = false;

  @override
  Future<void> setPlanChallenge(String planId, String challengeId) async {
    if (fail) throw StateError('offline');
    entered.add((planId: planId, challengeId: challengeId));
  }
}

Plan _plan({
  required String id,
  required String userId,
  String? managerId,
  String? challengeId,
  List<DateTime> completed = const [],
}) => Plan(
  id: id,
  userId: userId,
  managerId: managerId,
  startDate: DateTime(2026, 12, 21),
  endDate: DateTime(2027, 1, 17, 23, 59, 59),
  state: PlanState.active,
  items: [
    PlanItem(title: '러닝 30분', days: const [1, 2, 3, 4, 5, 6, 7], count: 7),
  ],
  createdAt: DateTime(2026, 12, 21),
  completedDates: [for (final d in completed) d.add(const Duration(hours: 19))],
  challengeId: challengeId,
  workoutType: 'running',
);

DateTime jan(int day) => DateTime(2027, 1, day);

Future<({_Records records, SharedPreferences prefs})> _pump(
  WidgetTester tester, {
  required DateTime today,
  List<Plan> myPlans = const [],
  List<Plan>? partnerPlans,
  String locale = 'ko',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final records = _Records();
  // A second pump in one test must not reuse the first scope's overrides.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        recordRepositoryProvider.overrideWithValue(records),
        duoClockProvider.overrideWithValue(() => today),
        myDuoPlansProvider.overrideWith((ref) => myPlans),
        partnerLabelProvider.overrideWithValue(
          partnerPlans == null
              ? const PartnerLabel()
              : const PartnerLabel(partnerUid: 'p', nickname: '자기'),
        ),
        duoPlansProvider(
          'p',
        ).overrideWith((ref) => Stream.value(partnerPlans ?? const <Plan>[])),
        partnerLinkedSinceProvider.overrideWith((ref) => null),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: ChallengeBanner()),
        ),
      ),
    ),
  );
  await tester.pump();
  return (records: records, prefs: prefs);
}

final _banner = find.byKey(const ValueKey('challenge-banner'));

void main() {
  testWidgets('nothing outside the challenge window', (tester) async {
    await _pump(tester, today: DateTime(2026, 11, 21));
    expect(_banner, findsNothing);
    await _pump(tester, today: DateTime(2027, 2, 1));
    expect(_banner, findsNothing);
  });

  testWidgets('announced: title, D-day, and it can be closed', (tester) async {
    final h = await _pump(
      tester,
      today: DateTime(2026, 12, 27),
      partnerPlans: const [],
    );
    expect(find.text('새해 둘운완 21일 챌린지'), findsOneWidget);
    expect(find.text('1월 1일부터 21일, 둘이 운동 약속 지키기'), findsOneWidget);
    expect(find.text('D-5'), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-banner-join')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('challenge-banner-dismiss')));
    await tester.pump();
    expect(_banner, findsNothing);
    expect(h.prefs.getStringList(ChallengeDismissalsNotifier.prefsKey), [
      'newyear2027_duo21@teaser',
    ]);
  });

  testWidgets('closing the announcement does not hide the running banner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ChallengeDismissalsNotifier.prefsKey: ['newyear2027_duo21@teaser'],
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          duoClockProvider.overrideWithValue(() => jan(1)),
          myDuoPlansProvider.overrideWith((ref) => const <Plan>[]),
          partnerLabelProvider.overrideWithValue(const PartnerLabel()),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ChallengeBanner()),
        ),
      ),
    );
    await tester.pump();
    expect(_banner, findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-banner-join')), findsOneWidget);
  });

  testWidgets('running, not entered, a promise running: enter it as it is', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      today: jan(5),
      myPlans: [_plan(id: 'mine', userId: 'me', managerId: 'p')],
      partnerPlans: const [],
    );
    expect(find.text('오늘 시작하면 1월 21일까지 17일이에요.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('challenge-banner-join')));
    await tester.pumpAndSettle();
    expect(find.text('어떻게 참여할까요?'), findsOneWidget);
    expect(find.text('러닝 30분 · 기간은 그대로예요'), findsOneWidget);
    expect(find.text('1월 21일까지 이어지는 약속이에요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('challenge-join-existing')));
    await tester.pumpAndSettle();
    expect(h.records.entered, [
      (planId: 'mine', challengeId: 'newyear2027_duo21'),
    ]);
    expect(find.text('챌린지에 참여했어요 💪'), findsOneWidget);
  });

  testWidgets('a failed join says so and enters nothing', (tester) async {
    final h = await _pump(
      tester,
      today: jan(5),
      myPlans: [_plan(id: 'mine', userId: 'me')],
    );
    h.records.fail = true;
    await tester.tap(find.byKey(const ValueKey('challenge-banner-join')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('challenge-join-existing')));
    await tester.pumpAndSettle();
    expect(h.records.entered, isEmpty);
    expect(find.text('참여하지 못했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-banner-join')), findsOneWidget);
  });

  testWidgets('entered: the day, progress and 둘운완 days since Jan 1', (
    tester,
  ) async {
    // Both worked out on the 1st, 2nd and 4th; on the 3rd only I did.
    await _pump(
      tester,
      today: jan(5),
      myPlans: [
        _plan(
          id: 'mine',
          userId: 'me',
          managerId: 'p',
          challengeId: 'newyear2027_duo21',
          completed: [DateTime(2026, 12, 30), jan(1), jan(2), jan(3), jan(4)],
        ),
      ],
      partnerPlans: [
        _plan(
          id: 'theirs',
          userId: 'p',
          managerId: 'me',
          completed: [jan(1), jan(2), jan(4)],
        ),
      ],
    );
    expect(find.text('5일째 · 전체 21일'), findsOneWidget);
    expect(find.text('둘운완 3일'), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-banner-join')), findsNothing);
    expect(
      find.byKey(const ValueKey('challenge-banner-dismiss')),
      findsNothing,
      reason: 'an entered, running challenge stays',
    );
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('challenge-banner-progress')),
    );
    expect(progress.value, closeTo(5 / 21, 0.0001));
    expect(find.byKey(const ValueKey('duo-share-button')), findsOneWidget);
  });

  testWidgets('solo: my workout days, no share card', (tester) async {
    await _pump(
      tester,
      today: jan(3),
      myPlans: [
        _plan(
          id: 'mine',
          userId: 'me',
          challengeId: 'newyear2027_duo21',
          completed: [jan(1), jan(2)],
        ),
      ],
    );
    expect(find.text('운동한 날 2일'), findsOneWidget);
    expect(find.byKey(const ValueKey('duo-share-button')), findsNothing);
  });

  testWidgets('over: the result for those who entered, nothing for others', (
    tester,
  ) async {
    await _pump(
      tester,
      today: jan(23),
      myPlans: [
        _plan(
          id: 'mine',
          userId: 'me',
          challengeId: 'newyear2027_duo21',
          completed: [jan(1), jan(2), jan(22)],
        ),
      ],
    );
    expect(find.text('챌린지를 마쳤어요 🎉'), findsOneWidget);
    expect(
      find.text('운동한 날 2일'),
      findsOneWidget,
      reason: 'the 22nd is after it',
    );

    await _pump(
      tester,
      today: jan(23),
      myPlans: [_plan(id: 'm', userId: 'me')],
    );
    expect(_banner, findsNothing);
  });

  test('every challenge image is a bundled file', () {
    for (final challenge in kDuoChallenges) {
      final asset = challengeImageAsset(challenge);
      if (asset == null) continue;
      expect(File(asset).existsSync(), isTrue, reason: asset);
      expect(asset, startsWith('assets/images/'), reason: 'declared directory');
    }
  });

  testWidgets('the join sheet fits a short screen with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(
      tester,
      today: jan(2),
      myPlans: [_plan(id: 'm', userId: 'me')],
      partnerPlans: const [],
    );
    await tester.tap(find.byKey(const ValueKey('challenge-banner-join')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('challenge-art')), findsWidgets);
    await tester.ensureVisible(
      find.byKey(const ValueKey('challenge-join-new')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('English', (tester) async {
    await _pump(
      tester,
      today: jan(5),
      myPlans: const [],
      partnerPlans: const [],
      locale: 'en',
    );
    expect(tester.takeException(), isNull);
    expect(find.text('New Year 21-day DuoDone challenge'), findsOneWidget);
    expect(find.text('Start today: 17 days until Jan 21.'), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
  });
}
