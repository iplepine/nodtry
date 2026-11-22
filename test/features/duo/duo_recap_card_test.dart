import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/application/partner_label_provider.dart';
import 'package:nod_try/features/duo/application/duo_moments.dart';
import 'package:nod_try/features/duo/application/duo_recap_provider.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/features/duo/application/review_prompt.dart';
import 'package:nod_try/features/duo/presentation/duo_recap_card.dart';
import 'package:nod_try/features/duo/presentation/duo_share_card.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// November 2026: the 1st is a Sunday, the 2nd a Monday.
DateTime nov(int day) => DateTime(2026, 11, day);

Plan _plan({
  required String id,
  required String userId,
  required String? managerId,
  required List<DateTime> completed,
  String? workoutType,
  DateTime? start,
}) => Plan(
  id: id,
  userId: userId,
  managerId: managerId,
  startDate: start ?? DateTime(2026, 10, 1),
  endDate: DateTime(2026, 12, 31, 23, 59, 59),
  state: PlanState.active,
  items: [
    PlanItem(title: '운동', days: const [1, 3, 5], count: 3),
  ],
  createdAt: start ?? DateTime(2026, 10, 1),
  completedDates: [for (final x in completed) x.add(const Duration(hours: 19))],
  workoutType: workoutType,
);

final _mine = _plan(
  id: 'a1',
  userId: 'me',
  managerId: 'p',
  completed: [nov(2), nov(4), nov(6), nov(9), nov(11), nov(13)],
  workoutType: 'running',
);
final _theirs = _plan(
  id: 'b1',
  userId: 'p',
  managerId: 'me',
  completed: [nov(2), nov(4), nov(9), nov(11), nov(13)],
  workoutType: 'yoga',
);

DuoRecap _recap({DateTime? month, DateTime? today, bool hasPartner = true}) =>
    computeDuoRecap(
      myPlans: [_mine],
      partnerPlans: [_theirs],
      month: month ?? nov(1),
      today: today ?? nov(14),
      hasPartner: hasPartner,
    );

Widget _app(Widget child, {List overrides = const [], String locale = 'ko'}) =>
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

/// The card is laid out unconstrained, the way the sheet's FittedBox does.
Widget _fitted(Widget card) => Center(child: FittedBox(child: card));

class _Sharer implements ShareCardSharer {
  final shared = <({Uint8List png, String text})>[];

  @override
  Future<ShareCardResult> sharePng(
    Uint8List png, {
    required String text,
    Rect? origin,
  }) async {
    shared.add((png: png, text: text));
    return const ShareCardResult(shared: true, target: 'instagram');
  }
}

class _Requester implements ReviewRequester {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> requestReview() async {}
}

/// The providers the sheet reads, as of [today].
List _sheetOverrides({
  required DateTime today,
  _Sharer? sharer,
  List<Plan>? myPlans,
  bool hasPartner = true,
}) => [
  duoClockProvider.overrideWithValue(() => today),
  myDuoPlansProvider.overrideWith((ref) => myPlans ?? [_mine]),
  partnerLabelProvider.overrideWithValue(
    hasPartner
        ? const PartnerLabel(partnerUid: 'p', nickname: '자기')
        : const PartnerLabel(),
  ),
  duoPlansProvider('p').overrideWith((ref) => Stream.value([_theirs])),
  partnerLinkedSinceProvider.overrideWith((ref) => null),
  shareCardCaptureProvider.overrideWithValue(
    (key) async => Uint8List.fromList([1, 2, 3]),
  ),
  if (sharer != null) shareCardSharerProvider.overrideWithValue(sharer),
];

