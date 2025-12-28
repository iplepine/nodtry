import 'package:flutter/material.dart';
import '../../models/history_item.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class HistoryCard extends StatelessWidget {
  final HistoryItem item;

  const HistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.5), // Subtle border
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Date & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(context, item.date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: 12),

            // Middle: Title
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Bottom: Comment & Verifier
            if (item.comment != null || item.verifierName != null) ...[
              const SizedBox(height: 16),
              _buildFooter(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    IconData icon;
    String label;

    switch (item.status) {
      case HistoryStatus.done:
        color = AppColors
            .success; // TODO: Define success color in AppColors if missing, usually green or primary variant
        icon = Icons.check_circle_outline;
        label = l10n.homeDidIt; // "했어"
        break;
      case HistoryStatus.verified:
        color = AppColors.primary;
        icon = Icons.verified;
        label = l10n.homeChecked; // "확인됐어요"
        break;
      case HistoryStatus.skipped:
        color = AppColors.textDisabled;
        icon = Icons.hourglass_empty;
        label = "이번엔 못 했어"; // TODO: Add to l10n if needed
        break;
    }

    // Fallback for success color if not defined (using primary for now or a custom green)
    if (item.status == HistoryStatus.done) {
      // 임시: 성공 색상은 웜톤 내에서 긍정적 색상 사용
      color = const Color(0xFF6B8E23); // Olive Green example
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background, // Slightly different bg for contrast
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (item.verifierName != null) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.3),
                image: item.verifierImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(
                          item.verifierImageUrl!,
                        ), // TODO: CacheNetworkImage
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.verifierImageUrl == null
                  ? Center(
                      child: Text(
                        item.verifierName![0],
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              item.comment ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    // MVP: Simple format MM.DD (Weekday)
    // In real app, use intl package
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}.${date.day} (${weekdays[date.weekday - 1]})';
  }
}
