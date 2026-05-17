import 'package:flutter/material.dart';

import '../../../../models/plan_model.dart';
import '../../../../models/promise_model.dart';
import '../../../../theme/app_colors.dart';

/// 진행 중인 약속의 보상/벌칙을 nowAction 카드 하단에 한 줄로 노출.
/// 우선순위는 "결정에 영향 미치는 정도" 기준: 임박한 벌칙 > 임박한 보상 > 안전권.
/// 탭하면 풀 조건 + 진행률 바텀시트.
class ActivePromiseChip extends StatelessWidget {
  final Plan plan;

  const ActivePromiseChip({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final promise = plan.promise;
    if (promise == null || promise.status != PromiseStatus.active) {
      return const SizedBox.shrink();
    }
    final summary = _summarize(plan, promise);
    if (summary == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () => _showDetailSheet(context, plan, promise),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: summary.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: summary.border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                summary.text,
                style: TextStyle(
                  color: summary.foreground,
                  fontWeight:
                      summary.emphasis ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: summary.foreground.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary {
  final String text;
  final Color background;
  final Color border;
  final Color foreground;
  final bool emphasis;

  const _Summary({
    required this.text,
    required this.background,
    required this.border,
    required this.foreground,
    required this.emphasis,
  });
}

_Summary? _summarize(Plan plan, Promise promise) {
  final reward = promise.reward;
  final penalty = promise.penalty;
  if (reward == null && penalty == null) return null;

  final success = plan.completedDayCount();
  final remaining = plan.remainingScheduledDayCount();

  // 보상까지 더 필요한 성공일 (0 = 달성, >0 = 더 필요)
  int? rewardNeeded;
  if (reward != null) {
    rewardNeeded = reward.targetDays - success;
    if (rewardNeeded < 0) rewardNeeded = 0;
  }

  // 벌칙 회피 여유 (= 더 실패해도 되는 횟수)
  // 벌칙 발동 조건: 최종 성공일 < penalty.targetDays
  // 최종 가능 성공일 = success + remaining
  // buffer = (success + remaining) - penalty.targetDays
  // buffer >= 0 → 안전, < 0 → 이미 확정
  int? failureBuffer;
  if (penalty != null) {
    failureBuffer = (success + remaining) - penalty.targetDays;
  }

  // ===== 우선순위 =====
  // 1) 이미 벌칙 확정
  if (failureBuffer != null && failureBuffer < 0) {
    return _penaltyTriggered(penalty!);
  }

  // 2) 벌칙 임박 (≤1번 여유)
  if (failureBuffer != null && failureBuffer <= 1) {
    return _penaltyImminent(penalty!, failureBuffer);
  }

  // 3) 보상 이미 달성
  if (rewardNeeded != null && rewardNeeded == 0) {
    return _rewardAchieved(reward!);
  }

  // 4) 보상 임박 (≤2일)
  if (rewardNeeded != null && rewardNeeded <= 2) {
    return _rewardImminent(reward!, rewardNeeded);
  }

  // 5) 양쪽 안전권 — 정보성 한 줄
  return _safe(reward, rewardNeeded, penalty, failureBuffer);
}

_Summary _penaltyTriggered(PromisePenalty penalty) {
  return _Summary(
    text: '⚡ 벌칙 발동 확정 — ${penalty.description}',
    background: const Color(0xFFFFF1E6),
    border: const Color(0xFFFF8A3D),
    foreground: const Color(0xFFB54708),
    emphasis: true,
  );
}

_Summary _penaltyImminent(PromisePenalty penalty, int buffer) {
  final count = buffer == 0 ? '한 번' : '$buffer번';
  return _Summary(
    text: '⚡ $count만 더 실패하면 벌칙 — ${penalty.description}',
    background: const Color(0xFFFFF1E6),
    border: const Color(0xFFFF8A3D),
    foreground: const Color(0xFFB54708),
    emphasis: true,
  );
}

_Summary _rewardAchieved(PromiseReward reward) {
  return _Summary(
    text: '🏆 보상 달성! — ${reward.description}',
    background: AppColors.primary.withValues(alpha: 0.12),
    border: AppColors.primary,
    foreground: AppColors.primary,
    emphasis: true,
  );
}

_Summary _rewardImminent(PromiseReward reward, int needed) {
  return _Summary(
    text: '🏆 보상까지 $needed일 더 성공하면 — ${reward.description}',
    background: AppColors.primary.withValues(alpha: 0.12),
    border: AppColors.primary,
    foreground: AppColors.primary,
    emphasis: true,
  );
}

_Summary _safe(
  PromiseReward? reward,
  int? rewardNeeded,
  PromisePenalty? penalty,
  int? failureBuffer,
) {
  String text;
  if (rewardNeeded != null && failureBuffer != null) {
    text = '🏆 보상까지 $rewardNeeded일 · ⚡ 벌칙까지 $failureBuffer번 여유';
  } else if (rewardNeeded != null) {
    text = '🏆 보상까지 $rewardNeeded일 — ${reward!.description}';
  } else if (failureBuffer != null) {
    text = '⚡ 벌칙까지 $failureBuffer번 여유 — ${penalty!.description}';
  } else {
    text = '';
  }
  return _Summary(
    text: text,
    background: AppColors.surface.withValues(alpha: 0.6),
    border: AppColors.outline.withValues(alpha: 0.4),
    foreground: AppColors.textSecondary,
    emphasis: false,
  );
}

// =====================================================================
// 풀 조건 바텀시트
// =====================================================================

void _showDetailSheet(BuildContext context, Plan plan, Promise promise) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PromiseDetailSheet(plan: plan, promise: promise),
  );
}

class _PromiseDetailSheet extends StatelessWidget {
  final Plan plan;
  final Promise promise;

  const _PromiseDetailSheet({required this.plan, required this.promise});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemNavInset = mediaQuery.viewPadding.bottom;
    final success = plan.completedDayCount();
    final failed = plan.failedDayCount();
    final remaining = plan.remainingScheduledDayCount();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + systemNavInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '약속 조건',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '플랜 종료 시 정산돼요. 현재 성공 $success일 · 실패 $failed일 · 남은 예정 $remaining일.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          if (promise.reward != null)
            _RewardOrPenaltyBlock(
              emoji: '🏆',
              title: '보상',
              description: promise.reward!.description,
              targetText:
                  '${promise.reward!.targetDays}일 성공하면 달성 — 지금 $success일',
              progress: (success / promise.reward!.targetDays).clamp(0.0, 1.0),
              progressColor: AppColors.primary,
            ),
          if (promise.reward != null && promise.penalty != null)
            const SizedBox(height: 16),
          if (promise.penalty != null)
            _RewardOrPenaltyBlock(
              emoji: '⚡',
              title: '벌칙',
              description: promise.penalty!.description,
              targetText: _penaltyDescription(
                penalty: promise.penalty!,
                success: success,
                remaining: remaining,
              ),
              progress: (success / promise.penalty!.targetDays).clamp(0.0, 1.0),
              progressColor: const Color(0xFFFF8A3D),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('닫기'),
            ),
          ),
        ],
      ),
    );
  }
}

String _penaltyDescription({
  required PromisePenalty penalty,
  required int success,
  required int remaining,
}) {
  final maxPossible = success + remaining;
  final buffer = maxPossible - penalty.targetDays;
  if (buffer < 0) {
    return '${penalty.targetDays}일 성공이 필요한데 더 이상 도달할 수 없어요 — 벌칙 발동 확정';
  }
  if (buffer == 0) {
    return '${penalty.targetDays}일 성공 미만 시 발동 — 한 번도 더 실패할 수 없음';
  }
  return '${penalty.targetDays}일 성공 미만 시 발동 — $buffer번 더 실패해도 안전';
}

class _RewardOrPenaltyBlock extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String targetText;
  final double progress;
  final Color progressColor;

  const _RewardOrPenaltyBlock({
    required this.emoji,
    required this.title,
    required this.description,
    required this.targetText,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surface.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            targetText,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
