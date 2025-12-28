import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/progress_hint_bar.dart';
import '../../widgets/primary_button.dart';
import '../../routes/app_router.dart';
import '../../l10n/app_localizations.dart';

/// Screen 4: 요일 선택 화면
///
/// "요일은 안 정해도 돼요"
class PlanDaySelectionScreen extends StatefulWidget {
  final String? action;
  final int? frequency;
  final String? description;

  const PlanDaySelectionScreen({
    super.key,
    this.action,
    this.frequency,
    this.description,
  });

  @override
  State<PlanDaySelectionScreen> createState() => _PlanDaySelectionScreenState();
}

class _PlanDaySelectionScreenState extends State<PlanDaySelectionScreen> {
  final Set<int> _selectedDays = {}; // 0=월요일, 6=일요일

  List<String> _getDayNames(AppLocalizations l10n) {
    return [
      l10n.dayMonday,
      l10n.dayTuesday,
      l10n.dayWednesday,
      l10n.dayThursday,
      l10n.dayFriday,
      l10n.daySaturday,
      l10n.daySunday,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            hint: l10n.planPreparing,
            currentStep: 4,
            totalSteps: 5,
          ),

          // 본문
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀
                  Text(
                    l10n.planDayTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.planDaySubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 요일 선택 그리드
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(7, (index) {
                      final isSelected = _selectedDays.contains(index);
                      return _buildDayChip(context, index, isSelected);
                    }),
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
              child: Column(
                children: [
                  // 스킵 버튼 (기본 추천)
                  OutlinedButton(
                    onPressed: () {
                      // 요일 없이 다음 화면으로
                      _navigateToSummary();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      l10n.planDaySkip,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 다음 버튼
                  PrimaryButton(
                    text: l10n.planNext,
                    onPressed: () {
                      _navigateToSummary();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(BuildContext context, int dayIndex, bool isSelected) {
    final l10n = AppLocalizations.of(context)!;
    final dayNames = _getDayNames(l10n);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(dayIndex);
          } else {
            _selectedDays.add(dayIndex);
          }
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            dayNames[dayIndex],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSummary() {
    final selectedDaysList = _selectedDays.toList()..sort();
    context.push(
      '${AppRoutes.planSummary}?action=${Uri.encodeComponent(widget.action ?? '')}&frequency=${widget.frequency ?? 3}&description=${Uri.encodeComponent(widget.description ?? '')}&days=${selectedDaysList.join(',')}',
    );
  }
}
