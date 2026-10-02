// Store screenshot generator for 둘운완 / DuoDone.
//
//   flutter test tool/generate_store_screenshots_test.dart
//
// Renders the six captioned listing screenshots (spec §7, in order) for ko and
// en and writes them to
//   ios/fastlane/screenshots/{ko,en-US}/                      1320×2868
//   android/fastlane/metadata/android/{ko-KR,en-US}/images/phoneScreenshots/
//                                                             1440×2560
// Same shots and copy for both stores; the Play canvas is 9:16 because Play
// rejects screenshots more than twice as tall as wide. PNGs are 24-bit (no
// alpha). Old PNGs in those folders are replaced only after every image
// rendered. SCREENSHOT_PREVIEW_DIR=/some/dir writes there instead.
//
// Each image is the real app UI (real widgets, real ARB copy) fed with
// fictional couple/workout fixtures, laid out on a 393×852 phone and framed
// under a caption. Proof photos are generated illustrations, never people.
//
// Fonts: see store_screenshots/fonts.dart (needs macOS system fonts until
// assets/fonts/Pretendard-*.otf are real font files).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nod_try/features/duo/domain/duo_stats.dart';
import 'package:nod_try/features/now/presentation/cards/check_in_question.dart';
import 'package:nod_try/features/now/presentation/now_tab_state.dart';
import 'package:nod_try/features/plan/presentation/screens/plan_create_screen.dart';
import 'package:nod_try/features/proof/data/proof_photo_cache.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/proof_photo.dart';
import 'package:nod_try/screens/home_screen.dart';
import 'package:nod_try/theme/app_colors.dart';
import 'package:nod_try/theme/app_theme.dart';
import 'package:nod_try/theme/app_theme_enum.dart';

import 'store_screenshots/fixtures.dart';
import 'store_screenshots/fonts.dart';
import 'store_screenshots/frame.dart';
import 'store_screenshots/proof_art.dart';

final _shotKey = GlobalKey();
final _artKey = GlobalKey();

const _locales = [Locale('ko'), Locale('en')];

/// Output folder per store canvas and language.
const _folders = {
  'appStore': {
    'ko': 'ios/fastlane/screenshots/ko',
    'en': 'ios/fastlane/screenshots/en-US',
  },
  'play': {
    'ko': 'android/fastlane/metadata/android/ko-KR/images/phoneScreenshots',
    'en': 'android/fastlane/metadata/android/en-US/images/phoneScreenshots',
  },
};

void main() {
  testWidgets('generate store screenshots', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppColors.setTheme(AppThemeType.smokyPlum);
    // flutter_test draws shadows as hard black outlines unless told not to.
    debugDisableShadows = false;
    // folder → file name → PNG bytes.
    final rendered = <String, Map<String, Uint8List>>{};
    try {
      _useCanvas(tester, ShotCanvas.appStore);
      final fonts = await tester.runAsync(loadScreenshotFonts);
      debugPrint('[screenshots] fonts: $fonts');
      final photos = {kPartnerPhotoPath: await _renderArt(tester)};
      final appIcon = MemoryImage(
        File('assets/images/app_icon.png').readAsBytesSync(),
      );

      for (final canvas in const [ShotCanvas.appStore, ShotCanvas.play]) {
        _useCanvas(tester, canvas);
        for (final locale in _locales) {
          final language = locale.languageCode;
          rendered[_folderFor(canvas, language)] = await _renderLocale(
            tester,
            canvas: canvas,
            locale: locale,
            photos: photos,
            appIcon: appIcon,
          );
        }
      }
      // Leave nothing mounted (timers, streams) before writing.
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      debugDisableShadows = true;
    }
    await tester.runAsync(() => _writeOutputs(rendered));
  });
}

void _useCanvas(WidgetTester tester, ShotCanvas canvas) {
  tester.view.physicalSize = canvas.pixels;
  tester.view.devicePixelRatio = canvas.pixelRatio;
}

String _folderFor(ShotCanvas canvas, String language) {
  final preview = Platform.environment['SCREENSHOT_PREVIEW_DIR'];
  if (preview != null && preview.isNotEmpty) {
    return '$preview/${canvas.name}/$language';
  }
  return _folders[canvas.name]![language]!;
}

