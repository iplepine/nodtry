import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_enum.dart';

part 'app_settings_provider.freezed.dart';

@freezed
abstract class AppSettingsState with _$AppSettingsState {
  const factory AppSettingsState({
    @Default(AppThemeType.smokyPlum) AppThemeType currentTheme,
    @Default(Locale('ko', '')) Locale currentLocale,
  }) = _AppSettingsState;
}

/// 앱 설정 상태 관리 (테마, 언어)
class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    return const AppSettingsState();
  }

  /// 테마 변경
  void setTheme(AppThemeType theme) {
    if (state.currentTheme != theme) {
      state = state.copyWith(currentTheme: theme);
      AppColors.setTheme(theme);
    }
  }

  /// 언어 변경
  void setLocale(Locale locale) {
    if (state.currentLocale != locale) {
      state = state.copyWith(currentLocale: locale);
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
