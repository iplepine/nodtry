// Caption frame + device frame for the store screenshots.
//
// The real app is laid out at [kDeviceScreen] (a 393×852 phone) and scaled
// into a rounded device frame below a caption, on a [ShotCanvas] per store.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'fonts.dart';

/// Which phone the app is shown in: the App Store gets an iPhone, Google
/// Play an Android phone (Play's preview assets should show the Android
/// experience — no Dynamic Island or iOS status bar on the Play listing).
enum DeviceChrome { ios, android }

/// A store's screenshot canvas: the logical size the frame is laid out at,
/// the pixel ratio it is exported at, and how wide the device is in it.
class ShotCanvas {
  const ShotCanvas({
    required this.name,
    required this.size,
    required this.pixelRatio,
    required this.deviceWidth,
    required this.bottomMargin,
    this.chrome = DeviceChrome.ios,
  });

  /// App Store 6.9" portrait: 1320×2868 px.
  static const appStore = ShotCanvas(
    name: 'appStore',
    size: Size(440, 956),
    pixelRatio: 3,
    deviceWidth: 340,
    bottomMargin: 24,
  );

  /// Google Play phone, 9:16 portrait: 1440×2560 px. Play rejects images
  /// whose long side is more than twice the short side (1320×2868 is 2.17),
  /// and recommends 9:16 at ≥1080 px for promotion surfaces.
  static const play = ShotCanvas(
    name: 'play',
    size: Size(450, 800),
    pixelRatio: 3.2,
    deviceWidth: 284,
    bottomMargin: 16,
    chrome: DeviceChrome.android,
  );

  final String name;
  final Size size;
  final double pixelRatio;
  final double deviceWidth;
  final double bottomMargin;
  final DeviceChrome chrome;

  Size get pixels => size * pixelRatio;
}

/// The phone the app is laid out on (logical points).
const kDeviceScreen = Size(393, 852);
const kDeviceSafeTop = 54.0;
const kDeviceSafeBottom = 34.0;

/// Brand palette (spec §1).
abstract final class Brand {
  static const primary = Color(0xFFD92653);
  static const yellow = Color(0xFFFFD84D);
  static const cream = Color(0xFFFFF8F6);
  static const primarySoft = Color(0xFFFFE8ED);
  static const text = Color(0xFF2B1B21);
  static const textSecondary = Color(0xFF6F5C63);
  static const gradientStart = Color(0xFFFF6B5E);
  static const gradientEnd = Color(0xFFFF3577);
}

enum CaptionBackground { cream, coral }

/// One caption: a headline (with `*accent*` segments) and a subline.
class Caption {
  const Caption(this.headline, this.subline);

  /// Lines separated by `\n`; text between `*` is drawn in the accent colour.
  final String headline;
  final String subline;
}

/// The device geometry inside the canvas.
class DeviceGeometry {
  const DeviceGeometry._(this.outer, this.screen, this.scale);

  factory DeviceGeometry.of(ShotCanvas canvas) {
    final outerWidth = canvas.deviceWidth;
    final bezel = outerWidth * 9 / 340;
    final screenWidth = outerWidth - bezel * 2;
    final scale = screenWidth / kDeviceScreen.width;
    final screenHeight = kDeviceScreen.height * scale;
    final outerHeight = screenHeight + bezel * 2;
    final top = canvas.size.height - canvas.bottomMargin - outerHeight;
    final left = (canvas.size.width - outerWidth) / 2;
    final outer = Rect.fromLTWH(left, top, outerWidth, outerHeight);
    return DeviceGeometry._(outer, outer.deflate(bezel), scale);
  }

  final Rect outer;
  final Rect screen;

  /// App logical points → canvas logical points.
  final double scale;
}

/// A finished store screenshot: caption on top, the app in a device below,
/// and optional decorations drawn over everything in canvas coordinates.
class StoreShotFrame extends StatelessWidget {
  const StoreShotFrame({
    super.key,
    required this.canvas,
    required this.caption,
    required this.background,
    required this.app,
    required this.statusTime,
    this.screenOverlay,
    this.canvasOverlay,
  });

  final ShotCanvas canvas;
  final Caption caption;

  /// The clock in the status bar, e.g. `7:58`.
  final String statusTime;
  final CaptionBackground background;

  /// The real app, laid out at [kDeviceScreen].
  final Widget app;

  /// Drawn over the app inside the screen (app coordinates), e.g. a push
  /// banner.
  final Widget? screenOverlay;

  /// Drawn over the whole canvas, given the device geometry.
  final Widget Function(DeviceGeometry geometry)? canvasOverlay;

