import 'package:flutter/material.dart';

/// Kakao's button colours: the yellow container and the 85% black label of
/// Kakao's design guide — not the app's coral, so it reads as KakaoTalk.
const Color kKakaoYellow = Color(0xFFFEE500);
const Color kKakaoLabel = Color(0xD9000000);

/// "카카오톡으로 초대 보내기": the primary invite button while KakaoTalk is
/// installed. Sized by the caller to match the button it stands in for.
class KakaoInviteButton extends StatelessWidget {
  const KakaoInviteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.height = 52,
    this.radius = 14,
    this.fontSize = 16,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Shows a spinner in place of the speech bubble.
  final bool busy;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kKakaoYellow,
          foregroundColor: kKakaoLabel,
          disabledBackgroundColor: kKakaoYellow.withValues(alpha: 0.5),
          disabledForegroundColor: kKakaoLabel.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800),
        ),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kKakaoLabel,
                ),
              )
            : const Icon(Icons.chat_bubble_rounded, size: 18),
        label: Text(label),
      ),
    );
  }
}
