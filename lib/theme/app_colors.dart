import 'package:flutter/material.dart';
import 'app_theme_enum.dart';

/// OnMyBehalf Color System — Multi-Theme Support
///
/// Theme A: Smoky Plum × Warm Stone
/// "우리가 서로를 맡기는 관계"의 색
///
/// Theme B: Deep Olive × Sand
/// 단단함 · 책임감 · 안정적인 섹시함
class AppColors {
  AppColors._();

  // 현재 선택된 테마 (기본값: Smoky Plum)
  static AppThemeType _currentTheme = AppThemeType.smokyPlum;

  /// 현재 테마 설정
  static AppThemeType get currentTheme => _currentTheme;

  /// 테마 변경
  static void setTheme(AppThemeType theme) {
    _currentTheme = theme;
  }

  // ============================================
  // Theme A: Velvet Wine Plum × Dark Stone
  // "집중하게 만드는 관리자 색"
  // ============================================
  static const Color _smokyPlumBackground = Color(
    0xFFEEEAE6,
  ); // Dark Warm Stone
  static const Color _smokyPlumSurface = Color(0xFFDFD9D4); // Soft Dark Stone
  static const Color _smokyPlumPrimary = Color(0xFF552A3E); // Velvet Wine Plum
  static const Color _smokyPlumPrimaryPressed = Color(
    0xFF462232,
  ); // Deep Velvet Wine
  static const Color _smokyPlumPrimarySoft = Color(
    0xFF6E4156,
  ); // Muted Wine Plum (≤5%)
  static const Color _smokyPlumSecondary = Color(0xFFC9C1BB); // Secondary
  static const Color _smokyPlumOutline = Color(0xFFCCC4BE); // Outline
  static const Color _smokyPlumDivider = Color(0xFFD2CBC6); // Stone Line
  static const Color _smokyPlumDisabled = Color(0xFFB5ADA8); // Disabled
  static const Color _smokyPlumTextPrimary = Color(0xFF201A1D);
  static const Color _smokyPlumTextSecondary = Color(0xFF6E6469);
  static const Color _smokyPlumTextDisabled = Color(0xFFA29A9E);
  static const Color _smokyPlumAccentWine = Color(
    0xFF6A1F2B,
  ); // Accent Wine (≤5%)
  static const Color _smokyPlumAccentInkViolet = Color(
    0xFF3A2A46,
  ); // Accent Ink Violet (포커스/전환, ≤400ms)

  // ============================================
  // Theme B: Deep Olive × Sand
  // ============================================
  static const Color _deepOliveBackground = Color(0xFFF3F1ED); // Soft Sand
  static const Color _deepOliveSurface = Color(0xFFE7E3DC); // Warm Sand
  static const Color _deepOlivePrimary = Color(0xFF5F6F63); // Deep Olive
  static const Color _deepOlivePrimaryPressed = Color(0xFF4E5C52); // Dark Olive
  static const Color _deepOliveSecondary = Color(0xFFD2CCC3); // Pale Sand
  static const Color _deepOliveDivider = Color(0xFFDED8D0); // Sand Line
  static const Color _deepOliveTextPrimary = Color(0xFF2E2F2C);
  static const Color _deepOliveTextSecondary = Color(0xFF767A74);
  static const Color _deepOliveTextDisabled = Color(0xFFB1B4AE);

  // ============================================
  // Core Palette Getters (현재 테마에 따라 반환)
  // ============================================

