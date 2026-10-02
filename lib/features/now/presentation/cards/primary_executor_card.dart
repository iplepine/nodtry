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

  Widget _buildMessage(BuildContext context, AppLocalizations l10n) {
    // 오늘 완료한 플랜이 둘 이상이면 체크리스트로 보여줘 성취의 규모가 드러나게 한다.
    if (model.state == HomeCardState.todayComplete &&
        model.completedPlans.length >= 2) {
      return _buildMultiPlanCompleteMessage(context, l10n);
    }

    final title = model.plan?.items.firstOrNull?.title;
    final List<Widget> children = [];
    final hero = _isCheckInHero;

    // 오늘 {운동} 했어? — the question leads; the promise line follows.
    if (hero) {
      children.add(
        Text(
          todayCheckInQuestion(l10n, model.plan!),
          key: const ValueKey('now-hero-question'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
          textAlign: TextAlign.left,
        ),
      );
      if (title != null) children.add(const SizedBox(height: 6));
    }

    // Title (if applicable)
    if (title != null) {
      children.add(
        Text(
          title,
          style: hero
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                )
              : Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
          textAlign: TextAlign.left,
        ),
      );

      // Description
      final description = model.plan?.items.firstOrNull?.description;
      if (description != null && description.isNotEmpty) {
        children.add(const SizedBox(height: 4));
        children.add(
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.left,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
    }

    // 스트릭 배지
    if (model.streakCount != null && model.streakCount! >= 2) {
      children.add(const SizedBox(height: 8));
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.nowStreakCount(model.streakCount!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    String? statusMessage = model.headerMessage;
    // The partner was told about today's missing record: say who, by name.
    if (model.state == HomeCardState.poked && model.hasMissedNotice) {
      statusMessage = l10n.nowHeaderMissedNotice(
        model.partnerName ?? l10n.partnerFallbackLabel,
      );
    }
    String? subMessage; // Added for Type 2-1, 2-2 A/B, etc.

    if (statusMessage == null) {
      switch (model.state) {
        case HomeCardState.nowAction: // Type 1: 지금 실천
          // statusMessage = l10n.homeNowTask; // Removed per user request
          break;
        case HomeCardState.overdue: // Type 5: 지난 실천
          // statusMessage = l10n.timePassedActorMessage; // Removed per user request
          // subMessage = l10n.timePassedActorSubMessage;
          break;
        case HomeCardState.emptyPlan: // Type 2-1: 계획 필요
          statusMessage = l10n.nowNoPlan;
          subMessage = l10n.nowNoPlanSubtitle;
          break;
        case HomeCardState.todayComplete: // Type 2-2 A: 오늘 완료
          statusMessage = l10n.nowTodayDone;
          // Sub-message for next promise can be handled via upcoming schedule if available
          break;
        case HomeCardState.todayEmpty: // Type 2-2 B: 여유로운 날
          statusMessage = l10n.nowQuietRest;
          break;
        case HomeCardState.rejected: // Type 1-7: 반려됨
          statusMessage = l10n.nowHeaderAdjustNeeded;
          break;
        case HomeCardState.nextAction: // Type 1-3: 다음 일정 (이따·아무 때나)
          // The check-in hero asks the question itself.
          if (hero) break;
          final nt = model.plan?.items.firstOrNull?.notificationTime;
          final hasTime = nt != null && nt.type != 'none';
          statusMessage = hasTime
              ? l10n.nowNextActionLater
              : l10n.nowNextActionAnytime;
          break;
        case HomeCardState.poked:
          // 똑똑 배지에서 안내하므로 별도 statusMessage 없음
          break;
        case HomeCardState.promiseProposed:
          statusMessage = l10n.nowHeaderPromiseProposed;
          break;
        case HomeCardState.promiseSettled:
          statusMessage = l10n.nowHeaderPromiseSettled;
          break;
        case HomeCardState.pilotSettlement:
          statusMessage = l10n.nowHeaderSettlementNeeded;
          subMessage = l10n.nowHeaderSettlementSub;
          break;
        default:
          break;
      }
    }

    if (statusMessage != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(
        ReactionText(
          statusMessage,
          style:
              (title != null
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    color: title != null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    height: 1.5,
                  ),
          textAlign: TextAlign.left,
        ),
      );
    }

    // Render Sub-message if exists (e.g. for Plan Needed)
    if (subMessage != null) {
      children.add(const SizedBox(height: 4));
      children.add(
        Text(
          subMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.left,
        ),
      );
    }

    // My own proof photo once today's promise is recorded.
    if (model.state == HomeCardState.todayComplete) {
      final photoPath = todayProofPhotoPathOf(model.plan);
      if (photoPath != null) {
        children.add(const SizedBox(height: 12));
        children.add(
          ProofPhoto(
            key: ValueKey('own-proof-$photoPath'),
            path: photoPath,
            isOwner: true,
            resolveMetaFromAction: true,
            height: 200,
          ),
        );
      }
      // Close the loop: the partner's one-tap 인정 for today.
      final plan = model.plan;
      if (plan != null && _verifiedToday(plan)) {
        final reaction = plan.lastCheerType;
        children.add(const SizedBox(height: 10));
        children.add(
          Row(
            key: const ValueKey('now-partner-verified'),
            children: [
              if (reaction != null && ReactionIcon.assetFor(reaction) != null)
                ReactionIcon(reaction, size: 20)
              else
                Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.historyPartnerVerified,
                  style: TextStyle(
                    color: AppColors.primaryPressed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // ----------------------------------------------------
    // 1. lastActionNote (실천자 한마디 - 나/파트너 공통)
    // 날짜 라벨을 위에 붙여 "오늘은 ..."이 어제 작성된 메모임을 분명히 한다.
    // ----------------------------------------------------
    if (model.plan?.lastActionNote != null &&
        model.plan!.lastActionNote!.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(
        _buildDatedNoteBubble(
          context,
          l10n: l10n,
          text: model.plan!.lastActionNote!,
          date: _lastActionNoteDate(model.plan!),
          background: AppColors.background.withValues(alpha: 0.5),
          noteColor: AppColors.textPrimary,
          noteItalic: true,
          radius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(2),
          ),
        ),
      );
    }

    // ----------------------------------------------------
    // 2. lastComment (매니저 피드백/응원)
    // lastCheerAt 기준으로 날짜 라벨을 붙인다.
    // lastCheerType(👍/❤️/💪 같은 리액션 이모지)과 lastComment를 나란히
    // 놓으면 ① 파트너가 보통 코멘트에도 이모지를 같이 치기 때문에 의미가
    // 중복되고 ② 두 Text의 fontSize/strut이 달라 윗선이 어긋난다.
    // ----------------------------------------------------
    if (model.plan?.lastComment != null &&
        model.plan!.lastComment!.isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(
        _buildDatedNoteBubble(
          context,
          l10n: l10n,
          text: model.plan!.lastComment!,
          date: model.plan!.lastCheerAt,
          background: AppColors.primary.withValues(alpha: 0.1),
          noteColor: AppColors.primary,
          dateLabelColor: AppColors.primary.withValues(alpha: 0.75),
          noteWeight: FontWeight.w600,
          radius: BorderRadius.circular(12),
        ),
      );
    }

    // ----------------------------------------------------
    // 3. Promise 상세 (약속 제안/정산 결과)
    // ----------------------------------------------------
    if (model.plan?.promise != null) {
      final promise = model.plan!.promise!;
      if (model.state == HomeCardState.promiseProposed ||
          model.state == HomeCardState.promiseSettled) {
        children.add(const SizedBox(height: 12));
        children.add(_buildPromiseDetail(context, promise));
      }
    }

    if (model.state == HomeCardState.pilotSettlement && model.plan != null) {
      children.add(const SizedBox(height: 12));
      children.add(_buildPilotSettlementDetail(context, model.plan!));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildPilotSettlementDetail(BuildContext context, Plan plan) {
    final l10n = AppLocalizations.of(context)!;
    final totalScheduled = _scheduledDaysCount(plan);
    final completed = plan.completedDates.length;
    final feedback = _partnerFeedbackCount(plan);
    final missed = (totalScheduled - completed).clamp(0, totalScheduled);

    // Judge the outcome against the goal the user actually set with their
    // partner (the reward target) — not a fixed day count. A short plan (e.g.
    // 2x/week → 8 scheduled days) can never reach an absolute threshold, so a
    // perfect run used to read as a failure. With no reward promise there is no
    // win/lose at all, so we show a neutral wrap-up message instead.
    final rewardTarget = plan.promise?.reward?.targetDays;
    final String settlementMessage;
    if (rewardTarget == null) {
      settlementMessage = l10n.nowSettlementNeutralMessage;
    } else if (completed >= rewardTarget) {
      settlementMessage = l10n.nowSettlementWinMessage;
    } else {
      settlementMessage = l10n.nowSettlementLoseMessage;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSettlementMetric(
                  l10n.nowMetricCompleted,
                  l10n.nowMetricDaysSuffix(completed),
                ),
              ),
              Expanded(
                child: _buildSettlementMetric(
                  l10n.nowMetricPartnerReact,
                  l10n.nowMetricCountSuffix(feedback),
                ),
              ),
              Expanded(
                child: _buildSettlementMetric(
                  l10n.nowMetricMissed,
                  l10n.nowMetricDaysSuffix(missed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            settlementMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  int _scheduledDaysCount(Plan plan) {
    return plan.scheduledDayCount;
  }

  int _partnerFeedbackCount(Plan plan) {
    var count = plan.verifiedDates.length + plan.rescuedDates.length;
    if (plan.lastCheerAt != null) count++;
    if (plan.lastPokeAt != null) count++;
    return count;
  }

  Widget _buildPromiseDetail(BuildContext context, Promise promise) {
    final l10n = AppLocalizations.of(context)!;
    final isSettled = promise.status == PromiseStatus.settled;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promise.reward != null) ...[
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.nowRewardCondition(
                      promise.reward!.targetDays,
                      promise.reward!.description,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSettled)
                  _buildSettlementBadge(context, promise, isReward: true),
              ],
            ),
          ],
          if (promise.reward != null && promise.penalty != null)
            const SizedBox(height: 8),
          if (promise.penalty != null) ...[
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.nowPenaltyCondition(
                      promise.penalty!.targetDays,
                      promise.penalty!.description,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSettled)
                  _buildSettlementBadge(context, promise, isReward: false),
              ],
            ),
          ],
          if (isSettled && promise.settledSuccessDays != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.nowPromiseResult(
                promise.settledSuccessDays!,
                promise.settledFailDays ?? 0,
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettlementBadge(
    BuildContext context,
    Promise promise, {
    required bool isReward,
  }) {
    final result = promise.settlementResult;
    final bool achieved;
    if (isReward) {
      achieved =
          result == SettlementResult.rewardAchieved ||
          result == SettlementResult.bothMet;
    } else {
      achieved =
          result == SettlementResult.penaltyTriggered ||
          result == SettlementResult.bothMet;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: achieved
            ? (isReward ? AppColors.success : AppColors.error).withValues(
                alpha: 0.15,
              )
            : AppColors.disabled.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        achieved
            ? (isReward
                  ? AppLocalizations.of(context)!.nowAchieved
                  : AppLocalizations.of(context)!.nowTriggered)
            : AppLocalizations.of(context)!.nowNotMet,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: achieved
              ? (isReward ? AppColors.success : AppColors.error)
              : AppColors.textDisabled,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildPromiseProposedButtons(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRejectPromise,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.nowDecline,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: onAcceptPromise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.nowAccept,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromiseSettledButton(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAcknowledgePromiseSettled,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.nowPromiseAckButton,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  /// nextAction(이따·아무 때나) 카드용 약한 액션 버튼.
  /// 채워진 "했어" 버튼 대신 외곽선 버튼을 써서 "지금 당장"이 아님을 시각적으로 전달한다.
  Widget _buildNextActionButton(BuildContext context, AppLocalizations l10n) {
    final nt = model.plan?.items.firstOrNull?.notificationTime;
    final hasTime = nt != null && nt.type != 'none';
    final label = hasTime ? l10n.nowDoEarly : l10n.nowDoAnytime;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onDidIt,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  static bool _verifiedToday(Plan plan) {
    final now = DateTime.now();
    return plan.verifiedDates.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }

  /// Whether this card is the "오늘 {운동} 했어?" check-in hero.
  bool get _isCheckInHero =>
      showsTodayCheckInHero(model.state, model.plan, now: DateTime.now());

  /// 📸 인증샷 찍기 (primary) / 사진 없이 했어 / 오늘은 쉴게 (rest pass) — or,
  /// on an overdue card without a rest pass, the old skip link. A promise
  /// from before the pivot (no workout type) says 인증하기 instead of asking
  /// for a workout photo (spec §4.4); the photo stays optional there too.
  Widget _buildHeroButtons(BuildContext context, AppLocalizations l10n) {
    final canRest = onRest != null && model.plan?.canUseRestToday == true;
    final legacy = workoutDisplayFor(l10n, model.plan?.workoutType) == null;
    final showSkip =
        !canRest && model.state == HomeCardState.overdue && onSkip != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          key: const ValueKey('now-hero-photo'),
          onPressed: onProofPhoto ?? onDidIt,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return AppColors.primaryPressed;
                  }
                  return null;
                }),
              ),
          child: Text(
            legacy ? l10n.nowHeroVerifyLegacy : l10n.nowProofTakePhoto,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('now-hero-no-photo'),
          onPressed: onDidIt,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary, width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            l10n.nowDidItNoPhoto,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        // 지금 할게! (집중 타이머) — hidden for the pivot (_kFocusTimerEnabled).
        if (onFocusTimer != null &&
            (model.state == HomeCardState.nowAction ||
                model.state == HomeCardState.poked)) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onFocusTimer,
            icon: Icon(
              Icons.timer_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            label: Text(
              l10n.nowStartFocusTimer,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        if (canRest || showSkip) ...[
          const SizedBox(height: 8),
          TextButton(
            key: ValueKey(canRest ? 'now-hero-rest' : 'now-hero-skip'),
            onPressed: canRest ? onRest : onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 32),
              padding: const EdgeInsets.symmetric(vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: AppUnderlinedText(
              canRest ? l10n.nowRestToday : l10n.nowActionSkipToday,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildButton(BuildContext context, AppLocalizations l10n) {
    final buttonTextColor = Colors.white;
    VoidCallback? onPressed;
    String buttonText;

    if (_isCheckInHero) return _buildHeroButtons(context, l10n);

    if (model.state == HomeCardState.pilotSettlement) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinueAfterSettlement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.nowContinueNext4Weeks,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onExitAfterSettlement,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 32),
              padding: const EdgeInsets.symmetric(vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: AppUnderlinedText(
              l10n.nowStopHere,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    if (model.state == HomeCardState.nowAction ||
        model.state == HomeCardState.poked) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (model.state == HomeCardState.overdue) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (model.state == HomeCardState.emptyPlan) {
      buttonText = l10n.nowCreatePlan;
      onPressed = onCreatePlan;
    } else if (model.state == HomeCardState.rejected) {
      buttonText = l10n.nowModify;
      onPressed = onModify;
    } else if (model.state == HomeCardState.promiseProposed) {
      return _buildPromiseProposedButtons(context);
    } else if (model.state == HomeCardState.promiseSettled) {
      return _buildPromiseSettledButton(context, l10n);
    } else if (model.state == HomeCardState.todayComplete ||
        model.state == HomeCardState.todayEmpty) {
      // "작은 버튼" 요청: TextButton으로 구현
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onCreatePlan,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppUnderlinedText(
                l10n.nowAddMorePlan,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 10),
            ],
          ),
        ),
      );
    } else if (model.state == HomeCardState.nextAction) {
      // 아직 시간이 안 된 항목: 압박 없이 "미리 할 수 있다"는 약한 액션만 제공.
      return _buildNextActionButton(context, l10n);
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: buttonTextColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.pressed)) {
                      return AppColors.primaryPressed;
                    }
                    return null;
                  }),
                ),
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: buttonTextColor,
              ),
            ),
          ),
        ),
        // 지금 할게! (집중 타이머)
        if ((model.state == HomeCardState.nowAction ||
                model.state == HomeCardState.poked) &&
            onFocusTimer != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onFocusTimer,
              icon: Icon(
                Icons.timer_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                l10n.nowStartFocusTimer,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        // 휴식권 버튼 (nowAction에서 사용 가능 시)
        if ((model.state == HomeCardState.nowAction ||
                model.state == HomeCardState.poked) &&
            onRest != null &&
            model.plan?.canUseRestToday == true) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRest,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 32),
              padding: const EdgeInsets.symmetric(vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: AppUnderlinedText(
              l10n.nowRestToday,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
        if (model.state == HomeCardState.overdue && onSkip != null) ...[
          const SizedBox(height: 12),
          // 휴식권 우선, 없으면 skip
          if (onRest != null && model.plan?.canUseRestToday == true)
            TextButton(
              onPressed: onRest,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(double.infinity, 32),
                padding: const EdgeInsets.symmetric(vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: AppUnderlinedText(
                l10n.nowRestToday,
                style: const TextStyle(fontSize: 13),
              ),
            )
          else
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(double.infinity, 32),
                padding: const EdgeInsets.symmetric(vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: AppUnderlinedText(
                l10n.nowActionSkipToday,
                style: const TextStyle(fontSize: 13),
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
