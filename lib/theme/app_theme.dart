import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_enum.dart';

class AppTheme {
  AppTheme._();

  /// 현재 테마에 따른 ThemeData 반환
  static ThemeData get lightTheme {
    return _buildTheme(AppColors.currentTheme);
  }

  /// 특정 테마의 ThemeData 반환
  static ThemeData _buildTheme(AppThemeType themeType) {
    // 테마 타입에 따라 직접 색상 가져오기
    final colors = _getColorsForTheme(themeType);

    // Material Design 3 ColorScheme 생성
    // seed color를 기반으로 전체 색상 팔레트 자동 생성
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.light,
    );

    // 디자인 스펙에 맞게 커스텀 색상으로 오버라이드
    // Material Design 3: background는 deprecated, surface 사용
    final colorScheme = baseColorScheme.copyWith(
      primary: colors.primary,
      secondary: colors.secondary,
      surface: colors.surface,
      onPrimary: Colors.white,
      onSecondary: colors.textPrimary,
      onSurface: colors.textPrimary,
      outline: colors.outline,
      outlineVariant: colors.divider,
      error: baseColorScheme.error, // Material 3 기본 에러 색상 사용
      onError: baseColorScheme.onError,
    );

    final themeData = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background, // 커스텀 배경색 유지
      fontFamily: 'Pretendard', // 기본 한글 폰트
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: colors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: colors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Soft radius (8~12dp)
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface, // Soft Stone
        elevation: 0, // 그림자 ❌
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
    );

    return themeData;
  }

  /// 특정 테마 타입에 대한 색상 팔레트 반환
  static _ThemeColors _getColorsForTheme(AppThemeType themeType) {
    switch (themeType) {
      case AppThemeType.smokyPlum:
        return _ThemeColors(
          background: const Color(0xFFEEEAE6), // Dark Warm Stone
          surface: const Color(0xFFDFD9D4), // Soft Dark Stone
          primary: const Color(0xFF552A3E), // Velvet Wine Plum
          secondary: const Color(0xFFC9C1BB), // Secondary
          outline: const Color(0xFFCCC4BE), // Outline
          divider: const Color(0xFFD2CBC6), // Stone Line
          textPrimary: const Color(0xFF201A1D),
          textSecondary: const Color(0xFF6E6469),
        );
      case AppThemeType.deepOlive:
        return _ThemeColors(
          background: const Color(0xFFF3F1ED), // Soft Sand
          surface: const Color(0xFFE7E3DC), // Warm Sand
          primary: const Color(0xFF5F6F63), // Deep Olive
          secondary: const Color(0xFFD2CCC3), // Pale Sand
          outline: const Color(0xFFDED8D0), // Sand Line
          divider: const Color(0xFFDED8D0), // Sand Line
          textPrimary: const Color(0xFF2E2F2C),
          textSecondary: const Color(0xFF767A74),
        );
    }
  }

  /// Smoky Plum 테마
  static ThemeData get smokyPlumTheme => _buildTheme(AppThemeType.smokyPlum);

  /// Deep Olive 테마
  static ThemeData get deepOliveTheme => _buildTheme(AppThemeType.deepOlive);

  // Dark Mode Theme (향후 구현)
  static ThemeData get darkTheme {
    // Material Design 3 ColorScheme 생성 (다크 모드)
    final baseDarkColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    final darkColorScheme = baseDarkColorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface, // #2A2328
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      error: baseDarkColorScheme.error,
      onError: baseDarkColorScheme.onError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground, // 커스텀 배경색 유지
      // ... 기타 다크 모드 설정
    );
  }
}

/// 테마별 색상 팔레트
class _ThemeColors {
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color outline;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;

  _ThemeColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.outline,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
  });
}
