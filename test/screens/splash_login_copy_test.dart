import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/auth/presentation/auth_state.dart';
import 'package:nod_try/features/auth/presentation/screens/splash_screen.dart';
import 'package:nod_try/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the login screen on screen: no Firebase, no auto-login.
class _IdleAuthViewModel extends AuthViewModel {
  @override
  Future<void> dispatch(AuthIntent intent) async {}
}

Future<void> _pumpLogin(WidgetTester tester, Locale locale) async {
  // Tutorial already seen → the splash goes straight to the login UI.
  SharedPreferences.setMockInitialValues({
    'duodone_tutorial_completed_v2': true,
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authViewModelProvider.overrideWith(_IdleAuthViewModel.new)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the login screen shows the app name and tagline (ko)', (
    tester,
  ) async {
    await _pumpLogin(tester, const Locale('ko'));

    expect(find.text('둘운완'), findsOneWidget);
    expect(find.text('둘이 보면, 진짜 하게 돼요.'), findsOneWidget);
    expect(find.text('Google 계정으로 계속하기'), findsOneWidget);
    expect(find.text('로그인 없이 시작하기'), findsOneWidget);
  });

  testWidgets('the login screen shows the app name and tagline (en)', (
    tester,
  ) async {
    await _pumpLogin(tester, const Locale('en'));

    expect(find.text('DuoDone'), findsOneWidget);
    expect(
      find.text('When your partner sees it, you actually do it.'),
      findsOneWidget,
    );
  });

  testWidgets('email sign-in is a small secondary text link', (tester) async {
    await _pumpLogin(tester, const Locale('ko'));

    final emailLabel = find.text('이메일로 계속하기');
    expect(emailLabel, findsOneWidget);
    // Was a full-width outlined button next to Google/Apple.
    expect(
      find.ancestor(of: emailLabel, matching: find.byType(OutlinedButton)),
      findsNothing,
    );
    expect(
      find.ancestor(of: emailLabel, matching: find.byType(TextButton)),
      findsOneWidget,
    );
    final style = tester.widget<Text>(emailLabel).style!;
    expect(style.fontSize, lessThan(16));
  });
}