  @override
  Widget build(BuildContext context) {
    final geometry = DeviceGeometry.of(canvas);
    final coral = background == CaptionBackground.coral;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.fromSize(
        size: canvas.size,
        child: Stack(
          children: [
            Positioned.fill(child: _Background(coral: coral)),
            Positioned(
              left: 24,
              right: 24,
              top: 0,
              height: geometry.outer.top,
              child: Center(
                child: _CaptionBlock(caption: caption, coral: coral),
              ),
            ),
            Positioned.fromRect(
              rect: geometry.outer,
              child: _DeviceFrame(
                geometry: geometry,
                chrome: canvas.chrome,
                app: app,
                statusTime: statusTime,
                screenOverlay: screenOverlay,
              ),
            ),
            if (canvasOverlay != null)
              Positioned.fill(child: canvasOverlay!(geometry)),
          ],
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({required this.coral});

  final bool coral;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // Blob positions are designed on the 440×956 canvas and scaled.
        Widget blob(double x, double y, double radius, Color color) {
          final r = radius * size.width / 440;
          final center = Offset(x / 440 * size.width, y / 956 * size.height);
          return Positioned(
            left: center.dx - r,
            top: center.dy - r,
            width: r * 2,
            height: r * 2,
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          );
        }

        if (coral) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Brand.gradientStart, Brand.gradientEnd],
                  ),
                ),
              ),
              blob(400, 60, 190, Colors.white.withValues(alpha: 0.1)),
              blob(20, 520, 160, Colors.white.withValues(alpha: 0.07)),
              blob(380, 900, 170, Brand.yellow.withValues(alpha: 0.16)),
            ],
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Brand.cream),
            blob(430, 30, 200, Brand.primarySoft.withValues(alpha: 0.7)),
            blob(0, 600, 170, Brand.yellow.withValues(alpha: 0.14)),
            blob(420, 860, 150, Brand.gradientEnd.withValues(alpha: 0.08)),
          ],
        );
      },
    );
  }
}

class _CaptionBlock extends StatelessWidget {
  const _CaptionBlock({required this.caption, required this.coral});

  final Caption caption;
  final bool coral;

  @override
  Widget build(BuildContext context) {
    final base = coral ? Colors.white : Brand.text;
    final accent = coral ? Brand.yellow : Brand.primary;
    final sub = coral
        ? Colors.white.withValues(alpha: 0.92)
        : Brand.textSecondary;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(children: _spans(caption.headline, accent)),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontFamilyFallback: const [kEmojiFontFamily],
              fontSize: 34,
              height: 1.24,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w800,
              color: base,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            caption.subline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontFamilyFallback: const [kEmojiFontFamily],
              fontSize: 16.5,
              height: 1.4,
              letterSpacing: -0.2,
              fontWeight: FontWeight.w500,
              color: sub,
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _spans(String text, Color accent) {
    final parts = text.split('*');
    return [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(
            text: parts[i],
            style: i.isOdd ? TextStyle(color: accent) : null,
          ),
    ];
  }
}

class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({
    required this.geometry,
    required this.chrome,
    required this.app,
    required this.statusTime,
    this.screenOverlay,
  });

  final DeviceGeometry geometry;
  final DeviceChrome chrome;
  final Widget app;
  final String statusTime;
  final Widget? screenOverlay;

