import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/domain/duo_stats.dart';
import 'package:nod_try/features/duo/presentation/duo_widgets.dart';
import 'package:nod_try/l10n/app_localizations.dart';

Widget _app(Widget child, {Locale locale = const Locale('ko')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  final monday = DateTime(2026, 9, 28);
  List<DuoDay> week() => [
    DuoDay(
      date: monday,
      me: const DuoPersonDay(
        status: DuoDayStatus.done,
        verification: DuoVerification.verified,
      ),
      partner: DuoPersonDay.off,
      isToday: false,
    ),
    DuoDay(
      date: DateTime(2026, 9, 29),
      me: DuoPersonDay.off,
      partner: const DuoPersonDay(status: DuoDayStatus.missed),
      isToday: false,
    ),
    DuoDay(
      date: DateTime(2026, 9, 30),
      me: const DuoPersonDay(status: DuoDayStatus.pending),
      partner: const DuoPersonDay(status: DuoDayStatus.rested),
      isToday: true,
    ),
    for (var i = 3; i < 7; i++)
      DuoDay(
        date: DateTime(2026, 9, 28 + i),
        me: const DuoPersonDay(status: DuoDayStatus.upcoming),
        partner: DuoPersonDay.off,
        isToday: false,
      ),
  ];

  testWidgets('week dots highlight duo days and mark 인정 and misses', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        DuoWeekDots(
          week: week(),
          showPartner: true,
          meLabel: '나',
          partnerLabel: '자기',
        ),
      ),
    );

    expect(find.byKey(const ValueKey('duo-week-9-28-duo')), findsOneWidget);
    expect(find.byKey(const ValueKey('duo-week-9-29')), findsOneWidget);
    expect(find.byKey(const ValueKey('duo-week-9-30')), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget); // 인정 ❤️
    expect(find.byIcon(Icons.close_rounded), findsOneWidget); // a miss
    expect(find.text('나'), findsOneWidget);
    expect(find.text('자기'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('나 인정 ❤️')), findsOneWidget);
  });

  testWidgets('status labels', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    String label(DuoDayStatus s, [DuoVerification v = DuoVerification.none]) =>
        duoStatusLabel(l10n, DuoPersonDay(status: s, verification: v));
    expect(label(DuoDayStatus.done), '완료 ✓');
    expect(label(DuoDayStatus.done, DuoVerification.verified), '인정 ❤️');
    expect(label(DuoDayStatus.done, DuoVerification.waiting), '인정 대기');
    expect(label(DuoDayStatus.pending), '아직');
    expect(label(DuoDayStatus.rested), '휴식권');
    expect(label(DuoDayStatus.off), '쉬는 날');
    expect(label(DuoDayStatus.missed), '놓침');
    expect(duoStreakHeadline(l10n, 0), '오늘 둘 다 하면 둘운완 1일째');
    expect(duoStreakHeadline(l10n, 12), '둘이 함께 12일째');

    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(duoStreakHeadline(en, 1), 'Together for 1 day');
    expect(duoStreakHeadline(en, 4), 'Together for 4 days');
  });
}
