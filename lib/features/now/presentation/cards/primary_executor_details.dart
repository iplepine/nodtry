part of '../now_tab_screen.dart';

/// The primary card's promise and 4-week settlement detail boxes. Split out
/// of primary_executor_card.dart.
extension _PrimaryExecutorDetails on _PrimaryExecutorCard {
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
}
