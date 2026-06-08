import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/study_plan_template.dart';

class PlanActionStep extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<PlanCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<PlanCategory> onCategorySelected;
  final List<StudyPlanTemplate> templates;
  final String? selectedTemplateId;
  final ValueChanged<StudyPlanTemplate> onTemplateSelected;
  final VoidCallback onActionCleared;

  const PlanActionStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.templates,
    required this.selectedTemplateId,
    required this.onTemplateSelected,
    required this.onActionCleared,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCategory = categories.firstWhere(
      (category) => category.id == selectedCategoryId,
      orElse: () => categories.first,
    );
    final categoryTemplates = templates
        .where((template) => template.categoryId == selectedCategoryId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planWhatToPromise,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.planPromiseHint,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.planMostlyProcrastinated,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = selectedCategoryId == category.id;
            return ChoiceChip(
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category),
              label: Text(category.label),
              avatar: Icon(
                _iconForCategory(category.id),
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              selectedColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          selectedCategory.description,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        if (categoryTemplates.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l10n.planRecommendedPromises,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryTemplates.map((template) {
              final isSelected = selectedTemplateId == template.id;
              return ChoiceChip(
                selected: isSelected,
                onSelected: (_) => onTemplateSelected(template),
                label: Text(l10n.planTemplatePerWeek(template.label, template.weeklyCount)),
                avatar: Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                selectedColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          l10n.planMine,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: l10n.planActionHint,
            hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.planClearAction,
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onActionCleared,
                  ),
          ),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.planOneLineEnough,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  IconData _iconForCategory(String categoryId) {
    switch (categoryId) {
      case planCategoryStudy:
        return Icons.menu_book_rounded;
      case planCategoryExercise:
        return Icons.fitness_center_rounded;
      case planCategoryVerified:
        return Icons.self_improvement_rounded;
      case planCategoryCustom:
        return Icons.edit_rounded;
      default:
        return Icons.circle_rounded;
    }
  }
}
