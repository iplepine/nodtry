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
    // 테마 변경
    final previousTheme = AppColors.currentTheme;
    AppColors.setTheme(themeType);
    
    final themeData = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        onPrimary: Colors.white,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Smoky Plum
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Soft radius (8~12dp)
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface, // Soft Stone
        elevation: 0, // 그림자 ❌
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
    
    // 원래 테마로 복원
    AppColors.setTheme(previousTheme);
    
    return themeData;
  }

  /// Smoky Plum 테마
  static ThemeData get smokyPlumTheme => _buildTheme(AppThemeType.smokyPlum);

  /// Deep Olive 테마
  static ThemeData get deepOliveTheme => _buildTheme(AppThemeType.deepOlive);

  // Dark Mode Theme (향후 구현)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary, // Smoky Plum 유지
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface, // #2A2328
        background: AppColors.darkBackground, // #1E1A1D
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      // ... 기타 다크 모드 설정
    );
  }
}
