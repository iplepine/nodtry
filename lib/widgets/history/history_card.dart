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
    final isMine = item.isMine('me'); // TODO: Pass real UID

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.85,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMine ? 20 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 20),
                ),
                border: Border.all(
                  color: AppColors.surface.withValues(alpha: 0.5),
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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

                    // Bottom: Comment (Section)
                    _buildCommentSection(context),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12), // 의도적인 여백 (카드와 반응 분리)
            // 외부 반응 영역 (Align을 통해 극단적으로 정렬)
            Align(
              alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
              child: isMine
                  ? _buildMyActionVerification(context) // 파트너의 반응은 왼쪽 끝
                  : _buildPartnerActionVerification(
                      context,
                      ref,
                    ), // 나의 반응은 오른쪽 끝
            ),
            const SizedBox(height: 24), // 카드 간 간격
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
      case HistoryStatus.verified: // '확인됐어요' 배지는 제거하고 '했어'로 통합
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
      case HistoryStatus.skipped:
        color = AppColors.textDisabled;
        icon = Icons.hourglass_empty;
        label = l10n.reconcileSkip;
        break;
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

  Widget _buildCommentSection(BuildContext context) {
    if (item.comment == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.4), // 더 연하게 처리
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.comment!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// [내 실천] 카드 하단: 파트너의 확인 여부 표시
  Widget _buildMyActionVerification(BuildContext context) {
    if (!item.isVerifiedByPartner) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start, // 파트너의 반응은 왼쪽 끝 (상대가 보낸 것)
      mainAxisSize: MainAxisSize.min,
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
            color: AppColors.textSecondary.withValues(alpha: 0.8),
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
        mainAxisAlignment: MainAxisAlignment.end, // 나의 반응은 오른쪽 (내가 보낸 것)
        children: [
          Text(
            l10n.historyPartnerActionVerified,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.thumb_up, size: 14, color: AppColors.primary),
        ],
      );
    }

    return InkWell(
      onTap: () async {
        await ref.read(recordRepositoryProvider).verifyHistoryItem(item.id);
        ref.invalidate(historyItemsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('확인되었습니다.')));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08), // 조금 더 명확하게
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.historyPartnerActionWaiting,
              style: TextStyle(
                color: AppColors.primary, // 주어지는 주어 생략 정책에 따라 텍스트 강조
                fontSize: 12,
                fontWeight: FontWeight.w700, // 더 강조된 버튼 텍스트
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.check_circle_outline, // 더 명확한 '확인' 유도 아이콘
              size: 14,
              color: AppColors.primary,
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
