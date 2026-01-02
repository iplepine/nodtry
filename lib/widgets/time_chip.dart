import 'package:flutter/material.dart';

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
/// 스펙: 시간은 메시지가 아니라 상태(state)다
/// 상태는 칩(chip)으로 표현한다
class TimeChip extends StatelessWidget {
  final String text;
  final TimeChipType type;

  const TimeChip({super.key, required this.text, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20), // Pill shape (Full radius)
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getTextColor(),
          height: 1.2,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case TimeChipType.now:
        // 스펙: Warm Coral (#F28B82)
        return const Color(0xFFF28B82);
      case TimeChipType.upcoming:
        // 스펙: Light Sand (Opacity 80%)
        // Theme A Surface를 사용하되, 스펙의 Light Sand 색상 사용
        return const Color(0xFFF2ECE7).withOpacity(0.8);
      case TimeChipType.soon:
        // 스펙: Light Sand (Opacity 60%)
        return const Color(0xFFF2ECE7).withOpacity(0.6);
      case TimeChipType.past:
        // 과거 시간: 더 약한 색상 (Opacity 50%)
        return const Color(0xFFF2ECE7).withOpacity(0.5);
    }
  }

  Color _getTextColor() {
    switch (type) {
      case TimeChipType.now:
        // 스펙: #3F3A36
        return const Color(0xFF3F3A36);
      case TimeChipType.upcoming:
      case TimeChipType.soon:
      case TimeChipType.past:
        // 스펙: #7A726C
        return const Color(0xFF7A726C);
    }
  }
}