/// The six screenshots of one locale on one store canvas, by file name.
Future<Map<String, Uint8List>> _renderLocale(
  WidgetTester tester, {
  required ShotCanvas canvas,
  required Locale locale,
  required Map<String, Uint8List> photos,
  required ImageProvider appIcon,
}) async {
  final l10n = await AppLocalizations.delegate.load(locale);
  final cast = ShotCast(locale, now: DateTime.now());
  final cache = ProofPhotoCache(
    fetch: (path) async => photos[path],
    directory: () async => null,
  );
  await tester.runAsync(() async {
    for (final path in photos.keys) {
      await cache.load(path);
    }
  });
  final shots = _Shots(
    tester: tester,
    canvas: canvas,
    locale: locale,
    l10n: l10n,
    cast: cast,
    cache: cache,
    photos: photos,
    appIcon: appIcon,
  );
  return {
    '01_proof_props': await shots.proofProps(),
    '02_pinky_promise': await shots.pinkyPromise(),
    '03_check_in': await shots.checkIn(),
    '04_partner_knows': await shots.partnerKnows(),
    '05_bet': await shots.bet(),
    '06_duo_streak': await shots.duoStreak(),
  };
}

class _Shots {
  _Shots({
    required this.tester,
    required this.canvas,
    required this.locale,
    required this.l10n,
    required this.cast,
    required this.cache,
    required this.photos,
    required this.appIcon,
  });

  final WidgetTester tester;
  final ShotCanvas canvas;
  final Locale locale;
  final AppLocalizations l10n;
  final ShotCast cast;
  final ProofPhotoCache cache;
  final Map<String, Uint8List> photos;
  final ImageProvider appIcon;

  bool get ko => cast.ko;

  ShotWorld _world({
    required Plan myPlan,
    required Plan partnerPlan,
    required NowTabState Function(Plan mine, Plan theirs) now,
  }) => buildWorld(
    cast: cast,
    myPlan: myPlan,
    partnerPlan: partnerPlan,
    now: now,
    photoCache: cache,
    photos: photos,
  );

  /// A Now-tab card; on mine as on theirs the partner is the other person.
  HomeCardModel _card(HomeCardState state, Plan plan) => HomeCardModel(
    state: state,
    plan: plan,
    partnerUid: kPartnerUid,
    partnerName: cast.partnerName,
  );

  /// ① 짝꿍 인증샷 + ❤️ 인정.
  Future<Uint8List> proofProps() {
    final world = _world(
      myPlan: cast.myRunPlan(doneToday: true),
      partnerPlan: cast.partnerGymPlan(
        promise: cast.chickenBet(proposerId: kMeUid),
      ),
      now: (mine, theirs) => nowTabState(
        cast: cast,
        manager: [_card(HomeCardState.partnerAction, theirs)],
      ),
    );
    return _render(
      caption: ko
          ? const Caption('둘이 보면,\n*진짜* 하게 돼요', '짝꿍 인증샷에 ❤️ 한 번이면 인정 끝')
          : const Caption(
              'Your partner sees it.\nYou *actually* do it.',
              'Proof photo in, ❤️ props back in one tap',
            ),
      background: CaptionBackground.coral,
      world: world,
      statusTime: '7:58',
      tapBurstOn: find.byKey(ValueKey('react-${kProofReactions.first}')),
    );
  }

