import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../models/promise_model.dart';
import '../../../../theme/app_colors.dart';

/// 약속 상세 화면 상단에 노출되는 "진행 현황" 카드.
/// 성공률 / 연속 달성 / 실천·남음·놓침 카운트 + (있다면) 약속 진행률을 한 곳에서 보여준다.
/// active 플랜은 오늘까지 기준, completed 플랜은 전체 기간 기준으로 산정한다.
class PlanProgressCard extends StatelessWidget {
  final Plan plan;

  const PlanProgressCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = _PlanStats.from(plan);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.planDetailProgressTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHeadlineRate(context, l10n, stats),
          const SizedBox(height: 16),
          _buildProgressBar(stats),
          const SizedBox(height: 20),
          _buildMetricRow(context, l10n, stats),
          if (plan.promise != null) ...[
            const SizedBox(height: 20),
            Divider(
              color: AppColors.primary.withValues(alpha: 0.18),
              height: 1,
            ),
            const SizedBox(height: 16),
            _PromiseProgressBlock(plan: plan, promise: plan.promise!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeadlineRate(
    BuildContext context,
    AppLocalizations l10n,
    _PlanStats stats,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          stats.hasVerdict ? '${stats.successRatePercent}%' : '–',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 44,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.planDetailProgressSuccessRate,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats.hasVerdict
                      ? l10n.planDetailProgressFractionDays(
                          stats.success,
                          stats.totalForRate,
                        )
                      : l10n.planDetailProgressNoVerdictYet,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(_PlanStats stats) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: stats.successRate,
        minHeight: 8,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    AppLocalizations l10n,
    _PlanStats stats,
  ) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: l10n.planDetailProgressStreakLabel,
            value: l10n.planDetailProgressCountUnit(stats.streak),
            highlight: stats.streak >= 3,
          ),
        ),
        Expanded(
          child: _MetricTile(
            label: l10n.planDetailProgressDoneLabel,
            value: l10n.planDetailProgressDayUnit(stats.success),
          ),
        ),
        Expanded(
          child: _MetricTile(
            label: stats.isCompleted
                ? l10n.planDetailProgressMissedLabel
                : l10n.planDetailProgressRemainingLabel,
            value: l10n.planDetailProgressDayUnit(
              stats.isCompleted ? stats.failed : stats.remaining,
            ),
            muted: stats.isCompleted && stats.failed == 0,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool muted;

  const _MetricTile({
    required this.label,
    required this.value,
    this.highlight = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: muted
                ? AppColors.textDisabled
                : (highlight ? AppColors.primary : AppColors.textPrimary),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PromiseProgressBlock extends StatelessWidget {
  final Plan plan;
  final Promise promise;

  const _PromiseProgressBlock({required this.plan, required this.promise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final success = plan.completedDayCount();
    final failed = plan.failedDayCount();
    final remaining = plan.remainingScheduledDayCount();
    final reward = promise.reward;
    final penalty = promise.penalty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.handshake_outlined,
              color: AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.planDetailPromiseProgressTitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.planDetailPromiseSuccessFailBreakdown(success, failed),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reward != null) ...[
          _PromiseRow(
            label: l10n.planDetailPromiseRewardLabel,
            description: reward.description,
            statusText: _rewardStatusText(l10n, reward, success),
            progress: (success / reward.targetDays).clamp(0.0, 1.0),
            color: AppColors.primary,
          ),
        ],
        if (reward != null && penalty != null) const SizedBox(height: 12),
        if (penalty != null) ...[
          _PromiseRow(
            label: l10n.planDetailPromisePenaltyLabel,
            description: penalty.description,
            statusText: _penaltyStatusText(l10n, penalty, success, remaining),
            progress: _penaltyProgress(penalty, failed),
            color: AppColors.warningBorder,
          ),
        ],
      ],
    );
  }

  String _rewardStatusText(
    AppLocalizations l10n,
    PromiseReward reward,
    int success,
  ) {
    final needed = reward.targetDays - success;
    if (needed <= 0) return l10n.planDetailPromiseRewardAchieved;
    return l10n.planDetailPromiseRewardNeed(needed);
  }

  String _penaltyStatusText(
    AppLocalizations l10n,
    PromisePenalty penalty,
    int success,
    int remaining,
  ) {
    final buffer = (success + remaining) - penalty.targetDays;
    if (buffer < 0) return l10n.planDetailPromisePenaltyTriggered;
    if (buffer == 0) return l10n.planDetailPromisePenaltyImminent;
    return l10n.planDetailPromisePenaltyBuffer(buffer);
  }

  double _penaltyProgress(PromisePenalty penalty, int failed) {
    if (penalty.targetDays <= 0) return 0;
    return (failed / penalty.targetDays).clamp(0.0, 1.0);
  }
}

class _PromiseRow extends StatelessWidget {
  final String label;
  final String description;
  final String statusText;
  final double progress;
  final Color color;

  const _PromiseRow({
    required this.label,
    required this.description,
    required this.statusText,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          statusText,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PlanStats {
  final int success;
  final int failed;
  final int remaining;
  final int streak;
  final int scheduledTotal;
  final bool isCompleted;

  const _PlanStats({
    required this.success,
    required this.failed,
    required this.remaining,
    required this.streak,
    required this.scheduledTotal,
    required this.isCompleted,
  });

  factory _PlanStats.from(Plan plan) {
    final isCompleted = plan.state == PlanState.completed ||
        plan.state == PlanState.stopped;
    return _PlanStats(
      success: plan.completedDayCount(),
      failed: plan.failedDayCount(),
      remaining: plan.remainingScheduledDayCount(),
      streak: plan.currentStreak,
      scheduledTotal: plan.scheduledDayCount,
      isCompleted: isCompleted,
    );
  }

  /// 성공률 계산에 쓰는 분모.
  /// - 종료된 플랜: 전체 예정일 수
  /// - 진행 중: 이미 결과가 나온 날 수 (성공 + 실패)
  int get totalForRate {
    if (isCompleted) return scheduledTotal;
    return success + failed;
  }

  bool get hasVerdict => totalForRate > 0;

  double get successRate {
    if (!hasVerdict) return 0;
    return success / totalForRate;
  }

  int get successRatePercent => (successRate * 100).round();
}
