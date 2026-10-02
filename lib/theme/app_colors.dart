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
  /// 의미상 "accent". 브랜드 팔레트(둘운완)에서는 인정 옐로 **채움** 색이라
  /// 위에 textPrimary를 올린다. 흰 배경 위 텍스트/아이콘 accent가 필요하면
  /// [accentWine]을 쓴다. (deepOlive의 옛 #D2CCC3 같은 sand-on-sand는 ❌)
  final Color secondary;
  final Color accentWine; // 짙은 accent, 강한 강조 텍스트 (흰 배경 AA)
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

/// 둘운완 / DuoDone Color System
///
/// 앱은 단일 브랜드 팔레트로 고정한다(테마 선택 UI는 숨김). 브랜드 팔레트는
/// 저장 키 호환 때문에 enum 이름 `smokyPlum`에 들어 있다.
/// - 둘운완 Brand (`smokyPlum`)     : raspberry coral × 인정 옐로 — 기본·고정
///
/// 아래 4개는 숨겨진 레거시 팔레트(개발자 화면/롤백용, 사용자 노출 없음):
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
  // Theme A: 둘운완 Brand — Coral × 인정 Yellow (storage key `smokyPlum`)
  // ============================================
  //
  // 정본: docs/product/PIVOT_DUOUNWAN_SPEC.md 1절, docs/design/BRAND.md.
  // enum 이름/저장 키 `smokyPlum`은 기존 사용자 prefs 호환을 위해 그대로 둔다.
  // 대비(WCAG 2.x, 흰 글자 기준):
  //   white on primary 4.82:1 (AA) · white on primaryPressed 6.38:1 (AA)
  //   primary on background 4.60:1 (AA) · textSecondary on background 5.91:1
  //   textPrimary on secondary(yellow) 11.85:1 (AAA)
  // ⚠ secondary(#FFD84D)는 "채움" 색이다 — 위에는 textPrimary를 올린다.
  //   흰 배경 위 텍스트/아이콘 색으로 쓰면 1.38:1로 안 보인다. 그 용도는
  //   accentWine(#8A5A00, 흰 배경 5.93:1)을 쓴다.
  static const ThemePalette _smokyPlumPalette = ThemePalette(
    background: Color(0xFFFFF8F6), // warm blush white (앱 배경, 스플래시)
    surface: Color(0xFFFFFFFF), // 카드
    outline: Color(0xFFEADADD), // rose-grey 테두리
    divider: Color(0xFFF3E7E9),
    disabled: Color(0xFFD8C8CC),
    primary: Color(0xFFD92653), // raspberry coral — 버튼·강조
    primaryPressed: Color(0xFFB81C45), // 눌림 / soft 위 진한 텍스트
    primarySoft: Color(0xFFFFE8ED), // 칩·선택 배경
    secondary: Color(0xFFFFD84D), // 인정 옐로 — 채움 전용 (위 경고 참고)
    accentWine: Color(0xFF8A5A00), // honey — 옐로 계열의 텍스트/아이콘 색
    accentInkViolet: Color(0xFFFFF6D6), // 옅은 옐로 힌트 배경
    textPrimary: Color(0xFF2B1B21),
    textSecondary: Color(0xFF6F5C63),
    textDisabled: Color(0xFFA8969C),
    // 내기(벌칙)·경고 칩: primary(핑크)와 구분되는 따뜻한 오렌지 계열
    warningSoft: Color(0xFFFFF1E8),
    warningBorder: Color(0xFFE0612A), // 아이콘/테두리, 흰 배경 3.55:1
    warningStrong: Color(0xFFA3410F), // warningSoft 위 텍스트 5.72:1
    // 게스트 안내 배너: 인정 옐로 톤
    noticeBackground: Color(0xFFFFF7DB),
    noticeBorder: Color(0xFFFFD84D),
    noticeText: Color(0xFF5C4210), // noticeBackground 위 8.73:1
    restTone: Color(0xFF9DB0E0), // 휴식 셀: 차가운 periwinkle로 done(코랄)과 구분
    neutralBadge: Color(0xFFF2E8EA),
    timeChipNowBackground: Color(0xFFD92653), // "지금" 칩 = primary
    timeChipNeutralBackground: Color(0xFFF5ECEE),
    timeChipNowText: Color(0xFFFFFFFF), // primary 위 흰 글자 4.82:1
    timeChipMutedText: Color(0xFF7A666D), // neutral(80%) 위 4.67:1
    pendingBadgeFill: Color(0x33FFD84D), // 20% 인정 옐로
    pendingBadgeText: Color(0xFF8A5A00), // fill 위 5.53:1
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