  /// ② 손가락 걸기 — the one-screen workout promise.
  Future<Uint8List> pinkyPromise() {
    final world = _world(
      myPlan: cast.myRunPlan(),
      partnerPlan: cast.partnerGymPlan(),
      now: (mine, theirs) => nowTabState(cast: cast),
    );
    return _render(
      caption: ko
          ? const Caption('손가락 걸고,\n*운동 약속* 🤙', '운동 고르고 요일·마감 시간만 정하면 끝나요')
          : const Caption(
              '*Pinky-promise*\nyour workout 🤙',
              'Pick a workout, the days and a deadline. Done.',
            ),
      background: CaptionBackground.cream,
      world: world,
      statusTime: '12:30',
      interact: () async {
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const PlanCreateScreen()),
        );
        await _settle(tester);
        await tester.tap(find.text(l10n.workoutTypeRunningLabel).first);
        await _settle(tester);
      },
    );
  }

  /// ③ 오늘 운동했어? — the all-day check-in hero.
  Future<Uint8List> checkIn() {
    final world = _world(
      myPlan: cast.myRunPlan(promise: cast.chickenBet(proposerId: kPartnerUid)),
      partnerPlan: cast.partnerGymPlan(
        promise: cast.chickenBet(proposerId: kMeUid),
      ),
      now: (mine, theirs) => nowTabState(
        cast: cast,
        primary: _card(HomeCardState.nextAction, mine),
        manager: [_card(HomeCardState.partnerAction, theirs)],
      ),
    );
    return _render(
      caption: ko
          ? const Caption('오늘\n*운동했어?*', '📸 인증샷 한 장이면 오늘 기록 끝')
          : const Caption(
              'Did you work out\n*today?*',
              '📸 One proof photo and today is logged',
            ),
      background: CaptionBackground.cream,
      world: world,
      statusTime: '7:51',
    );
  }

  /// ④ 안 하면 짝꿍이 알아요 — deadline reminder + the partner's knock.
  Future<Uint8List> partnerKnows() {
    final myPlan = cast.myRunPlan(
      knockedToday: true,
      promise: cast.chickenBet(proposerId: kPartnerUid),
    );
    final world = _world(
      myPlan: myPlan,
      partnerPlan: cast.partnerGymPlan(
        promise: cast.chickenBet(proposerId: kMeUid),
      ),
      now: (mine, theirs) => nowTabState(
        cast: cast,
        primary: _card(HomeCardState.poked, mine),
        manager: [_card(HomeCardState.partnerAction, theirs)],
      ),
    );
    return _render(
      caption: ko
          ? const Caption('안 하면\n*짝꿍이 알아요*', '기록이 없으면 짝꿍한테 알려지고, 똑똑이 와요')
          : const Caption(
              'Skip it, and\n*your partner knows*',
              'No check-in by the deadline? Expect a knock.',
            ),
      background: CaptionBackground.cream,
      world: world,
      statusTime: '9:05',
      screenOverlay: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, kDeviceSafeTop + 4, 10, 0),
          child: PushBanner(
            title: todayCheckInQuestion(l10n, myPlan),
            body: l10n.notifReminderBodyWithPartner(cast.partnerName),
            timeLabel: ko ? '5분 전' : '5m ago',
            icon: appIcon,
          ),
        ),
      ),
    );
  }

  /// ⑤ 못 지키면 치킨 쏘기 — the bet sheet on the partner's promise.
  Future<Uint8List> bet() {
    final world = _world(
      myPlan: cast.myRunPlan(doneToday: true),
      partnerPlan: cast.partnerGymPlan(),
      now: (mine, theirs) => nowTabState(
        cast: cast,
        manager: [_card(HomeCardState.partnerAction, theirs)],
      ),
    );
    return _render(
      caption: ko
          ? const Caption('못 지키면\n*치킨 쏘기* 🍗', '돈 말고, 둘만의 귀여운 내기')
          : const Caption(
              'Miss it?\n*Chicken\'s on you* 🍗',
              'Playful couple bets. Never money.',
            ),
      background: CaptionBackground.cream,
      world: world,
      statusTime: '8:12',
      interact: () async {
        await _tapVisible(tester, find.text(l10n.nowMakePromise).first);
        await _tapVisible(tester, find.text(l10n.promisePenaltyChicken).first);
      },
    );
  }

  /// ⑥ 둘이 함께 N일째 — the 둘운완 board on the Us tab.
  Future<Uint8List> duoStreak() async {
    final myPlan = cast.myRunPlan(doneToday: true, verifiedToday: true);
    final partnerPlan = cast.partnerGymPlan(verifiedToday: true);
    final stats = computeDuoStats(
      myPlans: [myPlan],
      partnerPlans: [partnerPlan],
      today: cast.now,
    );
    final world = _world(
      myPlan: myPlan,
      partnerPlan: partnerPlan,
      now: (mine, theirs) => nowTabState(cast: cast),
    );
    final n = stats.streak;
    // The caption repeats the board's number; the fixtures always give a
    // multi-day streak.
    expect(n, greaterThan(1), reason: 'fixture streak');
    return _render(
      caption: ko
          ? Caption('둘이 함께\n*$n일째* 🔥', '둘 다 해낸 날, 오늘도 둘운완')
          : Caption(
              'Together for\n*$n days* 🔥',
              'Both of you did it? That\'s a DuoDone day.',
            ),
      background: CaptionBackground.coral,
      world: world,
      statusTime: '10:16',
      interact: () async {
        await tester.tap(find.text(l10n.tabUs).first);
        await _settle(tester);
      },
    );
  }

  Future<Uint8List> _render({
    required Caption caption,
    required CaptionBackground background,
    required ShotWorld world,
    required String statusTime,
    Widget? screenOverlay,
    Future<void> Function()? interact,
    Finder? tapBurstOn,
  }) async {
    // One app instance for the whole shot, so re-pumping the frame (to add
    // the tap burst) keeps the app's state.
    final app = ProviderScope(
      key: UniqueKey(),
      overrides: world.overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        theme: _screenshotTheme(),
        home: const HomeScreen(),
      ),
    );
    Widget frame({Rect? burstAt}) => RepaintBoundary(
      key: _shotKey,
      child: StoreShotFrame(
        canvas: canvas,
        caption: caption,
        background: background,
        statusTime: statusTime,
        screenOverlay: screenOverlay,
        app: app,
        canvasOverlay: burstAt == null
            ? null
            : (_) => TapBurst(target: burstAt),
      ),
    );

    await tester.pumpWidget(frame());
    await _settle(tester);
    if (interact != null) await interact();
    await _precacheImages(tester);
    await _settle(tester);
    if (tapBurstOn != null) {
      await tester.pumpWidget(frame(burstAt: tester.getRect(tapBurstOn)));
      await _settle(tester);
    }
    return _capture(
      tester,
      _shotKey,
      pixelRatio: canvas.pixelRatio,
      opaque: true,
    );
  }
}

