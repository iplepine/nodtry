import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/presentation/widgets/promise_proposal_sheet.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/promise_model.dart';

Plan _plan({
  required List<int> days,
  DateTime? startDate,
  int durationDays = 28,
  List<DateTime> completedDates = const [],
}) {
  final resolvedStartDate = startDate ?? DateTime(2026, 1, 5);
  return Plan(
    id: 'plan-test',
    userId: 'user-test',
    managerId: 'manager-test',
    startDate: resolvedStartDate,
    endDate: resolvedStartDate.add(Duration(days: durationDays - 1)),
    state: PlanState.active,
    items: [PlanItem(title: '헬스장 가기', days: days, count: 1)],
    createdAt: resolvedStartDate,
    completedDates: completedDates,
  );
}

Future<void> _pumpSheet(
  WidgetTester tester,
  Plan plan, {
  DateTime? asOf,
  Locale locale = const Locale('ko'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PromiseProposalSheet(plan: plan, asOf: asOf),
      ),
    ),
  );
}

typedef _Bet = ({PromiseReward? reward, PromisePenalty? penalty});

/// Opens the sheet the way the Now tab does, so its result can be read.
Future<List<_Bet?>> _openSheet(WidgetTester tester, Plan plan) async {
  final results = <_Bet?>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await showModalBottomSheet<_Bet>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => PromiseProposalSheet(
                    plan: plan,
                    asOf: DateTime(2026, 1, 5),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

final _mwf = _plan(
  days: const [DateTime.monday, DateTime.wednesday, DateTime.friday],
);

ElevatedButton _submit(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byKey(const ValueKey('promise-submit')));

void main() {
  testWidgets('못 지키면 leads and is on by default; 지키면 is optional', (
    tester,
  ) async {
    await _pumpSheet(tester, _mwf, asOf: DateTime(2026, 1, 5));

    expect(find.text('총 28일짜리 약속 · 할 날 12일'), findsOneWidget);
    expect(find.text('지금 지킨 날 0일 · 놓친 날 0일 · 남은 날 12일'), findsOneWidget);
    expect(find.text('지킬 날은 최대 12일, 놓칠 날은 최대 12일까지 정할 수 있어요.'), findsOneWidget);

    final penaltyTitle = tester.getTopLeft(find.text('⚡ 못 지키면'));
    final rewardTitle = tester.getTopLeft(find.text('🏆 지키면'));
    expect(penaltyTitle.dy, lessThan(rewardTitle.dy));

    // Only the penalty section is open: its field and day picker.
    expect(find.byKey(const ValueKey('promise-penalty-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('promise-reward-field')), findsNothing);
    expect(find.text('10일'), findsOneWidget);
    expect(find.text('최대 12일'), findsOneWidget);
  });

  testWidgets('keeps increment button within scheduled-day limit', (
    tester,
  ) async {
    await _pumpSheet(tester, _mwf, asOf: DateTime(2026, 1, 5));

    final addFinder = find.widgetWithIcon(IconButton, Icons.add_circle_outline);
    for (var i = 0; i < 3; i++) {
      await tester.tap(addFinder);
      await tester.pump();
    }

    expect(find.text('12일'), findsOneWidget);
    final addButton = tester.widget<IconButton>(addFinder);
    expect(addButton.onPressed, isNull);
  });

  testWidgets('limits reward target to current successes plus remaining days', (
    tester,
  ) async {
    final startDate = DateTime(2026, 1, 1);
    final completedDates = List.generate(
      5,
      (index) => startDate.add(Duration(days: index)),
    );

    await _pumpSheet(
      tester,
      _plan(
        startDate: startDate,
        durationDays: 30,
        days: const [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
        completedDates: completedDates,
      ),
      asOf: startDate.add(const Duration(days: 20)),
    );

    // Turn on 지키면 (the second switch).
    final rewardSwitch = find.byType(Switch).at(1);
    await tester.ensureVisible(rewardSwitch);
    await tester.tap(rewardSwitch);
    await tester.pumpAndSettle();

    expect(find.text('총 30일짜리 약속이에요'), findsOneWidget);
    expect(find.text('지금 지킨 날 5일 · 놓친 날 15일 · 남은 날 10일'), findsOneWidget);
    expect(find.text('지킬 날은 최대 15일, 놓칠 날은 최대 25일까지 정할 수 있어요.'), findsOneWidget);
    expect(find.text('12일'), findsOneWidget); // reward default
    expect(find.text('최대 15일'), findsOneWidget);
    expect(find.text('18일'), findsOneWidget); // penalty default
  });

  testWidgets('the curated chips fill the bet in one tap', (tester) async {
    final results = await _openSheet(tester, _mwf);

    expect(_submit(tester).onPressed, isNull); // nothing written yet
    for (final chip in [
      '🍗 치킨 쏘기',
      '☕ 아아 쏘기',
      '🍽️ 설거지 일주일',
      '💆 마사지 10분',
      // As a penalty the pick goes to the other one (양보), not to the
      // person who missed.
      '🎬 영화 고르기 양보',
      '🚗 데리러 가기',
    ]) {
      expect(find.text(chip), findsOneWidget, reason: chip);
    }

    await tester.tap(find.byKey(const ValueKey('promise-penalty-chip-0')));
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('promise-penalty-field')),
    );
    expect(field.controller!.text, '🍗 치킨 쏘기');
    expect(_submit(tester).onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const ValueKey('promise-submit')));
    await tester.tap(find.byKey(const ValueKey('promise-submit')));
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single!.penalty!.description, '🍗 치킨 쏘기');
    expect(results.single!.penalty!.targetDays, 10);
    expect(results.single!.reward, isNull);
  });

  testWidgets('reward chips include 🍣 같이 오마카세', (tester) async {
    await _openSheet(tester, _mwf);
    final rewardSwitch = find.byType(Switch).at(1);
    await tester.ensureVisible(rewardSwitch);
    await tester.tap(rewardSwitch);
    await tester.pumpAndSettle();

    final omakase = find.byKey(const ValueKey('promise-reward-chip-0'));
    await tester.ensureVisible(omakase);
    expect(find.text('🍣 같이 오마카세'), findsOneWidget);
    await tester.tap(omakase);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('promise-reward-field')))
          .controller!
          .text,
      '🍣 같이 오마카세',
    );
  });

  group('money guard', () {
    const blocked = '돈 내기는 지원하지 않아요. 밥, 커피, 설거지처럼 둘이 할 수 있는 걸로 걸어 주세요.';

    for (final text in ['만원 내기', '3000원 보내기', '현금 주기', '계좌로 송금', '포인트 선물']) {
      testWidgets('"$text" shows the notice and blocks saving', (tester) async {
        await _pumpSheet(tester, _mwf, asOf: DateTime(2026, 1, 5));
        await tester.enterText(
          find.byKey(const ValueKey('promise-penalty-field')),
          text,
        );
        await tester.pump();

        expect(find.text(blocked), findsOneWidget);
        expect(_submit(tester).onPressed, isNull);
      });
    }

    testWidgets('a wish bet (소원 들어주기) is not money', (tester) async {
      await _pumpSheet(tester, _mwf, asOf: DateTime(2026, 1, 5));
      await tester.enterText(
        find.byKey(const ValueKey('promise-penalty-field')),
        '소원 들어주기',
      );
      await tester.pump();

      expect(find.text(blocked), findsNothing);
      expect(_submit(tester).onPressed, isNotNull);
    });

    testWidgets('fixing the text unblocks saving', (tester) async {
      await _pumpSheet(tester, _mwf, asOf: DateTime(2026, 1, 5));
      final field = find.byKey(const ValueKey('promise-penalty-field'));
      await tester.enterText(field, '5만원');
      await tester.pump();
      expect(_submit(tester).onPressed, isNull);

      await tester.enterText(field, '설거지 일주일');
      await tester.pump();
      expect(find.text(blocked), findsNothing);
      expect(_submit(tester).onPressed, isNotNull);
    });

    testWidgets('the English notice shows for an English money bet', (
      tester,
    ) async {
      await _pumpSheet(
        tester,
        _mwf,
        asOf: DateTime(2026, 1, 5),
        locale: const Locale('en'),
      );
      await tester.enterText(
        find.byKey(const ValueKey('promise-penalty-field')),
        r'$20 cash',
      );
      await tester.pump();
      expect(
        find.textContaining("Money bets aren't supported"),
        findsOneWidget,
      );
      expect(_submit(tester).onPressed, isNull);
    });
  });
}
