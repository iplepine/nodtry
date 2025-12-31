import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/history_item.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/history_provider.dart';
import '../../providers/repository_provider.dart';

/// 기록 카드 (Spec 3.1)
class HistoryCard extends ConsumerWidget {
  final HistoryItem item;

  const HistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            // Bottom: Footer (Verification & Comments)
            _buildFooter(context, ref),
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

    // 실천 상태에 따른 라벨링 (배지)
    switch (item.status) {
      case HistoryStatus.done:
      case HistoryStatus.actuallyDone:
        color = const Color(0xFF6B8E23); // Olive Green
        icon = Icons.check_circle_outline;
        label = item.status == HistoryStatus.actuallyDone
            ? l10n.reconcileActuallyDone
            : l10n.homeDidIt;
        break;
      case HistoryStatus.rested:
        color = AppColors.secondary;
        icon = Icons.bedtime_outlined;
        label = l10n.reconcileTookRest;
        break;
      case HistoryStatus.verified:
        color = AppColors.primary;
        icon = Icons.verified;
        label = l10n.homeChecked;
        break;
      case HistoryStatus.skipped:
        color = AppColors.textDisabled;
        icon = Icons.hourglass_empty;
        label = l10n.reconcileSkip;
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

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final isMine = item.isMine('me'); // TODO: Pass real UID

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.comment != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.comment!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (isMine)
          _buildMyActionVerification(context)
        else
          _buildPartnerActionVerification(context, ref),
      ],
    );
  }

  /// [내 실천] 카드 하단: 파트너의 확인 여부 표시
  Widget _buildMyActionVerification(BuildContext context) {
    if (!item.isVerifiedByPartner) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(
          Icons.thumb_up,
          size: 14,
          color: AppColors.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.historyMyActionVerified,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// [파트너의 실천] 카드 하단: 나의 확인 여부 표시 및 액션
  Widget _buildPartnerActionVerification(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (item.isVerifiedByMe) {
      return Row(
        children: [
          Icon(Icons.thumb_up, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            l10n.historyPartnerActionVerified,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () async {
        await ref.read(recordRepositoryProvider).verifyHistoryItem(item.id);
        // 프로바이더 갱신 (리스트 새로고침)
        ref.invalidate(historyItemsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('확인되었습니다.')));
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.thumb_up_outlined,
              size: 16,
              color: AppColors.textDisabled,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.historyPartnerActionWaiting,
              style: TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