  @override
  Widget build(BuildContext context) {
    final android = chrome == DeviceChrome.android;
    // Android phones have tighter corners than an iPhone.
    final outerRadius = (android ? 34 : 52) * geometry.outer.width / 340;
    final screenRadius =
        outerRadius - (geometry.screen.left - geometry.outer.left);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1C181B),
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(color: const Color(0xFF3B3439), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332B1B21),
            blurRadius: 40,
            spreadRadius: 2,
            offset: Offset(0, 22),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(geometry.screen.left - geometry.outer.left),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(screenRadius),
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox.fromSize(
              size: kDeviceScreen,
              child: Stack(
                children: [
                  Positioned.fill(child: _DeviceMediaQuery(child: app)),
                  if (screenOverlay != null)
                    Positioned.fill(child: screenOverlay!),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: kDeviceSafeTop,
                    child: android
                        ? _AndroidStatusBar(time: statusTime)
                        : _StatusBar(time: statusTime),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Center(
                      child: android
                          ? const _GestureNavBar()
                          : const _HomeIndicator(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app sees a 393×852 phone with a status bar and home indicator.
class _DeviceMediaQuery extends StatelessWidget {
  const _DeviceMediaQuery({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.only(
      top: kDeviceSafeTop,
      bottom: kDeviceSafeBottom,
    );
    return MediaQuery(
      data: const MediaQueryData(
        size: kDeviceScreen,
        devicePixelRatio: 3,
        padding: padding,
        viewPadding: padding,
        textScaler: TextScaler.noScaling,
      ),
      child: child,
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF111111);
    return Stack(
      children: [
        Positioned(
          left: 0,
          width: 150,
          top: 0,
          bottom: 0,
          child: Center(
            child: Text(
              time,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        // Camera pill.
        Align(
          alignment: const Alignment(0, -0.1),
          child: Container(
            width: 118,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(17),
            ),
          ),
        ),
        const Positioned(
          right: 0,
          width: 150,
          top: 0,
          bottom: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.signal_cellular_alt_rounded, size: 18, color: color),
                SizedBox(width: 5),
                Icon(Icons.wifi_rounded, size: 18, color: color),
                SizedBox(width: 6),
                _Battery(color: color),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Battery extends StatelessWidget {
  const _Battery({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 27,
      height: 13,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 13,
            padding: const EdgeInsets.all(1.6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.82,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 1),
          Container(
            width: 2,
            height: 4.5,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An Android status bar: the clock on the left, a centred punch-hole
/// camera, Material signal / wifi / battery on the right.
class _AndroidStatusBar extends StatelessWidget {
  const _AndroidStatusBar({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1F1F1F);
    return Stack(
      children: [
        Positioned(
          left: 26,
          top: 0,
          bottom: 0,
          child: Center(
            child: Text(
              time,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ),
        // Punch-hole camera.
        Align(
          alignment: const Alignment(0, -0.05),
          child: Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Positioned(
          right: 24,
          top: 0,
          bottom: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, size: 16, color: color),
                SizedBox(width: 4),
                Icon(Icons.signal_cellular_4_bar, size: 15, color: color),
                SizedBox(width: 4),
                Icon(Icons.battery_full, size: 16, color: color),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Android's gesture navigation handle (thinner and shorter than iOS's).
class _GestureNavBar extends StatelessWidget {
  const _GestureNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// An iOS-style notification banner (drawn inside the screen).
class PushBanner extends StatelessWidget {
  const PushBanner({
    super.key,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
  });

  final String title;
  final String body;
  final String timeLabel;
  final ImageProvider icon;

  @override
  Widget build(BuildContext context) {
    TextStyle style(double size, FontWeight weight, Color color) => TextStyle(
      fontFamily: kAppFontFamily,
      fontFamilyFallback: const [kEmojiFontFamily],
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.3,
      letterSpacing: -0.2,
    );
    final radius = BorderRadius.circular(22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E2B1B21),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
            color: const Color(0xEBFFFFFF),
            child: _bannerContent(style),
          ),
        ),
      ),
    );
  }

  Widget _bannerContent(
    TextStyle Function(double size, FontWeight weight, Color color) style,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image(image: icon, width: 38, height: 38),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style(
                        15,
                        FontWeight.w700,
                        const Color(0xFF111111),
                      ),
                    ),
                  ),
                  Text(
                    timeLabel,
                    style: style(13, FontWeight.w400, const Color(0xFF8A8A8E)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: style(14.5, FontWeight.w400, const Color(0xFF1F1F1F)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A "just tapped" accent on [target] (canvas coordinates): a soft touch ring
/// and a few hearts floating up — the one-tap 인정.
class TapBurst extends StatelessWidget {
  const TapBurst({super.key, required this.target});

  final Rect target;

  @override
  Widget build(BuildContext context) {
    final center = target.center;
    final ring = target.shortestSide * 0.62;
    Widget heart(Offset offset, double size, double angle) => Positioned(
      left: center.dx + offset.dx - size / 2,
      top: center.dy + offset.dy - size / 2,
      child: Transform.rotate(
        angle: angle,
        child: Text(
          '❤️',
          style: TextStyle(
            fontFamily: kEmojiFontFamily,
            fontSize: size,
            height: 1,
            shadows: const [
              Shadow(
                color: Color(0x33D92653),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: center.dx - ring,
            top: center.dy - ring,
            width: ring * 2,
            height: ring * 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Brand.primary.withValues(alpha: 0.10),
                border: Border.all(
                  color: Brand.primary.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
            ),
          ),
          heart(Offset(-ring * 0.45, -ring * 1.4), 20, -0.2),
          heart(Offset(ring * 0.4, -ring * 1.95), 14, 0.3),
          heart(Offset(-ring * 1.1, -ring * 2.1), 12, -0.35),
        ],
      ),
    );
  }
}
