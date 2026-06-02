import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_enum.dart';

class AppTheme {
  AppTheme._();

  /// 현재 테마(`AppColors.currentTheme`)에 따른 ThemeData.
  static ThemeData get lightTheme => themeOf(AppColors.currentTheme);

  /// 특정 테마의 ThemeData. main.dart에서 settingsState를 보고 직접 호출한다.
  static ThemeData themeOf(AppThemeType type) =>
      _buildTheme(AppColors.paletteFor(type));

  static ThemeData _buildTheme(ThemePalette palette) {
    // Material Design 3 ColorScheme — seed로 자동 팔레트 생성 후 우리 토큰으로 덮어쓴다.
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.light,
    );

    final colorScheme = baseColorScheme.copyWith(
      primary: palette.primary,
      secondary: palette.secondary,
      surface: palette.surface,
      onPrimary: Colors.white,
      onSecondary: palette.textPrimary,
      onSurface: palette.textPrimary,
      outline: palette.outline,
      outlineVariant: palette.divider,
      error: baseColorScheme.error,
      onError: baseColorScheme.onError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Pretendard',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: palette.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: palette.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: palette.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: palette.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: palette.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: palette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: palette.divider, thickness: 1),
    );
  }

  // --- Convenience accessors (각 테마의 ThemeData 단축 getter) ---
  static ThemeData get smokyPlumTheme => themeOf(AppThemeType.smokyPlum);
  static ThemeData get deepOliveTheme => themeOf(AppThemeType.deepOlive);
  static ThemeData get pacificTheme => themeOf(AppThemeType.pacific);
  static ThemeData get roseMochaTheme => themeOf(AppThemeType.roseMocha);
  static ThemeData get lavenderDuskTheme => themeOf(AppThemeType.lavenderDusk);

  /// Dark mode (향후 구현)
  static ThemeData get darkTheme {
    final baseDarkColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    final darkColorScheme = baseDarkColorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      error: baseDarkColorScheme.error,
      onError: baseDarkColorScheme.onError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }
}
