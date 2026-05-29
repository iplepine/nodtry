import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/history_item.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../action_note_dialog.dart';
import '../app_underlined_text.dart';
import '../reaction_icon.dart';
import '../../features/history/presentation/history_viewmodel.dart';
import '../../features/history/presentation/history_state.dart';

class HistoryCard extends ConsumerWidget {
  final HistoryItem item;
  final bool isMe;
  final VoidCallback? onReconcile;

  /// 직전 카드와 같은 plan에 속해 제목을 반복 표시할 필요가 없을 때 false.
  /// 메모/상태가 시각적 주인공이 되도록 제목 라인을 생략한다.
  final bool showTitle;

  const HistoryCard({
    super.key,
    required this.item,
    required this.isMe,
    this.onReconcile,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mirror Layout: My cards aligned right, Partner cards aligned left
    final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bgColor = isMe
        ? AppColors.surface
        : Colors.white; // Minimal differentiation or use same

    // Status Logic
    final statusInfo = _getStatusInfo(context, item.status);
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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  // 평시에도 hairline outline으로 카드를 배경에서 분리.
                  // reconcilable 상태는 primary tint로 강조.
                  border: Border.all(
                    color: canReconcile
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.outline.withValues(alpha: 0.5),
                    width: canReconcile ? 1 : 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Date & Status
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _formatDate(context, item.date),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        _HistoryStatusBadge(statusInfo: statusInfo),
                      ],
                    ),
                    // Title — 직전 카드와 같은 plan이면 생략해서 노이즈 줄임.
                    if (showTitle) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    // note (실천자 소감)
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.note!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],

                    // comment (매니저 피드백)
                    // 칩 배경 자체가 응원 신호 역할을 하고, 본문에 사용자가 넣은
                    // 이모지(👏 🙌 ❤️ 등)가 시각적 hook이라 하트 Icon을 따로 두면
                    // Material 글리프/컬러 이모지/한글 텍스트가 각자 다른 baseline을
                    // 가져 세로 정렬이 본질적으로 안 맞는다. Icon을 빼고 텍스트
                    // 한 줄로 두면 정렬 문제가 발생할 자리 자체가 사라진다.
                    if (item.comment != null && item.comment!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ReactionText(
                          item.comment!,
                          style: TextStyle(
                            color: AppColors.primaryPressed,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    // Verification Badge
                    // My Item: Verified by Partner — 작은 감정 mini-card로 격상.
                    // 파트너 아바타 + "확인했어요" + (옵션) 파트너 메시지.
                    if (isMe && item.isVerifiedByPartner) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _Avatar(
                              imageUrl: item.partnerImageUrl,
                              name: item.partnerName,
                              radius: 12,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.historyPartnerVerified,
                                    style: TextStyle(
                                      color: AppColors.primaryPressed,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (item.partnerMessage != null &&
                                      item.partnerMessage!.isNotEmpty &&
                                      item.partnerMessage != item.comment) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.partnerMessage!,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
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
                            AppLocalizations.of(context)!.historyMeVerified,
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else if (!isMe &&
                        !item.isVerifiedByMe &&
                        item.status == HistoryStatus.done) ...[
                      // Not verified yet button
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Show Dialog to input feedback (reuse ActionNoteDialog)
                            final feedback = await showDialog<String>(
                              context: context,
                              builder: (context) => ActionNoteDialog(
                                title: item.title,
                                hintText: AppLocalizations.of(context)!.historyCardFeedbackHint,
                                buttonLabel: AppLocalizations.of(context)!.historyCardFeedbackButton,
                              ),
                            );

                            if (feedback != null) {
                              ref
                                  .read(historyViewModelProvider.notifier)
                                  .dispatch(
                                    HistoryIntent.verify(
                                      item.id,
                                      message: feedback,
                                    ),
                                  );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.historyCardFeedbackButton,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],

                    // Reconcile Hint
                    if (canReconcile) ...[
                      const SizedBox(height: 12),
                      AppUnderlinedText(
                        AppLocalizations.of(context)!.historyTapToChange,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
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

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    return DateFormat(l10n.historyCardDatePattern, l10n.localeName).format(date);
  }

  _StatusDisplayInfo _getStatusInfo(
    BuildContext context,
    HistoryStatus status,
  ) {
    switch (status) {
      case HistoryStatus.done:
        return _StatusDisplayInfo(
          text: AppLocalizations.of(context)!.homeDidIt,
          color: AppColors.primary.withValues(alpha: 0.1),
          textColor: AppColors.primary,
          icon: Icons.check,
        );
      case HistoryStatus.actuallyDone:
        return _StatusDisplayInfo(
          text: AppLocalizations.of(context)!.nowStatusActuallyDone,
          color: AppColors.secondary.withValues(alpha: 0.1),
          textColor: AppColors.secondary,
          icon: Icons.check_circle_outline,
        );
      case HistoryStatus.rested:
        return _StatusDisplayInfo(
          text: AppLocalizations.of(context)!.reconcileTookRest,
          color: Colors.grey.withValues(alpha: 0.1),
          textColor: AppColors.textSecondary,
          icon: Icons.hotel, // Bed icon
        );
      case HistoryStatus.skipped:
        return _StatusDisplayInfo(
          text: AppLocalizations.of(context)!.timeChipPassed,
          color: Colors.orange.withValues(alpha: 0.1),
          textColor: Colors.orange,
          icon: Icons.remove_circle_outline,
        );
      case HistoryStatus.verified:
        return _StatusDisplayInfo(
          text: AppLocalizations.of(context)!.homeChecked,
          color: AppColors.primary.withValues(alpha: 0.1),
          textColor: AppColors.primary,
          icon: Icons.verified,
        );
      case HistoryStatus.rescued:
        return _StatusDisplayInfo(
          text: AppLocalizations.of(context)!.historyCardAcknowledgePractice,
          color: AppColors.secondary.withValues(alpha: 0.1),
          textColor: AppColors.secondary,
          icon: Icons.volunteer_activism,
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

class _HistoryStatusBadge extends StatelessWidget {
  final _StatusDisplayInfo statusInfo;

  const _HistoryStatusBadge({required this.statusInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusInfo.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: 11, color: statusInfo.textColor),
          const SizedBox(width: 5),
          Text(
            statusInfo.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: statusInfo.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;

  const _Avatar({this.imageUrl, this.name, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final fallback = _FallbackAvatar(name: name, radius: radius);

    if (imageUrl == null || imageUrl!.trim().isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: Colors.white,
        child: CircleAvatar(radius: radius, backgroundColor: Colors.white),
      ),
      errorWidget: (context, url, error) => fallback,
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String? name;
  final double radius;

  const _FallbackAvatar({this.name, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final initial = _initial(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.66,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryPressed,
              ),
            )
          : Icon(
              Icons.person_rounded,
              size: radius,
              color: AppColors.primaryPressed,
            ),
    );
  }

  String? _initial(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return String.fromCharCode(trimmed.runes.first);
  }
}
