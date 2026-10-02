import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/application/partner_label_provider.dart';
import 'package:nod_try/features/duo/application/duo_moments.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/features/duo/application/review_prompt.dart';
import 'package:nod_try/features/duo/presentation/duo_share_card.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Requester implements ReviewRequester {
  int requests = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => requests++;
}

DuoStats _stats({required bool duoToday, int streak = 3}) {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day);
  final today = DuoDay(
    date: date,
    me: const DuoPersonDay(
      status: DuoDayStatus.done,
      doneWorkoutTypes: ['running'],
    ),
    partner: DuoPersonDay(
      status: duoToday ? DuoDayStatus.done : DuoDayStatus.pending,
      doneWorkoutTypes: duoToday ? const ['gym'] : const [],
    ),
    isToday: true,
  );
  final monday = DateTime(date.year, date.month, date.day - (date.weekday - 1));
  return DuoStats(
    streak: streak,
    streakStart: DateTime(date.year, date.month, date.day - streak + 1),
    today: today,
    week: [
      for (var i = 0; i < 7; i++)
        DateTime(monday.year, monday.month, monday.day + i) == date
            ? today
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

Future<({SharedPreferences prefs, _Requester requester, List<bool> results})>
_pump(WidgetTester tester, DuoStats stats) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final requester = _Requester();
  final results = <bool>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        duoStatsProvider.overrideWith((ref) => stats),
        myDuoPlansProvider.overrideWith((ref) => const <Plan>[]),
        partnerLabelProvider.overrideWithValue(
          const PartnerLabel(partnerUid: 'p', nickname: '자기'),
        ),
        reviewRequesterProvider.overrideWithValue(requester),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async =>
                  results.add(await runDuoMomentPrompts(context, ref)),
              child: const Text('run'),
            ),
          ),
        ),
      ),
    ),
  );
  return (prefs: prefs, requester: requester, results: results);
}

void main() {
  testWidgets('a milestone duo day offers the card, then asks for a review', (
    tester,
  ) async {
    final h = await _pump(tester, _stats(duoToday: true, streak: 3));

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    expect(find.byType(DuoShareSheet), findsOneWidget);
    expect(find.text('둘이 함께 3일째! 🎉 자랑해 볼까요?'), findsOneWidget);
    expect(h.requester.requests, 0, reason: 'never over the share sheet');

    await tester.tap(find.byKey(const ValueKey('share-sheet-later')));
    await tester.pumpAndSettle();
    expect(h.results, [true]);
    expect(h.requester.requests, 1);
    expect(h.prefs.getString(DuoMomentPrefKeys.doneDayLogged), isNotNull);

    // Same day again: nothing more.
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    expect(find.byType(DuoShareSheet), findsNothing);
    expect(h.results, [true, false]);
    expect(h.requester.requests, 1);
  });

  testWidgets('no duo day yet: no sheet, no review', (tester) async {
    final h = await _pump(tester, _stats(duoToday: false, streak: 0));
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    expect(find.byType(DuoShareSheet), findsNothing);
    expect(h.results, [false]);
    expect(h.requester.requests, 0);
  });
}