  static Color get background {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumBackground;
      case AppThemeType.deepOlive:
        return _deepOliveBackground;
    }
  }

  static Color get surface {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumSurface;
      case AppThemeType.deepOlive:
        return _deepOliveSurface;
    }
  }

  static Color get primary {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumPrimary;
      case AppThemeType.deepOlive:
        return _deepOlivePrimary;
    }
  }

  static Color get primaryPressed {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumPrimaryPressed;
      case AppThemeType.deepOlive:
        return _deepOlivePrimaryPressed;
    }
  }

  static Color get secondary {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumSecondary;
      case AppThemeType.deepOlive:
        return _deepOliveSecondary;
    }
  }

  static Color get outline {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumOutline;
      case AppThemeType.deepOlive:
        return _deepOliveDivider; // Deep Olive에는 별도 outline 없음
    }
  }

  static Color get disabled {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumDisabled;
      case AppThemeType.deepOlive:
        return _deepOliveTextDisabled; // Deep Olive에는 별도 disabled 없음
    }
  }

  static Color get divider {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumDivider;
      case AppThemeType.deepOlive:
        return _deepOliveDivider;
    }
  }

  // ============================================
  // Text Colors Getters
  // ============================================

  static Color get textPrimary {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumTextPrimary;
      case AppThemeType.deepOlive:
        return _deepOliveTextPrimary;
    }
  }

  static Color get textSecondary {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumTextSecondary;
      case AppThemeType.deepOlive:
        return _deepOliveTextSecondary;
    }
  }

  static Color get textDisabled {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumTextDisabled;
      case AppThemeType.deepOlive:
        return _deepOliveTextDisabled;
    }
  }

  // ============================================
  // Accent Colors (Theme A only)
  // ============================================

  /// Accent Wine - 아이콘·선택 상태 (≤5%)
  static Color get accentWine {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumAccentWine;
      case AppThemeType.deepOlive:
        return _deepOlivePrimary; // Deep Olive에는 accent 없음
    }
  }

  /// Accent Ink Violet - 포커스/전환 순간 (≤400ms)
  static Color get accentInkViolet {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumAccentInkViolet;
      case AppThemeType.deepOlive:
        return _deepOlivePrimary; // Deep Olive에는 accent 없음
    }
  }

  /// Primary Soft - 배지·포커스 (제한적, ≤5%)
  static Color get primarySoft {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumPrimarySoft;
      case AppThemeType.deepOlive:
        return _deepOlivePrimary; // Deep Olive에는 primarySoft 없음
    }
  }

  // ============================================
  // Dark Mode Colors (향후 구현)
  // ============================================

  static const Color darkBackgroundSmokyPlum = Color(0xFF1E1A1D);
  static const Color darkSurfaceSmokyPlum = Color(0xFF2A2328);

  static Color get darkBackground {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return darkBackgroundSmokyPlum;
      case AppThemeType.deepOlive:
        // TODO: Deep Olive 다크 모드 색상 정의
        return darkBackgroundSmokyPlum;
    }
  }

  static Color get darkSurface {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
        return darkSurfaceSmokyPlum;
      case AppThemeType.deepOlive:
        // TODO: Deep Olive 다크 모드 색상 정의
        return darkSurfaceSmokyPlum;
    }
  }

  // ============================================
  // Legacy colors (하위 호환성, 추후 제거 예정)
  // ============================================

  @Deprecated('Use background instead')
  static Color get neutral99 => background;

  @Deprecated('Use surface instead')
  static Color get secondary90 => surface;

  @Deprecated('Use textPrimary instead')
  static Color get neutral10 => textPrimary;

  @Deprecated('Use textSecondary instead')
  static Color get neutral40 => textSecondary;

  @Deprecated('Use primary instead')
  static Color get primary70 => primary;

  @Deprecated('Use primaryPressed instead')
  static Color get primary60 => primaryPressed;

  @Deprecated('Use background instead')
  static Color get warmOffWhite => background;

  @Deprecated('Use surface instead')
  static Color get lightSand => surface;

  @Deprecated('Use textPrimary instead')
  static Color get primaryText => textPrimary;

  @Deprecated('Use textSecondary instead')
  static Color get secondaryText => textSecondary;

  @Deprecated('Use textDisabled instead')
  static Color get neutral50 => textDisabled;

  @Deprecated('Use primary instead')
  static Color get warmCoral => primary;

  @Deprecated('Use primary instead')
  static Color get softSageGreen => primary;

  // ============================================
  // Status Colors
  // ============================================

  static const Color _success = Color(0xFF6B8E23); // Warm Olive Green
  static const Color _error = Color(0xFFD32F2F); // Standard Error Red

  static Color get success => _success;
  static Color get error => _error;
}
