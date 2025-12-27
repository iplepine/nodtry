// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'OnMyBehalf';

  @override
  String get splashTagline => '혼자서 지키지 못했던 계획을, 함께';

  @override
  String get loginWithGoogle => 'Google로 시작하기';

  @override
  String get loginWithApple => 'Apple로 시작하기';

  @override
  String get privacyMessage => '강요하지 않아요. 기록은 둘만 봅니다.';
}
