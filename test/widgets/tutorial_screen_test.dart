import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/tutorial/presentation/tutorial_screen.dart';
import 'package:nod_try/l10n/app_localizations.dart';

Widget _wrap(Locale locale) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const TutorialScreen(showBackButton: false),
  );
}

void main() {
  // The tutorial renders before sign-in, so this copy is a new user's very
  // first impression of the app.
  testWidgets('renders Korean copy in the ko locale', (tester) async {
    await tester.pumpWidget(_wrap(const Locale('ko')));
    await tester.pumpAndSettle();

    expect(find.text('할 일을 작게 정해요'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
    expect(find.text('처음엔 작은 약속 하나면 충분해요.'), findsOneWidget);
  });

  testWidgets('renders English copy in the en locale', (tester) async {
    await tester.pumpWidget(_wrap(const Locale('en')));
    await tester.pumpAndSettle();

    // Regression: every string here was a Korean literal, so an English user's
    // first screen was entirely untranslated.
    expect(find.text('Keep it small'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('One small promise is enough to begin.'), findsOneWidget);

    expect(find.text('할 일을 작게 정해요'), findsNothing);
    expect(find.text('다음'), findsNothing);
  });

  testWidgets('the last page swaps the CTA to start and skip to close', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const Locale('en')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text("Let your record shape what's next"), findsOneWidget);
    expect(find.text("Okay, let's start"), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
