import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/settings/presentation/screens/settings_screen.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/providers/app_settings_provider.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/theme/app_theme_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 둘운완 ships a single brand palette: no theme picker, and a theme picked in
/// an older version must not keep the user on a non-brand palette.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'app.theme': 'deepOlive'});
    prefs = await SharedPreferences.getInstance();
  });

  test('a stored non-default theme is ignored at startup', () {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(appSettingsProvider).currentTheme,
      AppThemeType.smokyPlum,
    );
  });

  testWidgets('the settings screen has no theme picker', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ko')],
          locale: Locale('ko'),
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The language section still renders, the theme section does not.
    expect(find.text(l10n.settingsLanguage), findsOneWidget);
    expect(find.text(l10n.settingsTheme), findsNothing);
    expect(find.text(l10n.settingsThemeDeepOlive), findsNothing);
    expect(find.text(l10n.settingsThemeSmokyPlum), findsNothing);
  });
}
