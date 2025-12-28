import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../routes/app_router.dart';

/// Plan Rail 상태
enum PlanRailState {
  noPlan, // 약속 없음
  activePlan, // 약속 있음
  pendingApproval, // 제안/승인 대기
}

/// Plan Rail - 계획 진입점 고정 바
/// 
/// '지금' 탭에서 항상 같은 위치에 표시되는 계획 진입점
class PlanRail extends StatelessWidget {
  final PlanRailState state;
  final String? planSummary; // "운동 · 주 3회 · 월/수/금" 등
  final VoidCallback? onNewPlanTap;

  const PlanRail({
    super.key,
    required this.state,
    this.planSummary,
    this.onNewPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 좌측: 요약
          Expanded(
            child: _buildSummary(context),
          ),
          const SizedBox(width: 12),
          // 우측: 새 약속 버튼
          _buildActionChip(context),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    switch (state) {
      case PlanRailState.noPlan:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이번 달 약속이 아직 없어요',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '한 가지 약속만 정해볼까요?',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      case PlanRailState.activePlan:
        return Text(
          planSummary ?? '이번 달 약속',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        );
      case PlanRailState.pendingApproval:
        return Text(
          '새 약속을 제안했어요 · 상대가 보고 있어요',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        );
    }
  }

  Widget _buildActionChip(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleNewPlanTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '새 약속',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (state) {
      case PlanRailState.noPlan:
        return AppColors.surface; // Opacity 100%
      case PlanRailState.activePlan:
        return AppColors.surface.withOpacity(0.7); // Opacity 70~80%
      case PlanRailState.pendingApproval:
        return AppColors.surface.withOpacity(0.7);
    }
  }

  void _handleNewPlanTap(BuildContext context) {
    if (state == PlanRailState.pendingApproval) {
      // 제안 대기 중일 때는 확인 모달 표시
      _showPendingApprovalDialog(context);
    } else {
      // 바로 계획 생성 플로우 진입
      if (onNewPlanTap != null) {
        onNewPlanTap!();
      } else {
        context.push(AppRoutes.planActionSelection);
      }
    }
  }

  void _showPendingApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '이미 제안한 약속이 있어요',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '또 제안할까요?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '이번 건 기다릴래요',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onNewPlanTap != null) {
                onNewPlanTap!();
              } else {
                context.push(AppRoutes.planActionSelection);
              }
            },
            child: Text(
              '새로 제안할래요',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

