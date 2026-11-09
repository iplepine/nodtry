part of '../now_tab_screen.dart';

/// The primary card's buttons for each card state. Split out of
/// primary_executor_card.dart.
extension _PrimaryExecutorButtons on _PrimaryExecutorCard {
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
