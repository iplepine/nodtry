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

    expect(find.text('운동 약속을 걸어요'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
    expect(find.text('운동 약속 하나면 시작할 수 있어요.'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_rounded), findsOneWidget);
  });

  testWidgets('renders English copy in the en locale', (tester) async {
    await tester.pumpWidget(_wrap(const Locale('en')));
    await tester.pumpAndSettle();

    // Regression: every string here was a Korean literal, so an English user's
    // first screen was entirely untranslated.
    expect(find.text('Make a workout promise'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(
      find.text('One workout promise is all it takes to start.'),
      findsOneWidget,
    );

    expect(find.text('운동 약속을 걸어요'), findsNothing);
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

    expect(find.text("Both done? That's DuoDone"), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('the Korean pages tell the couple-workout story in order', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const Locale('ko')));
    await tester.pumpAndSettle();

    expect(find.text('운동 약속을 걸어요'), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('짝꿍이 보고 인정해요'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('둘 다 하면, 둘운완'), findsOneWidget);
    expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('"초대 코드 받았어요" is only offered on the first run', (tester) async {
    // Replay from Settings: no link.
    await tester.pumpWidget(_wrap(const Locale('ko')));
    await tester.pumpAndSettle();
    expect(find.text('초대 코드 받았어요'), findsNothing);

    var haveCode = 0;
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TutorialScreen(
          showBackButton: false,
          onFinished: () => finished++,
          onHaveInviteCode: () => haveCode++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Right on the first page, so an invited partner skips the rest.
    expect(find.text('운동 약속을 걸어요'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tutorial-have-invite-code')));
    await tester.pumpAndSettle();
    expect(haveCode, 1);
    expect(finished, 0);
  });

  testWidgets('a short screen scrolls instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TutorialScreen(showBackButton: false, onHaveInviteCode: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
