// Placeholder "proof photo" (인증샷) for the store screenshots: an illustrated
// evening-gym scene (gradient, bokeh, rack, emoji) — never a real person.
//
// The app shows proof photos cover-cropped to a wide box, so everything that
// matters sits in the middle band (20%–80% of the height).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fonts.dart';

/// Logical size the art is painted at (3:4 portrait, like a phone photo).
const kProofArtSize = Size(300, 400);

class GymProofArt extends StatelessWidget {
  const GymProofArt({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kProofArtSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3A2747),
                  Color(0xFF8C4A6E),
                  Color(0xFFE88A7C),
                ],
                stops: [0.1, 0.55, 1],
              ),
            ),
          ),
          CustomPaint(painter: _GymPainter()),
          const Align(
            alignment: Alignment(0, 0.02),
            child: Text(
              '🏋️',
              style: TextStyle(
                fontFamily: kEmojiFontFamily,
                fontSize: 142,
                height: 1,
                shadows: [
                  Shadow(
                    color: Color(0x55000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          // Soft vignette, like a phone photo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.95,
                colors: [Color(0x00000000), Color(0x40000000)],
                stops: [0.6, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Out-of-focus ceiling lights.
    final random = math.Random(7);
    for (var i = 0; i < 16; i++) {
      final center = Offset(
        random.nextDouble() * w,
        h * (0.08 + random.nextDouble() * 0.4),
      );
      final radius = 10 + random.nextDouble() * 26;
      final warm = i.isEven ? const Color(0xFFFFE0B8) : const Color(0xFFFFB3C1);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [warm.withValues(alpha: 0.42), warm.withValues(alpha: 0.0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Mirror wall panels.
    final panel = Paint()..color = const Color(0x14FFFFFF);
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (0.04 + i * 0.24), h * 0.2, w * 0.2, h * 0.4),
          const Radius.circular(6),
        ),
        panel,
      );
    }

    // Dumbbell rack.
    final rackY = h * 0.66;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, rackY, w * 0.92, 9),
        const Radius.circular(4.5),
      ),
      Paint()..color = const Color(0xFF2B1F33),
    );
    final bell = Paint()..color = const Color(0xFF2A1E31);
    final handle = Paint()..color = const Color(0xFFB7A6BD);
    for (var i = 0; i < 6; i++) {
      final cx = w * (0.12 + i * 0.152);
      final cy = rackY - 9;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 4),
        handle,
      );
      final r = 7.5 + (i % 3) * 1.5;
      canvas.drawCircle(Offset(cx - 12, cy), r, bell);
      canvas.drawCircle(Offset(cx + 12, cy), r, bell);
    }

    // Floor with a soft reflection line.
    final floorTop = h * 0.7;
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, w, h - floorTop),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x26000000), Color(0x08000000)],
        ).createShader(Rect.fromLTWH(0, floorTop, w, h - floorTop)),
    );
    canvas.drawLine(
      Offset(0, floorTop),
      Offset(w, floorTop),
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
