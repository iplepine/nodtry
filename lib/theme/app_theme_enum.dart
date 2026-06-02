/// 앱 테마 타입
enum AppThemeType {
  /// Theme A: Mint × Orange — 차분 + 행동 강조
  smokyPlum,

  /// Theme B: Deep Olive × Sand — 단단함 · 책임감
  /// 운동 / 습관 / 실행자에게 잘 맞는 톤.
  deepOlive,

  /// Theme C: Pacific — Ocean Blue × Coral
  /// 청량함, 활기, 휴양지의 가벼움.
  pacific,

  /// Theme D: Rose Mocha — Dusty Rose × Cream
  /// 따뜻함, 편안함, 무드 있는 카페 톤.
  roseMocha,

  /// Theme E: Lavender Dusk — Plum × Mustard Gold
  /// 차분한 우아함, 저녁 시간의 결.
  lavenderDusk;

  /// SharedPreferences 등 직렬화용 키.
  String get storageKey {
    switch (this) {
      case AppThemeType.smokyPlum:
        return 'smokyPlum';
      case AppThemeType.deepOlive:
        return 'deepOlive';
      case AppThemeType.pacific:
        return 'pacific';
      case AppThemeType.roseMocha:
        return 'roseMocha';
      case AppThemeType.lavenderDusk:
        return 'lavenderDusk';
    }
  }

  /// 역직렬화. 미상이면 null.
  static AppThemeType? fromStorageKey(String? key) {
    if (key == null) return null;
    for (final t in AppThemeType.values) {
      if (t.storageKey == key) return t;
    }
    return null;
  }
}
