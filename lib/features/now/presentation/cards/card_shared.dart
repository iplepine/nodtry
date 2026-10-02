part of '../now_tab_screen.dart';

extension GlassExtension on Widget {
  Widget wrapWithGlass() {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: this,
      ),
    );
  }
}

/// lastActionNote가 작성된 시점 추정. reportCompletion에서 completedDates와
/// lastActionNote가 함께 갱신되므로, 가장 최근 completedDate를 노트 작성일로
/// 본다. 비어있으면 null.
DateTime? _lastActionNoteDate(Plan plan) {
  if (plan.completedDates.isEmpty) return null;
  return plan.completedDates.reduce((a, b) => a.isAfter(b) ? a : b);
}

/// "오늘 / 어제 / N일 전 / M월 D일" 같은 짧은 날짜 라벨.
/// 노트·코멘트 풍선의 상단에 작은 글씨로 박아 시간 맥락을 명시한다.
String? _formatNoteDateLabel(AppLocalizations l10n, DateTime? date) {
  if (date == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diffDays = today.difference(target).inDays;
  if (diffDays <= 0) return l10n.nowNoteDateToday;
  if (diffDays == 1) return l10n.timeChipYesterday;
  if (diffDays <= 6) return l10n.timeChipDaysAgo(diffDays);
  return l10n.timeChipDate(date.month, date.day);
}

/// 노트/코멘트 풍선을 그리는 공통 빌더. 날짜가 있으면 작은 라벨을 위에 붙인다.
Widget _buildDatedNoteBubble(
  BuildContext context, {
  required AppLocalizations l10n,
  required String text,
  required DateTime? date,
  required Color background,
  required Color noteColor,
  Color? dateLabelColor,
  FontWeight noteWeight = FontWeight.w500,
  bool noteItalic = false,
  BorderRadius? radius,
}) {
  final dateLabel = _formatNoteDateLabel(l10n, date);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: radius ?? BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dateLabel != null) ...[
          Text(
            dateLabel,
            style: TextStyle(
              color: dateLabelColor ?? AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
        ],
        ReactionText(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: noteColor,
            fontWeight: noteWeight,
            fontStyle: noteItalic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    ),
  );
}
