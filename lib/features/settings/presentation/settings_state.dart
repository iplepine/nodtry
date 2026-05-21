import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nod_try/theme/app_theme_enum.dart';

part 'settings_state.freezed.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    // null = follow system locale (no explicit user override).
    Locale? currentLocale,
    required AppThemeType currentTheme,
    @Default(false) bool isWithdrawing,
    String? errorMessage,
  }) = _SettingsState;
}

sealed class SettingsIntent {
  const SettingsIntent();
}

class ChangeLocaleIntent extends SettingsIntent {
  final Locale locale;
  const ChangeLocaleIntent(this.locale);
}

class ChangeThemeIntent extends SettingsIntent {
  final AppThemeType theme;
  const ChangeThemeIntent(this.theme);
}

class WithdrawAccountIntent extends SettingsIntent {
  const WithdrawAccountIntent();
}

class LogoutIntent extends SettingsIntent {
  const LogoutIntent();
}

