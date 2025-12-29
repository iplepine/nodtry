import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 진행 맥락 힌트 바
///
/// 계획 생성 플로우에서 현재 단계를 표시하는 위젯
class ProgressHintBar extends StatelessWidget {
  final String hint;
  final int currentStep;
  final int totalSteps;

  const ProgressHintBar({
    super.key,
    required this.hint,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$hint · $currentStep/$totalSteps',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // 진행 바
          SizedBox(
            width: 60,
            child: Row(
              children: List.generate(
                totalSteps,
                (index) => Expanded(
                  child: Container(
                    height: 2,
                    margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: index < currentStep
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
