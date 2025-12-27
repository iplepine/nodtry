import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.warmCoral,
        surface: AppColors.lightSand,
        onPrimary: AppColors.primaryText,
        onSurface: AppColors.primaryText,
      ),
      scaffoldBackgroundColor: AppColors.warmOffWhite,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.primaryText,
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: AppColors.primaryText,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: AppColors.primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: AppColors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: AppColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: AppColors.primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmCoral,
          foregroundColor: AppColors.primaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSand,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

