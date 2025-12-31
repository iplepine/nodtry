import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_enum.dart';

/// 앱 설정 상태 관리 (테마, 언어)
class AppSettingsProvider extends ChangeNotifier {
  // 현재 테마
  AppThemeType _currentTheme = AppThemeType.smokyPlum;

  // 현재 언어
  Locale _currentLocale = const Locale('ko', '');

  AppThemeType get currentTheme => _currentTheme;
  Locale get currentLocale => _currentLocale;

  /// 테마 변경
  void setTheme(AppThemeType theme) {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      AppColors.setTheme(theme);
      notifyListeners();
    }
  }

  /// 언어 변경
  void setLocale(Locale locale) {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      notifyListeners();
    }
  }
}

/// InheritedWidget을 통한 Provider 패턴
class AppSettings extends InheritedWidget {
  final AppSettingsProvider provider;

  const AppSettings({super.key, required this.provider, required super.child});

  static AppSettingsProvider of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppSettings>();
    if (widget == null) {
      throw Exception('AppSettings not found in widget tree');
    }
    return widget.provider;
  }

  @override
  bool updateShouldNotify(AppSettings oldWidget) {
    return provider != oldWidget.provider;
  }
}
