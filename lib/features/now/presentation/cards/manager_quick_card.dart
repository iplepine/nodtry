part of '../now_tab_screen.dart';

class _ManagerQuickCard extends StatelessWidget {
  final HomeCardModel model;
  final String? partnerName;
  final VoidCallback? onApprove;

  /// One-tap 인정 with the tapped emoji (❤️🔥💪👏).
  final ValueChanged<String>? onReact;

  /// "한마디": the optional note dialog.
  final VoidCallback? onAddNote;
  final VoidCallback? onReject;
  final VoidCallback? onPokeUser;
  final VoidCallback? onPokePartner;

  /// 응원 보내기 on an auto-forwarded missed workout (encouragement, not 인정).
  final VoidCallback? onSendCheer;

  /// A cheer already went out from this card today.
  final bool cheerSent;

  /// The partner was already knocked for this promise today: 똑똑 is off.
  final bool knockSent;
  final VoidCallback? onRescue; // 실천 인정 (null = 버튼 숨김)
  final VoidCallback? onProposePromise;
  final VoidCallback? onAcknowledgePromiseSettled;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? exactTimeText;

  const _ManagerQuickCard({
    required this.model,
    this.partnerName,
    this.onApprove,
    this.onReact,
    this.onAddNote,
    this.onReject,
    this.onPokeUser,
    this.onPokePartner,
    this.onSendCheer,
    this.cheerSent = false,
    this.knockSent = false,
    this.onRescue,
    this.onProposePromise,
    this.onAcknowledgePromiseSettled,
    this.timeChipText,
    this.timeChipType,
    this.exactTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPartnerTodayComplete =
        model.state == HomeCardState.partnerTodayComplete;

    // The nickname first (spec §3); the generic label only without a name.
    // Sentence-initial lines use the capitalized fallback ("Your partner").
    final name = partnerName;
    final startName = name ?? l10n.partnerFallbackLabelStart;
    final midName = name ?? l10n.partnerFallbackLabel;
    final String headerText;
    switch (managerCardHeaderFor(model.state)) {
      case ManagerCardHeader.partnerTodayComplete:
        headerText = l10n.nowHeaderTodayAllDone;
      case ManagerCardHeader.partnerAction:
        headerText = l10n.nowHeaderConfirmAndPull(startName);
      case ManagerCardHeader.planProposed:
        headerText = l10n.nowPartnerProposed(startName);
      case ManagerCardHeader.planAdjusting:
        headerText = l10n.nowPartnerAdjusting;
      case ManagerCardHeader.partnerNoPlan:
        headerText = l10n.nowHeaderWaiting(midName);
      case ManagerCardHeader.waitingPromiseAccept:
        headerText = l10n.nowHeaderWaitingAccept;
      case ManagerCardHeader.promiseResult:
        headerText = l10n.nowHeaderPromiseResult;
      case ManagerCardHeader.fallback:
        headerText =
            model.state == HomeCardState.partnerPoke && model.hasMissedNotice
            ? l10n.nowHeaderPartnerMissed(startName)
            : model.headerMessage ?? l10n.homeReceivedMessage;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                if (partnerName != null) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    backgroundImage: model.partnerImageUrl != null
                        ? NetworkImage(model.partnerImageUrl!)
                        : null,
                    child: model.partnerImageUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Week indicator removed
                      Text(
                        headerText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                if (timeChipText != null && timeChipType != null) ...[
                  const SizedBox(width: 8),
                  if (exactTimeText != null)
                    Tooltip(
                      message: exactTimeText!,
                      triggerMode: TooltipTriggerMode.longPress,
                      child: TimeChip(text: timeChipText!, type: timeChipType!),
                    )
                  else
                    TimeChip(text: timeChipText!, type: timeChipType!),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Title (Diff Aware)
            if (!isPartnerTodayComplete &&
                model.plan?.items.firstOrNull?.title != null) ...[
              SizedBox(
                width: double.infinity,
                child: _buildDiffText(
                  context,
                  current: model.plan!.items.firstOrNull!.title,
                  previous: model.previousPlan?.items.firstOrNull?.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            // Scale & Period
            if (!isPartnerTodayComplete && model.plan != null)
              _buildPlanDetails(context, model.plan!, l10n),
            const SizedBox(height: 8),
            // Description (Diff Aware)
            if (!isPartnerTodayComplete &&
                model.plan?.items.firstOrNull?.description != null) ...[
              SizedBox(
                width: double.infinity,
                child: _buildDiffText(
                  context,
                  current: model.plan!.items.firstOrNull!.description,
                  previous: model.previousPlan?.items.firstOrNull?.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (isPartnerTodayComplete) ...[
              _buildPartnerTodayCompleteMessage(context),
            ],
            // 조정하기 / 승인 — decided by the card state, not its header text.
            if (showsPlanApprovalActions(model.state)) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
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
                        l10n.nowAdjust,
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
                      onPressed: onApprove,
                      style:
                          ElevatedButton.styleFrom(
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
                          ).copyWith(
                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.pressed)) {
                                    return AppColors.primaryPressed;
                                  }
                                  return null;
                                }),
                          ),
                      child: Text(
                        l10n.nowApprove,
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

            // Button (Partner No Plan - Poke)
            if (model.state == HomeCardState.partnerNoPlan) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Text(
                  l10n.nowPartnerNoNewPlanGuide,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPokeUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
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
                    l10n.nowKnockMakePlan,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else if (model.state == HomeCardState.partnerPoke) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Text(
                  model.hasMissedNotice
                      ? l10n.nowPartnerMissedPokeBody(
                          partnerName ?? l10n.nowPartnerFallback2,
                        )
                      : l10n.nowPartnerQuietPokeBody(
                          partnerName ?? l10n.nowPartnerFallback2,
                        ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ..._buildPokeButtons(context, l10n),
              // 실천 인정 버튼 (어제 놓친 경우)
              if (model.canRescue && onRescue != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onRescue,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.volunteer_activism,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        AppUnderlinedText(
                          l10n.nowRescueYesterday,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else if (model.state == HomeCardState.partnerAction ||
                model.state == HomeCardState.partnerTodayComplete) ...[
              // The partner's proof photo and note, then one-tap 인정.
              if (!isPartnerTodayComplete) ..._buildPartnerProof(context),
              const SizedBox(height: 16),
              ProofReactionRow(onReact: onReact, onAddNote: onAddNote),
            ] else if (model.state == HomeCardState.partnerPromiseProposed) ...[
              const SizedBox(height: 12),
              if (model.plan?.promise != null)
                _buildManagerPromiseDetail(context, model.plan!.promise!),
            ] else if (model.state == HomeCardState.promiseSettled) ...[
              const SizedBox(height: 12),
              if (model.plan?.promise != null)
                _buildManagerPromiseDetail(context, model.plan!.promise!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAcknowledgePromiseSettled,
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
                    l10n.nowPromiseAckButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            // "약속 걸기" 버튼 (partnerPoke, partnerPlanCreate에서 약속 없을 때)
            if ((model.state == HomeCardState.partnerPoke ||
                    model.state == HomeCardState.partnerPlanCreate ||
                    model.state == HomeCardState.partnerAction) &&
                (model.plan?.promise == null ||
                    model.plan?.promise?.status == PromiseStatus.rejected)) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onProposePromise,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentWine,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        size: 16,
                        color: AppColors.accentWine,
                      ),
                      const SizedBox(width: 4),
                      AppUnderlinedText(
                        l10n.nowMakePromise,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.accentWine,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The partnerPoke buttons. An auto-forwarded missed workout leads with
  /// 응원 보내기 and keeps 똑똑 second; otherwise 똑똑 is the action. 똑똑 is
  /// off once the promise was knocked today.
  List<Widget> _buildPokeButtons(BuildContext context, AppLocalizations l10n) {
    final knock = knockSent ? null : onPokePartner;
    final knockLabel = knockSent ? l10n.nowKnockSentToday : l10n.nowKnockPull;
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    const padding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    const label = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    if (!leadsWithCheer(model.state, hasMissedNotice: model.hasMissedNotice)) {
      return [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const ValueKey('partner-knock'),
            onPressed: knock,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: padding,
              shape: shape,
            ),
            child: Text(knockLabel, style: label),
          ),
        ),
      ];
    }
    return [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: const ValueKey('partner-cheer'),
          onPressed: cheerSent ? null : onSendCheer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: padding,
            shape: shape,
          ),
          child: Text(
            cheerSent ? l10n.nowCheerSent : l10n.nowSendCheer,
            style: label,
          ),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: const ValueKey('partner-knock'),
          onPressed: knock,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.outline),
            padding: padding,
            shape: shape,
          ),
          child: Text(knockLabel, style: label),
        ),
      ),
    ];
  }

  Widget _buildPartnerTodayCompleteMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedPartnerName = (partnerName?.trim().isNotEmpty ?? false)
        ? partnerName!.trim()
        : l10n.nowPartnerFallback2;
    final title = model.plan?.items.firstOrNull?.title;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.nowPartnerAllDone(resolvedPartnerName),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.nowQuickCheckHelp,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (title != null && title.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.nowLastAction(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          ..._buildPartnerProof(context),
        ],
      ),
    );
  }

  /// Today's proof photo of the partner's plan (if any) and their note.
  List<Widget> _buildPartnerProof(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = model.plan;
    if (plan == null) return const [];
    final photoPath = todayProofPhotoPathOf(plan);
    final note = plan.lastActionNote?.trim();
    return [
      if (photoPath != null) ...[
        const SizedBox(height: 12),
        ProofPhoto(
          key: ValueKey('partner-proof-$photoPath'),
          path: photoPath,
          // The plan has only the path: the badge's source and capture time
          // are read from the action the path points at.
          resolveMetaFromAction: true,
          height: 240,
        ),
      ],
      if (note != null && note.isNotEmpty) ...[
        const SizedBox(height: 12),
        _buildDatedNoteBubble(
          context,
          l10n: l10n,
          text: note,
          date: _lastActionNoteDate(plan),
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
      ],
    ];
  }

  Widget _buildManagerPromiseDetail(BuildContext context, Promise promise) {
    final l10n = AppLocalizations.of(context)!;
    final isSettled = promise.status == PromiseStatus.settled;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promise.reward != null) ...[
            Text(
              l10n.nowRewardLine(
                promise.reward!.targetDays,
                promise.reward!.description,
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ],
          if (promise.reward != null && promise.penalty != null)
            const SizedBox(height: 4),
          if (promise.penalty != null) ...[
            Text(
              l10n.nowPenaltyLine(
                promise.penalty!.targetDays,
                promise.penalty!.description,
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ],
          if (isSettled && promise.settledSuccessDays != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.nowResultLine(
                promise.settledSuccessDays!,
                promise.settledFailDays ?? 0,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (promise.settlementResult != null) ...[
              const SizedBox(height: 4),
              Text(
                _settlementResultText(promise.settlementResult!, l10n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 4),
            Text(
              l10n.nowWaitingApproval,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  String _settlementResultText(SettlementResult result, AppLocalizations l10n) {
    switch (result) {
      case SettlementResult.rewardAchieved:
        return l10n.nowRewardAchievedTitle;
      case SettlementResult.penaltyTriggered:
        return l10n.nowPenaltyTriggeredTitle;
      case SettlementResult.bothMet:
        return l10n.nowBothTitle;
      case SettlementResult.neitherMet:
        return l10n.nowConditionNotMet;
    }
  }

  Widget _buildDiffText(
    BuildContext context, {
    required String? current,
    required String? previous,
    required TextStyle? style,
  }) {
    // 변경된 내용이 없거나 previous가 없으면 현재 내용만 표시
    if (previous == null || current == previous) {
      return Text(current ?? '', style: style, textAlign: TextAlign.left);
    }

    // 변경된 내용이 있으면 취소선(Before) -> Normal(After) 표시
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          previous,
          style: style?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            // 취소선 스타일 조정 (선택 사항)
            decorationColor: AppColors.textSecondary,
          ),
          textAlign: TextAlign.left,
        ),
        // 약간의 간격? 원한다면 추가. 현재 요구사항엔 명시 없음.
        Text(current ?? '', style: style, textAlign: TextAlign.left),
      ],
    );
  }

  Widget _buildPlanDetails(
    BuildContext context,
    Plan plan,
    AppLocalizations l10n,
  ) {
    if (plan.items.isEmpty) return const SizedBox.shrink();
    final item = plan.items.first;

    // Period: 10.01(Mon) - 10.28(Sun)
    final start = plan.startDate;
    final end = plan.endDate;

    String getWeekday(DateTime d) =>
        TimeFormatter.getWeekdayName(l10n, d.weekday);
    final periodStr =
        '${start.month}.${start.day}(${getWeekday(start)}) - ${end.month}.${end.day}(${getWeekday(end)})';

    // Days: Mon, Wed, Fri
    final daysStr = item.days.length == 7
        ? l10n.frequencyEveryday
        : item.days
              .map((d) => TimeFormatter.getWeekdayName(l10n, d))
              .join(', ');

    return SizedBox(
      width: double.infinity,
      child: Text(
        '$periodStr · $daysStr',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14, // Increased
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}