/// The app theme, with the emoji fallback font and the debug-only fake-state
/// button (a mini FAB on the Now/History tabs in debug builds) made invisible.
ThemeData _screenshotTheme() {
  final theme = withScreenshotFontFallback(AppTheme.smokyPlumTheme);
  return theme.copyWith(
    floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
      smallSizeConstraints: BoxConstraints.tight(Size.zero),
      foregroundColor: Colors.transparent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const _NoShape(),
    ),
  );
}

/// Paints nothing (used to hide the debug FAB).
class _NoShape extends ShapeBorder {
  const _NoShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

Future<Uint8List> _renderArt(WidgetTester tester) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(key: _artKey, child: const GymProofArt()),
      ),
    ),
  );
  await tester.pump();
  return _capture(tester, _artKey);
}

/// Decodes every image on screen for real (widget tests don't otherwise).
Future<void> _precacheImages(WidgetTester tester) async {
  final elements = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final element in elements) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
}

/// Scrolls [finder] to the middle of its scroll view (clear of the bottom
/// navigation bar), then taps it.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await _settle(tester);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i += 1) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// PNG bytes of the [key] boundary. With [opaque], the PNG is 24-bit RGB:
/// Google Play rejects screenshots with an alpha channel.
Future<Uint8List> _capture(
  WidgetTester tester,
  GlobalKey key, {
  double pixelRatio = 3,
  bool opaque = false,
}) async {
  final bytes = await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      if (!opaque) {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      }
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgb = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: rgba!.buffer,
        numChannels: 4,
      ).convert(numChannels: 3);
      return img.encodePng(rgb);
    } finally {
      image.dispose();
    }
  });
  return bytes!;
}

Future<void> _writeOutputs(Map<String, Map<String, Uint8List>> rendered) async {
  for (final MapEntry(key: folder, value: images) in rendered.entries) {
    final directory = Directory(folder);
    await directory.create(recursive: true);
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.png')) {
        await entity.delete();
      }
    }
    for (final MapEntry(key: name, value: bytes) in images.entries) {
      await File('$folder/$name.png').writeAsBytes(bytes, flush: true);
    }
    debugPrint('[screenshots] wrote ${images.length} → $folder');
  }
}
