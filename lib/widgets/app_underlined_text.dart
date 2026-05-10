import 'package:flutter/material.dart';

class AppUnderlinedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? lineColor;
  final double lineWidth;
  final double lineGap;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool selectable;

  const AppUnderlinedText(
    this.text, {
    super.key,
    this.style,
    this.lineColor,
    this.lineWidth = 1,
    this.lineGap = 1,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : selectable = false;

  const AppUnderlinedText.selectable(
    this.text, {
    super.key,
    this.style,
    this.lineColor,
    this.lineWidth = 1,
    this.lineGap = 1,
    this.textAlign,
    this.maxLines,
  }) : selectable = true,
       overflow = null;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle
        .merge(style)
        .copyWith(decoration: TextDecoration.none);
    final underlineColor =
        lineColor ?? effectiveStyle.color ?? defaultStyle.color ?? Colors.black;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: underlineColor, width: lineWidth),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: lineGap),
        child: selectable
            ? SelectableText(
                text,
                style: effectiveStyle,
                textAlign: textAlign,
                maxLines: maxLines,
              )
            : Text(
                text,
                style: effectiveStyle,
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: overflow,
              ),
      ),
    );
  }
}
