import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/history_item.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/history_provider.dart';
import '../../providers/repository_provider.dart';

/// 기록 카드 (Spec 3.1)
class HistoryCard extends ConsumerStatefulWidget {
  final HistoryItem item;

  const HistoryCard({super.key, required this.item});

  @override
  ConsumerState<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends ConsumerState<HistoryCard> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final isMine = widget.item.isMine('me'); // TODO: Pass real UID

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
                          _formatDate(context, widget.item.date),
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
                      widget.item.title,
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
            // 외부 반응 영역 (역할 기준 고정 정렬 & 안쪽 모서리 앵커링)
            Align(
              alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
              child: isMine
                  ? _buildMyActionVerification(context) // 파트너의 반응은 왼쪽 끝
                  : _buildPartnerActionVerification(context), // 나의 반응은 오른쪽 끝
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
    switch (widget.item.status) {
      case HistoryStatus.done:
      case HistoryStatus.actuallyDone:
      case HistoryStatus.verified: // '확인됐어요' 배지는 제거하고 '했어'로 통합
        color = const Color(0xFF6B8E23); // Olive Green
        icon = Icons.check_circle_outline;
        label = widget.item.status == HistoryStatus.actuallyDone
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
    if (widget.item.comment == null) return const SizedBox.shrink();

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
            widget.item.comment!,
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
    if (!widget.item.isVerifiedByPartner) return const SizedBox.shrink();

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

  Widget _buildPartnerActionVerification(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.item.isVerifiedByMe) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end, // 나의 반응은 오른쪽 (내가 보낸 것)
        mainAxisSize: MainAxisSize.min,
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

    if (_isMenuOpen) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.background),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              label: l10n.historyActionSawIt,
              onTap: () async {
                await ref
                    .read(recordRepositoryProvider)
                    .verifyHistoryItem(widget.item.id);
                ref.invalidate(historyItemsProvider);
                if (mounted) setState(() => _isMenuOpen = false);
              },
              color: AppColors.primary,
            ),
            _buildActionButton(
              label: l10n.historyActionCheer,
              onTap: () {
                // TODO: Implement Cheer action in repository if needed
                if (mounted) setState(() => _isMenuOpen = false);
              },
              color: Colors.purple,
            ),
            _buildActionButton(
              label: l10n.historyActionSkip,
              onTap: () {
                if (mounted) setState(() => _isMenuOpen = false);
              },
              color: AppColors.textSecondary,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isMenuOpen = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          l10n.historyPartnerActionWaiting,
          style: TextStyle(
            color: AppColors.textDisabled.withValues(alpha: 0.6), // 아주 연하게
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
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
