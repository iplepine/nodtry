import 'dart:ui' show Locale, PlatformDispatcher;

import '../l10n/app_localizations.dart';

/// Localized copy for code that runs outside the widget tree.
///
/// Repositories, notification handlers and background isolates have no
/// `BuildContext`, so they cannot call `AppLocalizations.of`. They used to keep
/// their own `isKo ? '…' : '…'` strings, which drifted from the ARB copy. This
/// resolves the same ARB strings by language code instead.
///
/// The language is the one picked in Settings when the app root has reported
/// it ([setContextFreeLocaleCode]); otherwise the device language. Anything
/// other than Korean falls back to English, matching the supported locales.

String? _appLocaleCode;

/// Called from the app root whenever the Settings language changes. `null`
/// means "follow the device".
void setContextFreeLocaleCode(String? code) {
  _appLocaleCode = code;
}

/// `'ko'` or `'en'`: the language context-free copy should use right now.
String contextFreeLanguageCode() {
  final code =
      _appLocaleCode ?? PlatformDispatcher.instance.locale.languageCode;
  return code.startsWith('ko') ? 'ko' : 'en';
}

/// The app strings for [contextFreeLanguageCode].
AppLocalizations contextFreeL10n() =>
    lookupAppLocalizations(Locale(contextFreeLanguageCode()));
