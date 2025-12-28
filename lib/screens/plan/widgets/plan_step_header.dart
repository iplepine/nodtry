import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class PlanStepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isKeyboardVisible;
  final VoidCallback onNextTap;

  const PlanStepHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isKeyboardVisible,
    required this.onNextTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      color: AppColors.background,
      child: Row(
        children: [
          Text(
            "약속 준비 중 · $currentStep/$totalSteps",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (isKeyboardVisible)
            GestureDetector(
              onTap: onNextTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "다음",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Row(
              children: List.generate(totalSteps, (index) {
                final isActive = index < currentStep;
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: isActive ? 12 : 6,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
