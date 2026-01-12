import 'package:flutter/material.dart';
import '../../models/plan_model.dart';
import '../../theme/app_colors.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isOwner;

  const PlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    // 단순화를 위해 첫 번째 아이템 정보만 표시 (MVP)
    final item = plan.items.first;
    final time = item.notificationTime;

    // 요일 문자열 변환 (예: 월, 수, 금)
    // TODO: Localization
    final daysString = item.days
        .map((d) {
          const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
          return weekDays[d - 1]; // d is 1-based
        })
        .join(', ');

    final timeString = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '시간 미정';

    // Status Badge Logic
    final statusInfo = _getStatusInfo(plan.state);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                      Row(
                        children: [
                          Text(
                            daysString,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: TextStyle(color: AppColors.textDisabled),
                            ),
                          ),
                          Text(
                            timeString,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right, color: AppColors.textDisabled),
                ],
              ],
            ),

            // Progress Placeholder (Mock Data for Visual)
            // if (plan.state == PlanState.active) ...[
            //   const SizedBox(height: 12),
            //   Divider(height: 1, color: AppColors.divider.withOpacity(0.5)),
            //   const SizedBox(height: 12),
            //   Row(
            //     children: [
            //       Expanded(
            //         child: ClipRRect(
            //           borderRadius: BorderRadius.circular(4),
            //           child: LinearProgressIndicator(
            //             value: 0.6, // Mock Value (3/5)
            //             backgroundColor: AppColors.divider,
            //             valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            //             minHeight: 6,
            //           ),
            //         ),
            //       ),
            //       const SizedBox(width: 12),
            //       Text(
            //         "이번 주 3/5", // Mock Status
            //         style: TextStyle(
            //           color: AppColors.textSecondary,
            //           fontSize: 12,
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ],
            //   ),
            // ]
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(PlanState state) {
    switch (state) {
      case PlanState.active:
        return {
          'text': '진행 중',
          'color': AppColors.primary.withValues(alpha: 0.1),
          'textColor': AppColors.primary,
        };
      case PlanState.draft:
        return {
          'text': '작성 중',
          'color': AppColors.textDisabled.withValues(alpha: 0.2),
          'textColor': AppColors.textSecondary,
        };
      case PlanState.pendingApproval:
        return {
          'text': '수락 대기',
          'color': const Color(0xFFFF9800).withValues(alpha: 0.1), // Orange
          'textColor': const Color(0xFFEF6C00),
        };
      case PlanState.rejected:
        return {
          'text': '거절됨',
          'color': const Color(0xFFF44336).withValues(alpha: 0.1), // Red
          'textColor': const Color(0xFFD32F2F),
        };
      case PlanState.completed:
        return {
          'text': '종료됨',
          'color': AppColors.textSecondary.withValues(alpha: 0.1),
          'textColor': AppColors.textSecondary,
        };
      case PlanState.stopped:
        return {
          'text': '중단됨',
          'color': AppColors.error.withValues(alpha: 0.1),
          'textColor': AppColors.error,
        };
    }
  }
}