void main() {
  group('DuoRecapCard', () {
    testWidgets('a couple: title, headline, both people and the calendar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _fitted(
            DuoRecapCard(recap: _recap(), meLabel: '나', partnerLabel: '자기'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('우리의 11월'), findsOneWidget);
      expect(find.text('둘운완 5일'), findsOneWidget);
      expect(find.text('나 6일 · 🏃 러닝'), findsOneWidget);
      expect(find.text('자기 5일 · 🧘 요가'), findsOneWidget);
      expect(find.text('최장 연속 3일'), findsOneWidget);
      expect(find.text('11월 14일까지'), findsOneWidget);
      // The 2nd was a duo day; on the 6th only I worked out; the 7th nobody.
      expect(find.byKey(const ValueKey('recap-day-2-full')), findsOneWidget);
      expect(find.byKey(const ValueKey('recap-day-6-ring')), findsOneWidget);
      expect(find.byKey(const ValueKey('recap-day-7-none')), findsOneWidget);
      expect(find.byKey(const ValueKey('recap-day-30-none')), findsOneWidget);
      expect(find.text('한 명만'), findsOneWidget);
      expect(find.text("스토어에서 '둘운완' 검색"), findsOneWidget);
    });

    testWidgets('solo: my month, no partner line, no ring legend', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _fitted(
            DuoRecapCard(
              recap: _recap(hasPartner: false),
              meLabel: '나',
              partnerLabel: '자기',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('나의 11월'), findsOneWidget);
      expect(find.text('운동한 날 6일'), findsOneWidget);
      expect(find.textContaining('자기'), findsNothing);
      expect(find.text('한 명만'), findsNothing);
      expect(find.byKey(const ValueKey('recap-day-6-full')), findsOneWidget);
    });

    testWidgets('a finished month has no "so far" note', (tester) async {
      await tester.pumpWidget(
        _app(
          _fitted(
            DuoRecapCard(
              recap: _recap(today: DateTime(2026, 12, 2)),
              meLabel: '나',
              partnerLabel: '자기',
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('recap-card-so-far')), findsNothing);
    });

    testWidgets('English fits too', (tester) async {
      await tester.pumpWidget(
        _app(
          _fitted(
            DuoRecapCard(recap: _recap(), meLabel: 'Me', partnerLabel: 'Honey'),
          ),
          locale: 'en',
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Our November'), findsOneWidget);
      expect(find.text('5 DuoDone days'), findsOneWidget);
      expect(find.text('Best streak: 3 days'), findsOneWidget);
    });

    testWidgets('a six-row month fits the card', (tester) async {
      // August 2026 starts on a Saturday: six calendar rows.
      await tester.pumpWidget(
        _app(
          _fitted(
            DuoRecapCard(
              recap: _recap(
                month: DateTime(2026, 8),
                today: DateTime(2026, 8, 31),
              ),
              meLabel: '나',
              partnerLabel: '자기',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('recap-day-31-none')), findsOneWidget);
    });
  });

  group('DuoRecapSheet', () {
    testWidgets('shares the card and closes', (tester) async {
      final sharer = _Sharer();
      bool? result;
      await tester.pumpWidget(
        _app(
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async => result = await showDuoRecapSheet(
                context,
                ref,
                source: DuoRecapSource.us,
              ),
              child: const Text('open'),
            ),
          ),
          overrides: _sheetOverrides(today: nov(14), sharer: sharer),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('월간 리캡'), findsOneWidget);
      expect(find.text('2026년 11월'), findsOneWidget);
      expect(find.text('둘운완 5일'), findsOneWidget);

      await tester.tap(find.text('공유하기'));
      await tester.pumpAndSettle();
      expect(sharer.shared, hasLength(1));
      expect(sharer.shared.single.text, contains('#둘운완'));
      expect(find.byType(DuoRecapSheet), findsNothing);
      expect(result, isTrue);
    });

    testWidgets('goes back a month; an empty month cannot be shared', (
      tester,
    ) async {
      final sharer = _Sharer();
      await tester.pumpWidget(
        _app(
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () =>
                  showDuoRecapSheet(context, ref, source: DuoRecapSource.us),
              child: const Text('open'),
            ),
          ),
          overrides: _sheetOverrides(today: nov(14), sharer: sharer),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // This month is the newest: no next.
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('recap-next-month')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('recap-prev-month')));
      await tester.pumpAndSettle();
      expect(find.text('2026년 10월'), findsOneWidget);
      expect(find.text('우리의 10월'), findsOneWidget);
      expect(find.byKey(const ValueKey('recap-sheet-empty')), findsOneWidget);
      // The plan began in October: nothing older.
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('recap-prev-month')))
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('공유하기'));
      await tester.pumpAndSettle();
      expect(sharer.shared, isEmpty);
      expect(find.byType(DuoRecapSheet), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('recap-sheet-later')));
      await tester.pumpAndSettle();
      expect(find.byType(DuoRecapSheet), findsNothing);
    });
  });

  group('DuoRecapEntry', () {
    testWidgets('hidden until I have a plan', (tester) async {
      await tester.pumpWidget(
        _app(
          const DuoRecapEntry(),
          overrides: _sheetOverrides(today: nov(14), myPlans: const []),
        ),
      );
      expect(find.byKey(const ValueKey('duo-recap-entry')), findsNothing);
    });

    testWidgets('opens this month\'s recap, solo too', (tester) async {
      await tester.pumpWidget(
        _app(
          const DuoRecapEntry(),
          overrides: _sheetOverrides(today: nov(14), hasPartner: false),
        ),
      );
      expect(find.text('11월 리캡'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('duo-recap-entry')));
      await tester.pumpAndSettle();
      expect(find.byType(DuoRecapSheet), findsOneWidget);
      expect(find.text('나의 11월'), findsOneWidget);
      expect(find.text('운동한 날 6일'), findsOneWidget);
    });
  });

  group('the start-of-month offer', () {
    DuoStats statsOn(DateTime date) {
      final today = DuoDay(
        date: date,
        me: DuoPersonDay.off,
        partner: DuoPersonDay.off,
        isToday: true,
      );
      final monday = DateTime(
        date.year,
        date.month,
        date.day - (date.weekday - 1),
      );
      return DuoStats(
        streak: 0,
        streakStart: null,
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

    Future<({SharedPreferences prefs, List<bool> results})> pump(
      WidgetTester tester,
      DateTime today,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final results = <bool>[];
      await tester.pumpWidget(
        _app(
          Consumer(
            builder: (context, ref, _) {
              // In the app the Now tab's duo header keeps both people's
              // plans loaded.
              ref.watch(duoPlansProvider('p'));
              return TextButton(
                onPressed: () async =>
                    results.add(await runDuoMomentPrompts(context, ref)),
                child: const Text('run'),
              );
            },
          ),
          overrides: [
            ..._sheetOverrides(today: today, sharer: _Sharer()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            duoStatsProvider.overrideWith((ref) => statsOn(today)),
            reviewRequesterProvider.overrideWithValue(_Requester()),
          ],
        ),
      );
      await tester.pump();
      return (prefs: prefs, results: results);
    }

    testWidgets('last month\'s recap is offered once in the first week', (
      tester,
    ) async {
      final h = await pump(tester, DateTime(2026, 12, 2));

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();
      expect(find.byType(DuoRecapSheet), findsOneWidget);
      expect(find.text('11월 리캡이 나왔어요 🎉'), findsOneWidget);
      expect(find.text('우리의 11월'), findsOneWidget);
      expect(h.prefs.getString(DuoMomentPrefKeys.recapOfferedMonth), '2026-11');

      await tester.tap(find.byKey(const ValueKey('recap-sheet-later')));
      await tester.pumpAndSettle();
      expect(h.results, [true]);

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();
      expect(find.byType(DuoRecapSheet), findsNothing);
      expect(h.results, [true, false]);
    });

    testWidgets('not after the first week', (tester) async {
      final h = await pump(tester, DateTime(2026, 12, 8));
      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();
      expect(find.byType(DuoRecapSheet), findsNothing);
      expect(h.results, [false]);
      expect(h.prefs.getString(DuoMomentPrefKeys.recapOfferedMonth), isNull);
    });
  });
}
