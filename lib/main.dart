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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: OnMyBehalfApp()));
}

class OnMyBehalfApp extends StatefulWidget {
  const OnMyBehalfApp({super.key});

  @override
  State<OnMyBehalfApp> createState() => _OnMyBehalfAppState();
}

class _OnMyBehalfAppState extends State<OnMyBehalfApp> {
  final AppSettingsProvider _settingsProvider = AppSettingsProvider();

  @override
  void initState() {
    super.initState();
    _settingsProvider.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsProvider.removeListener(_onSettingsChanged);
    _settingsProvider.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {
      // 테마나 언어가 변경되면 앱을 다시 빌드
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppSettings(
      provider: _settingsProvider,
      child: Builder(
        builder: (context) {
          // 현재 테마에 따라 ThemeData 가져오기
          final themeData =
              _settingsProvider.currentTheme == AppThemeType.smokyPlum
              ? AppTheme.smokyPlumTheme
              : AppTheme.deepOliveTheme;

          return MaterialApp.router(
            title: 'IfTogether',
            debugShowCheckedModeBanner: false,
            theme: themeData,
            locale: _settingsProvider.currentLocale,
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
          );
        },
      ),
    );
  }
}
