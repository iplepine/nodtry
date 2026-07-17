import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/presentation/focus_timer/focus_timer_screen.dart';
import 'package:nod_try/l10n/app_localizations.dart';

Widget _wrap(int minutes) {
  return MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: FocusTimerScreen(minutes: minutes),
  );
}

/// The countdown text is the only 48px label on the screen.
String _clockText(WidgetTester tester) {
  final clock = tester
      .widgetList<Text>(find.byType(Text))
      .firstWhere((t) => t.style?.fontSize == 48);
  return clock.data!;
}

void main() {
  // The picker accepts any value up to 120 minutes, so everything here is
  // reachable from the UI.
  testWidgets('a 61 minute session does not read as 59 seconds left', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(61));
    await tester.pump();

    // Regression: `inMinutes.remainder(60)` dropped the hour, rendering "00:59"
    // — a full hour of work that looks like it is about to run out.
    expect(_clockText(tester), matches(RegExp(r'^1:00:\d{2}$')));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a 90 minute session shows the hour it still has left', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(90));
    await tester.pump();

    // Regression: previously "29:59", indistinguishable from a 30 min session.
    expect(_clockText(tester), matches(RegExp(r'^1:29:\d{2}$')));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the 120 minute maximum shows two hours, not one', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(120));
    await tester.pump();

    // Regression: previously "59:59" — the same clock a 60 min session shows.
    expect(_clockText(tester), matches(RegExp(r'^1:59:\d{2}$')));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sessions under an hour keep the compact mm:ss clock', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(25));
    await tester.pump();

    expect(_clockText(tester), matches(RegExp(r'^24:\d{2}$')));

    await tester.pumpWidget(const SizedBox());
  });
}
