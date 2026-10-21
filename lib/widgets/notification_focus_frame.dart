import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wraps a card an opened notification can be about. When [focusToken] turns
/// non-null (or changes), scrolls the card into view and outlines it for a
/// moment, so the user sees which promise the notification meant.
///
/// The frame is always in the tree, so focusing never rebuilds the card it
/// wraps.
class NotificationFocusFrame extends StatefulWidget {
  const NotificationFocusFrame({
    super.key,
    required this.focusToken,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  /// A new value for each focus request on this card; null when it isn't
  /// the focused one.
  final int? focusToken;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<NotificationFocusFrame> createState() => _NotificationFocusFrameState();
}

class _NotificationFocusFrameState extends State<NotificationFocusFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  int? _handledToken;

  @override
  void initState() {
    super.initState();
    _maybeFocus();
  }

  @override
  void didUpdateWidget(NotificationFocusFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeFocus();
  }

  void _maybeFocus() {
    final token = widget.focusToken;
    if (token == null || token == _handledToken) return;
    _handledToken = token;
    // After this frame's layout (the tab may have just switched, the carousel
    // just moved).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.2,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      _glow.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      child: widget.child,
      builder: (context, child) {
        // Up quickly, hold, then fade out.
        final t = _glow.value;
        final strength = !_glow.isAnimating
            ? 0.0
            : t < 0.15
            ? t / 0.15
            : t < 0.6
            ? 1.0
            : (1 - t) / 0.4;
        if (strength <= 0) return child!;
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.8 * strength),
              width: 2,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
