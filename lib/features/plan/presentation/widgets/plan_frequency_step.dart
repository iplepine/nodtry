import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class FrequencyOption {
  final int value;
  final String label;
  final String description;
  final bool isDefault;

  FrequencyOption({
    required this.value,
    required this.label,
    required this.description,
    this.isDefault = false,
  });
}

class PlanFrequencyStep extends StatelessWidget {
  final int? selectedFrequency;
  final ValueChanged<int> onFrequencySelected;

  const PlanFrequencyStep({
    super.key,
    required this.selectedFrequency,
    required this.onFrequencySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = [
      FrequencyOption(
        value: 2,
        label: l10n.planFrequencyLight,
        description: l10n.planFrequencyWeekly2,
      ),
      FrequencyOption(
        value: 3,
        label: l10n.planFrequencyModerate,
        description: l10n.planFrequencyWeekly3,
        isDefault: true,
      ),
      FrequencyOption(
        value: 4,
        label: l10n.planFrequencyMore,
        description: l10n.planFrequencyWeekly4,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planFrequencyTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.planFrequencySubtitle,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFrequencyCard(option, l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyCard(FrequencyOption option, AppLocalizations l10n) {
    final isSelected = selectedFrequency == option.value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFrequencySelected(option.value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
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
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primary, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
