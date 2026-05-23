import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plan_model.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isOwner;

  /// 파트너 약속 카드에 응원 액션을 노출할 때 전달.
  /// 페르소나 권고(김민서·박상우): "보는 약속"에서 "참여하는 약속"으로 격상.
  final VoidCallback? onCheer;

  const PlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isOwner = false,
    this.onCheer,
  });

  @override
  Widget build(BuildContext context) {
    // 단순화를 위해 첫 번째 아이템 정보만 표시 (MVP)
    final item = plan.items.first;
    final time = item.notificationTime;

    // 요일 문자열 변환 — 7일=매일, 평일(월화수목금)=평일, 주말(토일)=주말,
    // 그 외는 짧은 요일 join. 풀 텍스트 "Mon, Tue, Wed, Thu, Fri, Sat, Sun"이
    // 한 줄을 다 차지하면 시간/기간 정보가 시각적으로 뒤로 밀린다.
    final l10n = AppLocalizations.of(context)!;
    final weekDays = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];
    final daysSet = item.days.toSet();
    final String daysString;
    if (daysSet.length == 7) {
      daysString = l10n.planDaysEveryday;
    } else if (daysSet.length == 5 &&
        daysSet.containsAll({1, 2, 3, 4, 5})) {
      daysString = l10n.planDaysWeekdays;
    } else if (daysSet.length == 2 && daysSet.containsAll({6, 7})) {
      daysString = l10n.planDaysWeekend;
    } else {
      // 입력 순서가 아니라 월→일 순서로 정렬해서 표기.
      final sorted = item.days.toList()..sort();
      daysString = sorted.map((d) => weekDays[d - 1]).join(', ');
    }

    final isAlarmOn = time != null && time.type != 'none';
    final displayTime = time != null
        ? '${time.targetHour.toString().padLeft(2, '0')}:${time.targetMinute.toString().padLeft(2, '0')}'
        : l10n.planTimeUnset;

    // Status Badge Logic
    final statusInfo = _getStatusInfo(plan.state, l10n);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusInfo['color'] as Color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusInfo['text'] as String,
                              style: TextStyle(
                                color: statusInfo['textColor'] as Color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: Text(
                                  daysString,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '·',
                                style: TextStyle(color: AppColors.textDisabled),
                              ),
                              if (isAlarmOn)
                                Icon(
                                  Icons.notifications_active_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              Text(
                                displayTime,
                                style: TextStyle(
                                  color: isAlarmOn
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: isAlarmOn
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MM.dd').format(plan.startDate)} ~ ${DateFormat('MM.dd').format(plan.endDate)}',
                        style: TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 파트너 약속 + 응원 콜백 있으면 chevron 자리에 응원 버튼.
                // 평시 outline 하트, 평탄한 list 안에서도 살짝 눈에 띄도록 primary tint.
                if (!isOwner && onCheer != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.primary,
                    ),
                    iconSize: 22,
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.usCheerTooltip,
                    onPressed: onCheer,
                  ),
                ] else if (onTap != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right, color: AppColors.textDisabled),
                ],
              ],
            ),

            // 진척 미니바 — 활성 약속만. 페르소나 권고: 카드가 "관리 list"에서
            // "성취 시각화"로 격상되는 핵심.
            if (plan.state == PlanState.active) _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final completed = plan.completedDayCount();
    final failed = plan.failedDayCount();
    final remaining = plan.remainingScheduledDayCount();
    final total = completed + failed + remaining;
    if (total <= 0) return const SizedBox.shrink();
    final ratio = (completed / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.outline.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$completed/$total',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(PlanState state, AppLocalizations l10n) {
    switch (state) {
      case PlanState.active:
        return {
          // 페르소나 합의: outline-처럼 보이는 약한 tint → primarySoft로 filled 톤
          'text': l10n.planStateActive,
          'color': AppColors.primarySoft,
          'textColor': AppColors.primaryPressed,
        };
      case PlanState.draft:
        return {
          'text': l10n.planStateDraft,
          'color': AppColors.textDisabled.withValues(alpha: 0.2),
          'textColor': AppColors.textSecondary,
        };
      case PlanState.pendingApproval:
        return {
          'text': l10n.planStatePending,
          'color': const Color(0xFFFF9800).withValues(alpha: 0.1), // Orange
          'textColor': const Color(0xFFEF6C00),
        };
      case PlanState.rejected:
        return {
          'text': l10n.planStateRejected,
          'color': const Color(0xFFF44336).withValues(alpha: 0.1), // Red
          'textColor': const Color(0xFFD32F2F),
        };
      case PlanState.completed:
        return {
          'text': l10n.planStateCompleted,
          'color': AppColors.textSecondary.withValues(alpha: 0.1),
          'textColor': AppColors.textSecondary,
        };
      case PlanState.stopped:
        return {
          'text': l10n.planStateStopped,
          'color': AppColors.error.withValues(alpha: 0.1),
          'textColor': AppColors.error,
        };
    }
  }
}
