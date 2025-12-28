import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/progress_hint_bar.dart';
import '../../widgets/primary_button.dart';
import '../../routes/app_router.dart';
import '../../l10n/app_localizations.dart';

/// Screen 2: 반복 빈도 설정 화면
/// 
/// "이 정도면 괜찮을지 정하는 중"
class PlanFrequencyScreen extends StatefulWidget {
  final String? action;

  const PlanFrequencyScreen({
    super.key,
    this.action,
  });

  @override
  State<PlanFrequencyScreen> createState() => _PlanFrequencyScreenState();
}

class _PlanFrequencyScreenState extends State<PlanFrequencyScreen> {
  int? _selectedFrequency; // 2, 3, 4 (주 N회)

  List<_FrequencyOption> _buildFrequencyOptions(AppLocalizations l10n) {
    return [
      _FrequencyOption(
        value: 2,
        label: l10n.planFrequencyLight,
        description: l10n.planFrequencyWeekly2,
      ),
      _FrequencyOption(
        value: 3,
        label: l10n.planFrequencyModerate,
        description: l10n.planFrequencyWeekly3,
        isDefault: true,
      ),
      _FrequencyOption(
        value: 4,
        label: l10n.planFrequencyMore,
        description: l10n.planFrequencyWeekly4,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    // 기본값 설정
    _selectedFrequency = 3;
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
            currentStep: 2,
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
                    l10n.planFrequencyTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.planFrequencySubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 빈도 선택 카드들
                  ..._buildFrequencyOptions(l10n).map((option) => _buildFrequencyCard(option)),
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
                top: BorderSide(
                  color: AppColors.divider,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: PrimaryButton(
                text: l10n.planNext,
                onPressed: _selectedFrequency != null
                    ? () {
                        // 다음 화면으로 이동 (설명 화면)
                        context.push(
                          '${AppRoutes.planDescription}?action=${Uri.encodeComponent(widget.action ?? '')}&frequency=$_selectedFrequency',
                        );
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyCard(_FrequencyOption option) {
    final isSelected = _selectedFrequency == option.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFrequency = option.value;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FrequencyOption {
  final int value;
  final String label;
  final String description;
  final bool isDefault;

  _FrequencyOption({
    required this.value,
    required this.label,
    required this.description,
    this.isDefault = false,
  });
}

