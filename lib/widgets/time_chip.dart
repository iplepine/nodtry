import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Time Chip 타입
enum TimeChipType {
  /// NOW: 즉시 인지해야 할 상태
  now,

  /// UPCOMING: 가까운 미래 행동
  upcoming,

  /// SOON: 시간 계산이 애매한 임박 상태
  soon,

  /// PAST: 지난 시간 (과거 행동)
  past,
}

/// Time Chip 위젯
///
/// 스펙: 시간은 메시지가 아니라 상태(state)다 — 상태는 칩(chip)으로 표현한다.
/// 모든 색은 현재 테마의 ThemePalette에서 가져온다.
class TimeChip extends StatelessWidget {
  final String text;
  final TimeChipType type;

  const TimeChip({super.key, required this.text, required this.type});

  @override
  Widget build(BuildContext context) {
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.55)
        .clamp(112.0, 180.0)
        .toDouble();

    return Tooltip(
      message: text,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(20), // Pill shape
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 14, color: _getTextColor()),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case TimeChipType.now:
        return AppColors.timeChipNowBackground;
      case TimeChipType.upcoming:
        return AppColors.timeChipNeutralBackground.withValues(alpha: 0.8);
      case TimeChipType.soon:
        return AppColors.timeChipNeutralBackground.withValues(alpha: 0.6);
      case TimeChipType.past:
        return AppColors.timeChipNeutralBackground.withValues(alpha: 0.5);
    }
  }

  Color _getTextColor() {
    switch (type) {
      case TimeChipType.now:
        return AppColors.timeChipNowText;
      case TimeChipType.upcoming:
      case TimeChipType.soon:
      case TimeChipType.past:
        return AppColors.timeChipMutedText;
    }
  }
}
