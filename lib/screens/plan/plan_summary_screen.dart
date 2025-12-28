import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/progress_hint_bar.dart';
import '../../widgets/primary_button.dart';
import '../../routes/app_router.dart';
import '../../l10n/app_localizations.dart';

/// Screen 5: 계획 제안 요약 화면
///
/// "이렇게 제안할 거예요"
class PlanSummaryScreen extends StatelessWidget {
  final String? action;
  final int? frequency;
  final String? description;
  final String? days;

  const PlanSummaryScreen({
    super.key,
    this.action,
    this.frequency,
    this.description,
    this.days,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDays =
        days
            ?.split(',')
            .map((e) => int.tryParse(e))
            .whereType<int>()
            .toList() ??
        [];
    final dayNames = [
      l10n.dayMonday,
      l10n.dayTuesday,
      l10n.dayWednesday,
      l10n.dayThursday,
      l10n.dayFriday,
      l10n.daySaturday,
      l10n.daySunday,
    ];
    final selectedDayNames = selectedDays.map((d) => dayNames[d]).join(', ');

    String getActionTitle() {
      // action은 이제 직접 입력한 텍스트
      if (action != null && action!.isNotEmpty) {
        return action!;
      }
      return l10n.planWhatToPromise;
    }

    String getFrequencyText() {
      switch (frequency) {
        case 2:
          return l10n.planFrequencyLightWithCount;
        case 3:
          return l10n.planFrequencyModerateWithCount;
        case 4:
          return l10n.planFrequencyMoreWithCount;
        default:
          return l10n.planFrequencyModerateWithCount;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.planProposal,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 진행 힌트 바
          ProgressHintBar(
            hint: l10n.planSummaryTitle,
            currentStep: 5,
            totalSteps: 5,
          ),

          // 본문
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 요약 카드
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getActionTitle(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          l10n.planSummaryFrequency,
                          getFrequencyText(),
                        ),
                        if (description != null && description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            l10n.planSummaryDescription,
                            description!,
                          ),
                        ],
                        if (selectedDays.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            l10n.planSummaryDay,
                            selectedDayNames,
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            l10n.planSummaryDay,
                            l10n.planSummaryDayConditional,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.planSummaryInfo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.planSummaryAdjustable,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: SafeArea(
              child: PrimaryButton(
                text: l10n.planSummarySend,
                onPressed: () {
                  // TODO: 계획 제안 생성 및 전송
                  // 성공 시 홈 화면으로 이동
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.planSummarySent),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  context.go(AppRoutes.home);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
