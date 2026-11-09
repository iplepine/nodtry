part of '../now_tab_screen.dart';

class _PrimaryExecutorCard extends StatelessWidget {
  final HomeCardModel model;
  final VoidCallback? onTap;
  final VoidCallback? onDidIt;

  /// 📸 인증샷 찍기 on the check-in hero.
  final VoidCallback? onProofPhoto;
  final VoidCallback? onFocusTimer;
  final VoidCallback? onSkip;
  final VoidCallback? onRest; // 휴식권
  final VoidCallback? onCreatePlan;
  final VoidCallback? onModify; // Added
  final VoidCallback? onAcceptPromise;
  final VoidCallback? onRejectPromise;
  final VoidCallback? onContinueAfterSettlement;
  final VoidCallback? onExitAfterSettlement;
  final VoidCallback? onAcknowledgePromiseSettled;
  // 우측 상단 '넘기기' 아이콘 — 잠시 후에 할지 / 오늘은 안 할지 고르는 시트를 연다.
  final VoidCallback? onDismissOptions;
  // 카드를 좌우로 스와이프하면 호출 — 캐러셀 이전/다음 카드로 이동.
  final void Function(DragEndDetails details)? onHorizontalSwipe;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? exactTimeText;

  /// One-tap answers to today's knock (지금 간다 🏃 / 오늘은 봐줘 🙏); null hides
  /// them (no knock today, already answered, or already recorded).
  final ValueChanged<PokeReplyKind>? onPokeReply;

  const _PrimaryExecutorCard({
    super.key,
    required this.model,
    this.onPokeReply,
    this.onDidIt,
    this.onProofPhoto,
    this.onFocusTimer,
    this.onSkip,
    this.onRest,
    this.onCreatePlan,
    this.onModify, // Added
    this.onAcceptPromise,
    this.onRejectPromise,
    this.onContinueAfterSettlement,
    this.onExitAfterSettlement,
    this.onAcknowledgePromiseSettled,
    this.onDismissOptions,
    this.onTap,
    this.onHorizontalSwipe,
    this.timeChipText,
    this.timeChipType,
    this.exactTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragEnd: onHorizontalSwipe,
      child: Card(
        // Opaque white like the rest of the screen: a translucent surface
        // with elevation read as grey on device.
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (model.state == HomeCardState.poked ||
                      onPokeReply != null) ...[
                    _PokeBadge(partnerName: model.partnerName),
                    if (onPokeReply != null) ...[
                      const SizedBox(height: 8),
                      _PokeReplyRow(onReply: onPokeReply!),
                    ],
                    const SizedBox(height: 12),
                  ],
                  if (timeChipText != null && timeChipType != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Week indicator removed per user request
                        exactTimeText != null
                            ? Tooltip(
                                message: exactTimeText!,
                                triggerMode: TooltipTriggerMode.longPress,
                                child: TimeChip(
                                  text: timeChipText!,
                                  type: timeChipType!,
                                ),
                              )
                            : TimeChip(
                                text: timeChipText!,
                                type: timeChipType!,
                              ),
                      ],
                    ),
                  if (timeChipText != null && timeChipType != null)
                    const SizedBox(height: 12),
                  _buildMessage(context, l10n),
                  if (model.plan != null && _showsGoal.contains(model.state))
                    PlanGoalLabel(plan: model.plan!, topSpacing: 10),
                  if (_shouldShowActivePromiseChip()) ...[
                    const SizedBox(height: 12),
                    ActivePromiseChip(plan: model.plan!),
                  ],
                  const SizedBox(height: 20),
                  _buildButton(context, l10n),
                ],
              ),
            ),
            if ((model.state == HomeCardState.nowAction ||
                    model.state == HomeCardState.overdue ||
                    model.state == HomeCardState.poked) &&
                onDismissOptions != null)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: onDismissOptions,
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  tooltip: AppLocalizations.of(context)!.nowDeferMenuTooltip,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Card states that carry one running promise, where its D-day shows.
  static const _showsGoal = {
    HomeCardState.nowAction,
    HomeCardState.nextAction,
    HomeCardState.overdue,
    HomeCardState.poked,
  };

  bool _shouldShowActivePromiseChip() {
    final plan = model.plan;
    final promise = plan?.promise;
    if (plan == null || promise == null) return false;
    if (promise.status != PromiseStatus.active) return false;
    return model.state == HomeCardState.nowAction ||
        model.state == HomeCardState.poked ||
        model.state == HomeCardState.overdue;
  }

  /// TodayComplete + 다중 플랜용 메시지 영역.
  /// 카운트 헤드라인 + 각 플랜의 체크리스트 row(스트릭이 있으면 작은 뱃지).
  Widget _buildMultiPlanCompleteMessage(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final plans = model.completedPlans;
    final children = <Widget>[
      Text(
        l10n.nowTodayAllDone(plans.length),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        textAlign: TextAlign.left,
      ),
      const SizedBox(height: 12),
    ];

    for (var i = 0; i < plans.length; i++) {
      if (i > 0) children.add(const SizedBox(height: 8));
      children.add(_buildCompletedPlanRow(context, plans[i]));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildCompletedPlanRow(BuildContext context, Plan plan) {
    final title = plan.items.firstOrNull?.title ?? '';
    final streak = plan.currentStreak;
    final photoPath = todayProofPhotoPathOf(plan);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
        if (photoPath != null) ...[
          const SizedBox(width: 8),
          ProofPhoto(
            key: ValueKey('own-proof-$photoPath'),
            path: photoPath,
            isOwner: true,
            resolveMetaFromAction: true,
            width: 44,
            height: 44,
            borderRadius: 10,
          ),
        ],
        if (streak >= 2) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  '$streak',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PokeBadge extends StatelessWidget {
  final String? partnerName;

  const _PokeBadge({this.partnerName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = partnerName == null || partnerName!.isEmpty
        ? l10n.nowPokeReceived
        : l10n.nowPokeReceivedFromName(partnerName!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 지금 간다 🏃 / 오늘은 봐줘 🙏 — partner-to-partner 반말, one tap each.
class _PokeReplyRow extends StatelessWidget {
  const _PokeReplyRow({required this.onReply});

  final ValueChanged<PokeReplyKind> onReply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget reply(PokeReplyKind kind, String label) => Expanded(
      child: OutlinedButton(
        key: ValueKey('poke-reply-${kind.id}'),
        onPressed: () => onReply(kind),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
    return Row(
      children: [
        reply(PokeReplyKind.coming, l10n.nowPokeReplyComing),
        const SizedBox(width: 8),
        reply(PokeReplyKind.pass, l10n.nowPokeReplyPass),
      ],
    );
  }
}

/// Primary 카드 캐러셀의 페이지 인디케이터 (점 + 카운터).
class _PrimaryCarouselIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final ValueChanged<int>? onTap;

  const _PrimaryCarouselIndicator({
    required this.count,
    required this.activeIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap == null ? null : () => onTap!(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              // Tap target stays comfortable while the dot itself is small.
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              width: i == activeIndex ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == activeIndex
                    ? AppColors.primary
                    : AppColors.textDisabled.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}
