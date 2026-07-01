import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../domain/study_plan_template.dart';
import 'notification_setting_editor.dart';

class PlanDaySelectionStep extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onDayToggle;
  final ValueChanged<Set<int>> onDayPresetSelected;
  final NotificationTime notificationTime;
  final ValueChanged<NotificationTime> onTimeChanged;
  final String selectedCategoryId;
  final String action;
  final String? partnerName;
  final bool hasPartner;
  final VoidCallback? onConnectPartner;

  const PlanDaySelectionStep({
    super.key,
    required this.selectedDays,
    required this.onDayToggle,
    required this.onDayPresetSelected,
    required this.notificationTime,
    required this.onTimeChanged,
    required this.selectedCategoryId,
    required this.action,
    this.partnerName,
    this.hasPartner = false,
    this.onConnectPartner,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final dayNames = [
      l10n.dayMonday,
      l10n.dayTuesday,
      l10n.dayWednesday,
      l10n.dayThursday,
      l10n.dayFriday,
      l10n.daySaturday,
      l10n.daySunday,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planDayTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedDays.isEmpty
              ? l10n.planNoDayMeansDaily
              : l10n.planDaySubtitle,
          style: TextStyle(
            fontSize: 14,
            color: selectedDays.isEmpty
                ? AppColors.primary
                : AppColors.textSecondary,
            fontWeight: selectedDays.isEmpty
                ? FontWeight.w500
                : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 16),
        _buildPresetChips(context),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final isSelected = selectedDays.contains(index);
            return _buildDayChip(context, index, dayNames[index], isSelected);
          }),
        ),
        const SizedBox(height: 32),

        NotificationSettingEditor(
          notificationTime: notificationTime,
          onTimeChanged: onTimeChanged,
        ),
        const SizedBox(height: 24),
        _PartnerPreviewCard(
          action: action,
          selectedDays: selectedDays,
          notificationTime: notificationTime,
          partnerName: partnerName,
          hasPartner: hasPartner,
          onConnectPartner: onConnectPartner,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPresetChips(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final presets = dayPresetsForCategory(l10n, selectedCategoryId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planRecommendedFrequency,
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
          children: presets.map((preset) {
            final isSelected =
                selectedDays.length == preset.selectedDayIndexes.length &&
                selectedDays.containsAll(preset.selectedDayIndexes);
            return ChoiceChip(
              selected: isSelected,
              onSelected: (_) => onDayPresetSelected(preset.selectedDayIndexes),
              label: Text(preset.label),
              tooltip: preset.description,
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
    );
  }

  Widget _buildDayChip(
    BuildContext context,
    int dayIndex,
    String dayName,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDayToggle(dayIndex),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            dayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PartnerPreviewCard extends StatelessWidget {
  final String action;
  final Set<int> selectedDays;
  final NotificationTime notificationTime;
  final String? partnerName;
  final bool hasPartner;
  final VoidCallback? onConnectPartner;

  const _PartnerPreviewCard({
    required this.action,
    required this.selectedDays,
    required this.notificationTime,
    this.partnerName,
    required this.hasPartner,
    this.onConnectPartner,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final targetName = partnerName?.trim().isNotEmpty == true
        ? partnerName!.trim()
        : l10n.planPartnerFallback;
    final promise = action.trim().isEmpty ? l10n.planActionFallback : action.trim();
    final previewText = hasPartner
        ? l10n.planPartnerPreviewWith(targetName, promise)
        : l10n.planPartnerPreviewWithout;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.planPartnerPreviewLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            previewText,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.planPreviewMeta(_daysLabel(l10n, selectedDays), _timeLabel(l10n, notificationTime)),
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (!hasPartner && onConnectPartner != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onConnectPartner,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: Text(l10n.planConnectPartner),
            ),
          ],
        ],
      ),
    );
  }

  static String _daysLabel(AppLocalizations l10n, Set<int> selectedDays) {
    if (selectedDays.isEmpty || selectedDays.length == 7) {
      return l10n.planDayEveryDay;
    }
    if (selectedDays.length == 5 && selectedDays.containsAll({0, 1, 2, 3, 4})) {
      return l10n.planDayWeekdays;
    }
    return l10n.planDayCountFormat(selectedDays.length);
  }

  static String _timeLabel(AppLocalizations l10n, NotificationTime notificationTime) {
    if (notificationTime.isHourly) {
      return l10n.planTimeHourlyRange(
        notificationTime.startHour,
        notificationTime.endHour,
        notificationTime.intervalHours,
      );
    }
    final targetTotal =
        notificationTime.hour * 60 +
        notificationTime.minute +
        notificationTime.alertOffset;
    final normalized = targetTotal % 1440;
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    final period = hour < 12 ? l10n.planTimeAM : l10n.planTimePM;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    if (minute == 0) {
      return l10n.planTimeFormatNoMinute(period, displayHour);
    }
    final minuteText = minute.toString().padLeft(2, '0');
    return l10n.planTimeFormatWithMinute(period, displayHour, minuteText);
  }
}
