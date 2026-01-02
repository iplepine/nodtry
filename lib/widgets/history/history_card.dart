import 'package:flutter/material.dart';
import '../../models/history_item.dart';
import '../../theme/app_colors.dart';

class HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final bool isMe;
  final VoidCallback? onReconcile;

  const HistoryCard({
    super.key,
    required this.item,
    required this.isMe,
    this.onReconcile,
  });

  @override
  Widget build(BuildContext context) {
    // Mirror Layout: My cards aligned right, Partner cards aligned left
    final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bgColor = isMe
        ? AppColors.surface
        : Colors.white; // Minimal differentiation or use same

    // Status Logic
    final statusInfo = _getStatusInfo(item.status);
    final canReconcile = isMe && item.status == HistoryStatus.skipped;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner Avatar (Left)
          if (!isMe) ...[
            _Avatar(imageUrl: item.partnerImageUrl, name: item.partnerName),
            const SizedBox(width: 12),
          ],

          // Card Content
          Flexible(
            child: GestureDetector(
              onTap: canReconcile ? onReconcile : null,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  // Highlight reconcilable items slightly??
                  border: canReconcile
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Date & Status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDate(item.date),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusInfo.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                statusInfo.icon,
                                size: 12,
                                color: statusInfo.textColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusInfo.text,
                                style: TextStyle(
                                  color: statusInfo.textColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      item.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Comment (if any)
                    if (item.comment != null && item.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.comment!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    // Verification Badge
                    // My Item: Verified by Partner
                    if (isMe && item.isVerifiedByPartner) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.thumb_up_alt_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "파트너가 확인했어요", // TODO: L10n
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Partner Item: Verified by Me
                    if (!isMe && item.isVerifiedByMe) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "내가 확인했어요", // TODO: L10n
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Reconcile Hint
                    if (canReconcile) ...[
                      const SizedBox(height: 12),
                      Text(
                        "탭해서 상태 변경하기",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Me Avatar (Right) - Optional, usually Me doesn't show avatar in chat UI, but maybe consistent here?
          // Spec says "Mirror Layout" but usually "Me" is just bubbled right without avatar.
          // Let's hide avatar for Me for now to follow standard chat/timeline conventions.
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Setup simple date format
    return "${date.month}/${date.day}";
  }

  _StatusDisplayInfo _getStatusInfo(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.done:
        return _StatusDisplayInfo(
          text: '했어',
          color: AppColors.primary.withValues(alpha: 0.1),
          textColor: AppColors.primary,
          icon: Icons.check,
        );
      case HistoryStatus.actuallyDone:
        return _StatusDisplayInfo(
          text: '사실 했어요', // Reconciled
          color: AppColors.secondary.withValues(alpha: 0.1),
          textColor: AppColors.secondary,
          icon: Icons.check_circle_outline,
        );
      case HistoryStatus.rested:
        return _StatusDisplayInfo(
          text: '쉬어갔어요',
          color: Colors.grey.withValues(alpha: 0.1),
          textColor: AppColors.textSecondary,
          icon: Icons.hotel, // Bed icon
        );
      case HistoryStatus.skipped:
        return _StatusDisplayInfo(
          text: '지나갔어요',
          color: Colors.orange.withValues(alpha: 0.1),
          textColor: Colors.orange,
          icon: Icons.remove_circle_outline,
        );
      case HistoryStatus.verified:
        return _StatusDisplayInfo(
          text: '확인됨',
          color: AppColors.primary.withValues(alpha: 0.1),
          textColor: AppColors.primary,
          icon: Icons.verified,
        );
    }
  }
}

class _StatusDisplayInfo {
  final String text;
  final Color color;
  final Color textColor;
  final IconData icon;

  _StatusDisplayInfo({
    required this.text,
    required this.color,
    required this.textColor,
    required this.icon,
  });
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;

  const _Avatar({this.imageUrl, this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      backgroundColor: AppColors.surface,
      child: imageUrl == null
          ? Text(
              name?.isNotEmpty == true ? name![0] : '?',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          : null,
    );
  }
}
