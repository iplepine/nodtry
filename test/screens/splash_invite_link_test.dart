import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/auth/presentation/auth_state.dart';
import 'package:nod_try/features/auth/presentation/screens/splash_screen.dart';
import 'package:nod_try/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:nod_try/features/connect/application/invite_link_binder.dart';
import 'package:nod_try/features/onboarding/domain/onboarding_gate.dart';
import 'package:nod_try/features/tutorial/presentation/tutorial_screen.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the login screen on screen: no Firebase, no auto-login.
class _IdleAuthViewModel extends AuthViewModel {
  @override
  Future<void> dispatch(AuthIntent intent) async {}
}

Future<ProviderContainer> _pumpSplash(
  WidgetTester tester,
  Map<String, Object> prefs,
) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer(
    overrides: [authViewModelProvider.overrideWith(_IdleAuthViewModel.new)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('cold start from an invite link skips the tutorial', (
    tester,
  ) async {
    // What stashLaunchInviteLink keeps before the first frame.
    await _pumpSplash(tester, {
      OnboardingPrefKeys.pendingCodeEntry: true,
      OnboardingPrefKeys.pendingInviteCode: 'K7MP2QXR',
      OnboardingPrefKeys.pendingInviteSource: 'link',
    });

    expect(find.byType(TutorialScreen), findsNothing);
    expect(find.text('Google 계정으로 계속하기'), findsOneWidget);
  });

  testWidgets('an invite link opened during the tutorial leaves it', (
    tester,
  ) async {
    final container = await _pumpSplash(tester, {});
    expect(find.byType(TutorialScreen), findsOneWidget);

    container.read(openedInviteLinkProvider.notifier).record('K7MP2QXR');
    await tester.pumpAndSettle();

    expect(find.byType(TutorialScreen), findsNothing);
    expect(find.text('Google 계정으로 계속하기'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(OnboardingStore(prefs).pendingCodeEntry, isTrue);
  });
}
