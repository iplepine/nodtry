import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_enum.dart';
import 'repository_provider.dart';

part 'app_settings_provider.freezed.dart';

/// SharedPreferences key for the user's explicit locale override.
/// Stored as the language code ("ko", "en"). Absent or empty = follow system.
const _kLocaleOverrideKey = 'app.locale_override';

@freezed
abstract class AppSettingsState with _$AppSettingsState {
  const factory AppSettingsState({
    @Default(AppThemeType.smokyPlum) AppThemeType currentTheme,
    // null = follow device locale (resolved by Flutter via supportedLocales).
    // non-null = user explicitly overrode in Settings (persisted to prefs).
    @Default(null) Locale? currentLocale,
  }) = _AppSettingsState;
}

/// 앱 설정 상태 관리 (테마, 언어)
class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_kLocaleOverrideKey);
    Locale? initialLocale;
    if (stored != null && stored.isNotEmpty) {
      initialLocale = Locale(stored, '');
    }
    return AppSettingsState(currentLocale: initialLocale);
  }

  /// 테마 변경
  void setTheme(AppThemeType theme) {
    if (state.currentTheme != theme) {
      state = state.copyWith(currentTheme: theme);
      AppColors.setTheme(theme);
    }
  }

  /// 언어 변경 — 사용자가 명시적으로 고른 값을 prefs에 persist 한다.
  /// null을 넘기면 override를 비우고 시스템 로케일을 따라가도록 한다.
  void setLocale(Locale? locale) {
    if (state.currentLocale == locale) return;
    state = state.copyWith(currentLocale: locale);
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      prefs.remove(_kLocaleOverrideKey);
    } else {
      prefs.setString(_kLocaleOverrideKey, locale.languageCode);
    }
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
      AppSettingsNotifier.new,
    );

// Keep this for now to avoid breaking context-based access if any remains,
// but it should be migrated to ref.watch(appSettingsProvider).
class AppSettings extends InheritedWidget {
  final AppSettingsState state;
  final AppSettingsNotifier notifier;

  const AppSettings({
    super.key,
    required this.state,
    required this.notifier,
    required super.child,
  });

  static AppSettingsState of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppSettings>();
    if (widget == null) {
      throw Exception('AppSettings not found in widget tree');
    }
    return widget.state;
  }

  @override
  bool updateShouldNotify(AppSettings oldWidget) {
    return state != oldWidget.state;
  }
}
