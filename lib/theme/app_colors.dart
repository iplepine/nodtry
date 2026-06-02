import 'package:flutter/material.dart';
import 'app_theme_enum.dart';

/// 테마 단위 색 토큰 묶음.
///
/// 화면 어디서나 `AppColors.xxx`로 읽지만, 실제 값은 `_palette`에 보관된 이
/// immutable struct에서 가져온다. 토큰을 새로 추가해도 모든 getter switch를
/// 손볼 필요 없이 이 한 곳만 늘리면 된다.
@immutable
class ThemePalette {
  // --- 표면/배경 ---
  final Color background;
  final Color surface;
  final Color outline;
  final Color divider;
  final Color disabled;

  // --- Primary ---
  final Color primary;
  final Color primaryPressed;
  final Color primarySoft;

  // --- Secondary / Accent ---
  /// 의미상 "accent". 텍스트/아이콘으로 쓰일 수 있어야 하므로 surface 위에서
  /// 대비가 충분해야 한다. (deepOlive의 옛 #D2CCC3 같은 sand-on-sand는 ❌)
  final Color secondary;
  final Color accentWine; // 짙은 accent, 강한 강조 텍스트
  final Color accentInkViolet; // 옅은 accent, 힌트 배경

  // --- Text ---
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  // --- Warning / Penalty 칩 (3-layer) ---
  final Color warningSoft;
  final Color warningBorder;
  final Color warningStrong;

  // --- Notice banner (게스트 안내 등) ---
  final Color noticeBackground;
  final Color noticeBorder;
  final Color noticeText;

  // --- Misc semantic ---
  final Color restTone; // 휴식 캘린더 셀
  final Color neutralBadge; // 약한 상태 배지

  // --- Time chip ---
  final Color timeChipNowBackground;
  final Color timeChipNeutralBackground;
  final Color timeChipNowText;
  final Color timeChipMutedText;

  // --- Plan state badge (pendingApproval 등) ---
  final Color pendingBadgeFill;
  final Color pendingBadgeText;

  const ThemePalette({
    required this.background,
    required this.surface,
    required this.outline,
    required this.divider,
    required this.disabled,
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.secondary,
    required this.accentWine,
    required this.accentInkViolet,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.warningSoft,
    required this.warningBorder,
    required this.warningStrong,
    required this.noticeBackground,
    required this.noticeBorder,
    required this.noticeText,
    required this.restTone,
    required this.neutralBadge,
    required this.timeChipNowBackground,
    required this.timeChipNeutralBackground,
    required this.timeChipNowText,
    required this.timeChipMutedText,
    required this.pendingBadgeFill,
    required this.pendingBadgeText,
  });
}

/// Nodtry Color System - Multi-Theme Support (5 palettes)
///
/// - Mint × Orange  (`smokyPlum`)   : 차분 + 행동 강조
/// - Deep Olive × Sand (`deepOlive`): 단단함 · 책임감
/// - Pacific (`pacific`)            : 바다 + 산호 — 활기, 청량
/// - Rose Mocha (`roseMocha`)       : 더스티 로즈 + 크림 — 따뜻함, 편안
/// - Lavender Dusk (`lavenderDusk`) : 라벤더 + 머스타드 골드 — 차분한 우아함
class AppColors {
  AppColors._();

  /// 현재 활성 palette. setTheme에서 swap.
  static ThemePalette _palette = _smokyPlumPalette;
  static AppThemeType _currentTheme = AppThemeType.smokyPlum;

  /// 현재 테마 설정
  static AppThemeType get currentTheme => _currentTheme;

  /// 테마 변경 (palette 도 함께 swap)
  static void setTheme(AppThemeType theme) {
    _currentTheme = theme;
    _palette = paletteFor(theme);
  }

