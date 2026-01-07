import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_enum.dart';
import 'routes/app_router.dart';
import 'providers/app_settings_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/repository_provider.dart';
import 'core/services/notification_service.dart';
import 'services/notification_service.dart' as local_notifications;

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Edge-to-edge를 위한 시스템 UI 오버레이 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Edge-to-edge 활성화
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Ignore duplicate app initialization error
    debugPrint('Firebase init error (ignored): $e');
  }

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Initialize Notification Service (FCM)
  // We don't await this to avoid blocking UI startup,
  // but it's fine to fire and forget or await if critical.
  // Generally permission request might block, but we handle that in initialize().
  // Using fire-and-forget here to let app start.
  container.read(notificationServiceProvider).initialize();

  // Initialize Local Notification Service (Plan Reminders)
  await local_notifications.NotificationService().init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OnMyBehalfApp(),
    ),
  );
}

class OnMyBehalfApp extends ConsumerWidget {
  const OnMyBehalfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    // 현재 테마에 따라 ThemeData 가져오기
    final themeData = settingsState.currentTheme == AppThemeType.smokyPlum
        ? AppTheme.smokyPlumTheme
        : AppTheme.deepOliveTheme;

    return AppSettings(
      state: settingsState,
      notifier: settingsNotifier,
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        theme: themeData,
        locale: settingsState.currentLocale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('ko', ''), // Korean
        ],
        routerConfig: appRouter,
      ),
    );
  }
}
