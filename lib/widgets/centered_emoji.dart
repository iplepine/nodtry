import 'package:flutter/material.dart';

class CenteredEmoji extends StatelessWidget {
  final String emoji;
  final double size;

  const CenteredEmoji(this.emoji, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          height: 1,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        strutStyle: StrutStyle(
          fontSize: size,
          height: 1,
          forceStrutHeight: true,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    );
  }
}
