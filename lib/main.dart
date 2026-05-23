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
import 'repositories/real_record_repository.dart' show setRepositoryLocaleCode;
import 'core/services/notification_service.dart';
import 'services/notification_service.dart' as local_notifications;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    return;
  }
  await local_notifications.NotificationService().init();
  await local_notifications.NotificationService().showRemoteMessageNotification(
    message,
  );
}

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('dotenv load error (ignored): $e');
  }

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

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OnMyBehalfApp(),
    ),
  );

  // 첫 프레임이 뜬 뒤 백그라운드에서 알림 초기화 (권한 다이얼로그는 띄우지 않음).
  // - 권한 요청은 약속 알림 설정 시점(SettingAlarmUseCase)에서 명시 호출한다.
  // - 권한이 이미 grant된 상태면 FCM 토큰만 등록한다.
  binding.addPostFrameCallback((_) {
    unawaited(local_notifications.NotificationService().init());
    unawaited(
      container.read(notificationServiceProvider).setupListenersAndMaybeRegister(),
    );
  });
}

class OnMyBehalfApp extends ConsumerWidget {
  const OnMyBehalfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    // Repository가 BuildContext 밖에서도 사용자의 명시적 locale 선택을 따르도록
    // 매 빌드마다 현재 locale 코드를 모듈 전역에 동기화한다.
    // null이면 repository 쪽에서 시스템 로케일로 fallback.
    setRepositoryLocaleCode(settingsState.currentLocale?.languageCode);

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
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