  /// 특정 테마의 palette 조회 — `AppTheme._buildTheme`에서 ThemeData 만들 때 사용.
  static ThemePalette paletteFor(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.smokyPlum:
        return _smokyPlumPalette;
      case AppThemeType.deepOlive:
        return _deepOlivePalette;
      case AppThemeType.pacific:
        return _pacificPalette;
      case AppThemeType.roseMocha:
        return _roseMochaPalette;
      case AppThemeType.lavenderDusk:
        return _lavenderDuskPalette;
    }
  }

  // ============================================
  // Status colors (테마 불변)
  // ============================================
  static const Color _success = Color(0xFF6B8E23); // Warm Olive Green
  static const Color _error = Color(0xFFD32F2F); // Standard Error Red

  static Color get success => _success;
  static Color get error => _error;

  // ============================================
  // Dark mode placeholders (향후 구현)
  // ============================================
  static const Color darkBackgroundSmokyPlum = Color(0xFF1E1A1D);
  static const Color darkSurfaceSmokyPlum = Color(0xFF2A2328);
  static const Color darkBackgroundDeepOlive = Color(0xFF1A1C1A);
  static const Color darkSurfaceDeepOlive = Color(0xFF252825);

  static Color get darkBackground {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
      case AppThemeType.pacific:
      case AppThemeType.lavenderDusk:
        return darkBackgroundSmokyPlum;
      case AppThemeType.deepOlive:
      case AppThemeType.roseMocha:
        return darkBackgroundDeepOlive;
    }
  }

  static Color get darkSurface {
    switch (_currentTheme) {
      case AppThemeType.smokyPlum:
      case AppThemeType.pacific:
      case AppThemeType.lavenderDusk:
        return darkSurfaceSmokyPlum;
      case AppThemeType.deepOlive:
      case AppThemeType.roseMocha:
        return darkSurfaceDeepOlive;
    }
  }

  // ============================================
  // Delegating getters (current palette)
  // ============================================

  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get outline => _palette.outline;
  static Color get divider => _palette.divider;
  static Color get disabled => _palette.disabled;

  static Color get primary => _palette.primary;
  static Color get primaryPressed => _palette.primaryPressed;
  static Color get primarySoft => _palette.primarySoft;

  static Color get secondary => _palette.secondary;
  static Color get accentWine => _palette.accentWine;
  static Color get accentInkViolet => _palette.accentInkViolet;

  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textDisabled => _palette.textDisabled;

  static Color get warningSoft => _palette.warningSoft;
  static Color get warningBorder => _palette.warningBorder;
  static Color get warningStrong => _palette.warningStrong;

  static Color get noticeBackground => _palette.noticeBackground;
  static Color get noticeBorder => _palette.noticeBorder;
  static Color get noticeText => _palette.noticeText;

  static Color get restTone => _palette.restTone;
  static Color get neutralBadge => _palette.neutralBadge;

  static Color get timeChipNowBackground => _palette.timeChipNowBackground;
  static Color get timeChipNeutralBackground =>
      _palette.timeChipNeutralBackground;
  static Color get timeChipNowText => _palette.timeChipNowText;
  static Color get timeChipMutedText => _palette.timeChipMutedText;

  static Color get pendingBadgeFill => _palette.pendingBadgeFill;
  static Color get pendingBadgeText => _palette.pendingBadgeText;

  // ============================================
  // Theme A: Mint & Orange (smokyPlum)
  // ============================================
  static const ThemePalette _smokyPlumPalette = ThemePalette(
    background: Color(0xFFF8FAF7),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFD9E4DF),
    divider: Color(0xFFE3ECE8),
    disabled: Color(0xFFC5D0CC),
    primary: Color(0xFF18B7A0),
    primaryPressed: Color(0xFF0E7F70),
    primarySoft: Color(0xFFDDF8F2),
    secondary: Color(0xFFFF8A3D),
    accentWine: Color(0xFFC85A1E),
    accentInkViolet: Color(0xFFFFF0E5),
    textPrimary: Color(0xFF1D2B27),
    textSecondary: Color(0xFF66736F),
    textDisabled: Color(0xFF97A4A0),
    warningSoft: Color(0xFFFFF1E6),
    warningBorder: Color(0xFFFF8A3D),
    warningStrong: Color(0xFFB54708),
    noticeBackground: Color(0xFFFFF4E5),
    noticeBorder: Color(0xFFFFD180),
    noticeText: Color(0xFF5D4037),
    restTone: Color(0xFF7AB8C8),
    neutralBadge: Color(0xFFEBE6E1),
    timeChipNowBackground: Color(0xFFF28B82),
    timeChipNeutralBackground: Color(0xFFF2ECE7),
    timeChipNowText: Color(0xFF3F3A36),
    timeChipMutedText: Color(0xFF7A726C),
    pendingBadgeFill: Color(0x1AFF9800),
    pendingBadgeText: Color(0xFFEF6C00),
  );

  // ============================================
  // Theme B: Deep Olive × Sand (deepOlive)
  // ============================================
  //
  // Fix 메모:
  //   - 기존 secondary `#D2CCC3` (pale sand)는 surface(#E7E3DC) 위에서
  //     텍스트/아이콘 색으로 쓰일 때 거의 안 보였다. rust(#B45A37)로 교체.
  //   - surface는 background보다 더 옅은 톤(#FBF8F2)으로 올려서 카드 경계가
  //     자연스럽게 드러나도록 수정.
  //   - textSecondary는 #6F6A60로 약간 더 진하게 조정해 sand 배경에서 가독성 확보.
  static const ThemePalette _deepOlivePalette = ThemePalette(
    background: Color(0xFFF0EAE0), // warm sand canvas
    surface: Color(0xFFFBF8F2), // cream card
    outline: Color(0xFFDED8D0),
    divider: Color(0xFFDED8D0),
    disabled: Color(0xFFB1B4AE),
    primary: Color(0xFF5F6F63), // deep olive
    primaryPressed: Color(0xFF4E5C52),
    primarySoft: Color(0xFFD4DAD0), // light olive (배지/포커스)
    secondary: Color(0xFFB45A37), // rust — accent
    accentWine: Color(0xFF7A3E1F),
    accentInkViolet: Color(0xFFEFE2D3),
    textPrimary: Color(0xFF2E2F2C),
    textSecondary: Color(0xFF6F6A60),
    textDisabled: Color(0xFFB1B4AE),
    warningSoft: Color(0xFFEFE2D3),
    warningBorder: Color(0xFFB45A37),
    warningStrong: Color(0xFF7A3E1F),
    noticeBackground: Color(0xFFEFE2D3),
    noticeBorder: Color(0xFFC9A985),
    noticeText: Color(0xFF4A3A2A),
    restTone: Color(0xFF8A9590),
    neutralBadge: Color(0xFFE0DACE),
    timeChipNowBackground: Color(0xFFB45A37),
    timeChipNeutralBackground: Color(0xFFE0DACE),
    timeChipNowText: Color(0xFFFFFFFF),
    timeChipMutedText: Color(0xFF6F6A60),
    pendingBadgeFill: Color(0x1AB45A37),
    pendingBadgeText: Color(0xFF7A3E1F),
  );

  // ============================================
  // Theme C: Pacific — Ocean × Coral
  // ============================================
  static const ThemePalette _pacificPalette = ThemePalette(
    background: Color(0xFFF2F7FA),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFCFE0EA),
    divider: Color(0xFFDEE9F0),
    disabled: Color(0xFFB8C7D0),
    primary: Color(0xFF2E86AB), // ocean blue
    primaryPressed: Color(0xFF1B5E80),
    primarySoft: Color(0xFFD8EAF3),
    secondary: Color(0xFFF76F8E), // coral
    accentWine: Color(0xFFD45370),
    accentInkViolet: Color(0xFFFFEAEE),
    textPrimary: Color(0xFF122A35),
    textSecondary: Color(0xFF5B6F7B),
    textDisabled: Color(0xFF9AABB5),
    warningSoft: Color(0xFFFFEAEE),
    warningBorder: Color(0xFFF76F8E),
    warningStrong: Color(0xFFB33B5C),
    noticeBackground: Color(0xFFFFF4E5),
    noticeBorder: Color(0xFFFFD180),
    noticeText: Color(0xFF5D4037),
    restTone: Color(0xFF94B3D1),
    neutralBadge: Color(0xFFE6EEF3),
    timeChipNowBackground: Color(0xFFF76F8E),
    timeChipNeutralBackground: Color(0xFFECF2F6),
    timeChipNowText: Color(0xFFFFFFFF),
    timeChipMutedText: Color(0xFF677B86),
    pendingBadgeFill: Color(0x1AF76F8E),
    pendingBadgeText: Color(0xFFB33B5C),
  );

  // ============================================
  // Theme D: Rose Mocha — Dusty Rose × Cream
  // ============================================
  static const ThemePalette _roseMochaPalette = ThemePalette(
    background: Color(0xFFFAF5F1),
    surface: Color(0xFFFFFCF8),
    outline: Color(0xFFE5D8CE),
    divider: Color(0xFFECE0D6),
    disabled: Color(0xFFC8B7AB),
    primary: Color(0xFFA04E48), // rose-clay
    primaryPressed: Color(0xFF7F3530),
    primarySoft: Color(0xFFF2DCD8),
    secondary: Color(0xFFC97A3D), // caramel
    accentWine: Color(0xFF7F3530),
    accentInkViolet: Color(0xFFF2DCD8),
    textPrimary: Color(0xFF2D211E),
    textSecondary: Color(0xFF6F5A52),
    textDisabled: Color(0xFFAB988E),
    warningSoft: Color(0xFFF8E3D8),
    warningBorder: Color(0xFFC97A3D),
    warningStrong: Color(0xFF823D14),
    noticeBackground: Color(0xFFF8E3D8),
    noticeBorder: Color(0xFFD4A574),
    noticeText: Color(0xFF5A3018),
    restTone: Color(0xFFB0918A),
    neutralBadge: Color(0xFFECE0D6),
    timeChipNowBackground: Color(0xFFA04E48),
    timeChipNeutralBackground: Color(0xFFF0E5DA),
    timeChipNowText: Color(0xFFFFFFFF),
    timeChipMutedText: Color(0xFF6F5A52),
    pendingBadgeFill: Color(0x1AC97A3D),
    pendingBadgeText: Color(0xFF823D14),
  );

  // ============================================
  // Theme E: Lavender Dusk — Plum × Mustard Gold
  // ============================================
  static const ThemePalette _lavenderDuskPalette = ThemePalette(
    background: Color(0xFFF5F2F7),
    surface: Color(0xFFFCFAFE),
    outline: Color(0xFFDBD3E0),
    divider: Color(0xFFE5DEEC),
    disabled: Color(0xFFB5ADBE),
    primary: Color(0xFF6B5B7B), // dusty plum
    primaryPressed: Color(0xFF4E4258),
    primarySoft: Color(0xFFE0D8E9),
    secondary: Color(0xFFC99A2C), // mustard gold
    accentWine: Color(0xFF8B6418),
    accentInkViolet: Color(0xFFFAF1DC),
    textPrimary: Color(0xFF261F2E),
    textSecondary: Color(0xFF5F546A),
    textDisabled: Color(0xFFA299AC),
    warningSoft: Color(0xFFFAF1DC),
    warningBorder: Color(0xFFC99A2C),
    warningStrong: Color(0xFF6E4D10),
    noticeBackground: Color(0xFFFAF1DC),
    noticeBorder: Color(0xFFE2C679),
    noticeText: Color(0xFF4A3A0F),
    restTone: Color(0xFF8C7BA0),
    neutralBadge: Color(0xFFE5DEEC),
    timeChipNowBackground: Color(0xFFC99A2C),
    timeChipNeutralBackground: Color(0xFFECE5F1),
    timeChipNowText: Color(0xFF2D2510),
    timeChipMutedText: Color(0xFF6E6376),
    pendingBadgeFill: Color(0x1AC99A2C),
    pendingBadgeText: Color(0xFF6E4D10),
  );

  // ============================================
  // Legacy aliases (하위 호환 — 추후 제거)
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
}
