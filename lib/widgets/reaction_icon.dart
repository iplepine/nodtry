import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'centered_emoji.dart';

/// Renders a cheer reaction as a custom illustrated icon.
///
/// The reaction is still stored/transported as an emoji string
/// (e.g. '🔥'), so this widget maps that canonical string to a custom
/// SVG asset. Any string without a mapping falls back to rendering the
/// emoji itself via [CenteredEmoji], keeping legacy/unknown data safe.
class ReactionIcon extends StatelessWidget {
  final String reaction;
  final double size;

  const ReactionIcon(this.reaction, {super.key, required this.size});

  /// Canonical emoji string -> custom SVG asset path.
  static const Map<String, String> _assetByReaction = {
    '🔥': 'assets/icons/reactions/fire.svg',
    '❤️': 'assets/icons/reactions/heart.svg',
    '👏': 'assets/icons/reactions/clap.svg',
    '👍': 'assets/icons/reactions/thumbsup.svg',
    '🙌': 'assets/icons/reactions/raisedhands.svg',
    '🎉': 'assets/icons/reactions/party.svg',
    '💪': 'assets/icons/reactions/muscle.svg',
    '✨': 'assets/icons/reactions/sparkle.svg',
  };

  /// The reaction strings that have a custom icon, in display order.
  static const List<String> reactions = [
    '🔥',
    '❤️',
    '👏',
    '👍',
    '🙌',
    '🎉',
    '💪',
    '✨',
  ];

  /// Returns the custom SVG asset path for [reaction], or null if there
  /// is no custom icon mapped for it.
  static String? assetFor(String reaction) => _assetByReaction[reaction];

  /// Reaction strings ordered longest-first, so multi-codepoint emojis
  /// (e.g. '❤️') are matched before any shorter prefix during scanning.
  static final List<String> _matchOrder =
      _assetByReaction.keys.toList()..sort((a, b) => b.length.compareTo(a.length));

  /// Longest reaction-string match at [text]'s [index], or null.
  static String? matchAt(String text, int index) {
    for (final r in _matchOrder) {
      if (text.startsWith(r, index)) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final asset = _assetByReaction[reaction];
    if (asset == null) {
      // Unknown / legacy reaction: render the raw emoji.
      return CenteredEmoji(reaction, size: size);
    }
    return Center(
      child: SvgPicture.asset(
        asset,
        width: size,
        height: size,
      ),
    );
  }
}

/// Renders a text string, replacing any known cheer-reaction emoji with
/// its inline custom icon. Non-reaction text and unknown emojis are kept
/// as-is. Data is never modified — only the visual rendering changes.
class ReactionText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// Inline icon size. Defaults to ~1.15x the text font size.
  final double? iconSize;

  const ReactionText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final size = iconSize ?? ((resolved.fontSize ?? 16) * 1.15);

    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    var i = 0;
    while (i < text.length) {
      final match = ReactionIcon.matchAt(text, i);
      if (match != null) {
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString()));
          buffer.clear();
        }
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: SvgPicture.asset(
                ReactionIcon.assetFor(match)!,
                width: size,
                height: size,
              ),
            ),
          ),
        );
        i += match.length;
      } else {
        buffer.write(text[i]);
        i++;
      }
    }
    if (buffer.isNotEmpty) spans.add(TextSpan(text: buffer.toString()));

    return Text.rich(
      TextSpan(style: resolved, children: spans),
      textAlign: textAlign,
    );
  }
}
