import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'providers/app_settings_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/repository_provider.dart';
import 'utils/context_free_l10n.dart' show setContextFreeLocaleCode;
import 'core/services/app_version_gate.dart';
import 'core/services/client_metadata_sync.dart';
import 'core/services/notification_service.dart';
import 'features/proof/data/proof_photo_cache.dart';
import 'features/connect/application/partner_link_binder.dart';
import 'features/plan/application/reminder_copy_refresh.dart';
import 'features/onboarding/domain/onboarding_gate.dart';
import 'services/notification_service.dart' as local_notifications;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/error_reporter.dart';
import 'utils/analytics.dart';
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

  // Capture uncaught Flutter + async errors in Crashlytics once Firebase is up.
  await ErrorReporter.initialize();

  // Product analytics (collection disabled in debug, same as Crashlytics).
  await AnalyticsService.initialize();

  final prefs = await SharedPreferences.getInstance();

  // Before the tutorial or sign-in write their flags: remember whether this
  // device ran the app before it became 둘운완 (one-time rename notice, no
  // invite step for existing users).
  recordDeviceCohort(prefs);

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
  // - 권한 요청은 의미 있는 시점(짝꿍 연결, 초대 공유, 약속 알림 설정)에서 명시 호출한다.
  // - 권한이 이미 grant된 상태면 FCM 토큰만 등록한다 (로그인 후에는
  //   fcmTokenBinderProvider 가 다시 등록한다).
  binding.addPostFrameCallback((_) {
    unawaited(local_notifications.NotificationService().init());
    unawaited(
      container
          .read(notificationServiceProvider)
          .setupListenersAndMaybeRegister(),
    );
  });
}

class OnMyBehalfApp extends ConsumerWidget {
  const OnMyBehalfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    // Repository·알림처럼 BuildContext 밖에서 만드는 문구도 사용자의 명시적
    // locale 선택을 따르도록 매 빌드마다 현재 locale 코드를 동기화한다.
    // null이면 시스템 로케일로 fallback.
    setContextFreeLocaleCode(settingsState.currentLocale?.languageCode);

    // users/{uid}.clientBuild/timezone/locale — written only when they change.
    ref.watch(clientMetadataSyncBinderProvider);

    // The FCM token for whoever signs in (the launch registration runs before
    // sign-in on a fresh install).
    ref.watch(fcmTokenBinderProvider);

    // Cached proof photos are dropped when the couple disconnects or the
    // account changes, so an ex-partner's photos don't stay on the device.
    ref.watch(proofPhotoCacheBinderProvider);

    // partner_connected {role} on every live link, and the nickname for an
    // ex-partner dropped when the link goes away.
    ref.watch(partnerLinkBinderProvider);

    // Once after upgrading to the pivot build: reschedule plan reminders so
    // the old copy already queued for the next weeks is replaced.
    ref.watch(reminderCopyRefreshBinderProvider);

    // Queued reminders follow the link: partner line added after linking,
    // dropped after unlinking, renamed with the nickname.
    ref.watch(reminderLinkRefreshBinderProvider);

    // 현재 테마에 따라 ThemeData 가져오기 (5개 테마 모두 지원)
    final themeData = AppTheme.themeOf(settingsState.currentTheme);

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
        // Minimum-version gate sits above the router so the auth/profile
        // redirect flow is untouched; it passes [child] through unless the
        // remote config says this build must (or should) update.
        builder: (context, child) =>
            AppVersionGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
