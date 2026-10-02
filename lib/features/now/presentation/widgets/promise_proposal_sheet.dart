import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../models/plan_model.dart';
import '../../../../models/promise_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/promise_money_guard.dart';

/// Curated "if missed" bets: treats and chores between the two of them, never
/// money (spec §4.9).
List<String> promisePenaltyChips(AppLocalizations l10n) => [
  l10n.promisePenaltyChicken,
  l10n.promisePenaltyCoffee,
  l10n.promisePenaltyDishes,
  l10n.promisePenaltyMassage,
  l10n.promisePenaltyMovie,
  l10n.promisePenaltyPickup,
];

/// Curated "if kept" bets.
List<String> promiseRewardChips(AppLocalizations l10n) => [
  l10n.promiseRewardOmakase,
  l10n.promiseRewardDessert,
  l10n.promiseRewardMassage,
  l10n.promiseRewardMovie,
];

@visibleForTesting
class PromiseProposalSheet extends StatefulWidget {
  final Plan plan;
  final DateTime? asOf;

  const PromiseProposalSheet({super.key, required this.plan, this.asOf});

  @override
  State<PromiseProposalSheet> createState() => _PromiseProposalSheetState();
}

class _PromiseProposalSheetState extends State<PromiseProposalSheet> {
  // 못 지키면 leads ("못 지키면 🍗 치킨 쏘기"); 지키면 is optional.
  bool _enableReward = false;
  bool _enablePenalty = true;
  final _rewardDescController = TextEditingController();
  final _penaltyDescController = TextEditingController();
  late int _rewardDays;
  late int _penaltyDays;
  late final DateTime _asOf;

  int get _scheduledDays => widget.plan.scheduledDayCount;
  int get _rewardDaysLimit => widget.plan.rewardTargetDaysLimit(asOf: _asOf);
  int get _penaltyDaysLimit => widget.plan.penaltyTargetDaysLimit(asOf: _asOf);
  int get _durationDays => widget.plan.calendarDurationDays;
  int get _completedDays => widget.plan.completedDayCount(asOf: _asOf);
  int get _failedDays => widget.plan.failedDayCount(asOf: _asOf);
  int get _remainingDays => widget.plan.remainingScheduledDayCount(asOf: _asOf);

  @override
  void initState() {
    super.initState();
    _asOf = widget.asOf ?? DateTime.now();
    _rewardDays = _defaultRewardDays();
    _penaltyDays = _defaultPenaltyDays();
  }

  @override
  void dispose() {
    _rewardDescController.dispose();
    _penaltyDescController.dispose();
    super.dispose();
  }

  bool get _rewardMentionsMoney =>
      _enableReward && mentionsMoney(_rewardDescController.text);
  bool get _penaltyMentionsMoney =>
      _enablePenalty && mentionsMoney(_penaltyDescController.text);

  bool get _isValid {
    if (!_enableReward && !_enablePenalty) return false;
    if (_rewardMentionsMoney || _penaltyMentionsMoney) return false;
    if (_enableReward && _rewardDescController.text.trim().isEmpty) {
      return false;
    }
    if (_enablePenalty && _penaltyDescController.text.trim().isEmpty) {
      return false;
    }
    if (_enableReward && !_isTargetDaysValid(_rewardDays, _rewardDaysLimit)) {
      return false;
    }
    if (_enablePenalty &&
        !_isTargetDaysValid(_penaltyDays, _penaltyDaysLimit)) {
      return false;
    }
    return true;
  }

  bool _isTargetDaysValid(int days, int maxDays) {
    return days >= 1 && days <= maxDays;
  }

  int _clampTargetDays(int days, int maxDays) {
    if (days < 1) return 1;
    if (days > maxDays) return maxDays;
    return days;
  }

  int _defaultRewardDays() {
    final additionalSuccesses = _remainingDays == 0
        ? 0
        : max(1, (_remainingDays * 0.7).ceil());
    final target = _completedDays + additionalSuccesses;
    final baseline = _completedDays == 0 ? min(20, target) : target;
    return _clampTargetDays(baseline, _rewardDaysLimit);
  }

  int _defaultPenaltyDays() {
    if (_failedDays == 0) {
      return _clampTargetDays(min(10, _penaltyDaysLimit), _penaltyDaysLimit);
    }

    final additionalFailures = _remainingDays == 0
        ? 0
        : max(1, (_remainingDays * 0.3).ceil());
    return _clampTargetDays(
      _failedDays + additionalFailures,
      _penaltyDaysLimit,
    );
  }

  void _setRewardDays(int days) {
    setState(() => _rewardDays = _clampTargetDays(days, _rewardDaysLimit));
  }

  void _setPenaltyDays(int days) {
    setState(() => _penaltyDays = _clampTargetDays(days, _penaltyDaysLimit));
  }

  String _durationSummary(AppLocalizations l10n) {
    if (_durationDays == _scheduledDays) {
      return l10n.nowTotalDaysOnly(_durationDays);
    }
    return l10n.nowTotalDaysScheduled(_durationDays, _scheduledDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final bottomInset = keyboardInset > 0
        ? keyboardInset
        : mediaQuery.viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.nowMakePromiseTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.nowMakePromiseSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _durationSummary(l10n),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.nowProgressLine(
                      _completedDays,
                      _failedDays,
                      _remainingDays,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.nowMaxLimitsLine(_rewardDaysLimit, _penaltyDaysLimit),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 못 지키면 (penalty) first, then 지키면 (reward).
            _buildSectionToggle(
              title: l10n.nowPenaltyTitle,
              enabled: _enablePenalty,
              onToggle: (v) => setState(() => _enablePenalty = v),
            ),
            if (_enablePenalty) ...[
              const SizedBox(height: 8),
              _buildChips(
                keyPrefix: 'promise-penalty-chip',
                labels: promisePenaltyChips(l10n),
                controller: _penaltyDescController,
              ),
              const SizedBox(height: 8),
              _buildDescriptionField(
                key: const ValueKey('promise-penalty-field'),
                controller: _penaltyDescController,
                hint: l10n.nowPenaltyHint,
                moneyError: _penaltyMentionsMoney
                    ? l10n.promiseMoneyBlocked
                    : null,
              ),
              _buildDaysPicker(
                label: l10n.nowPenaltyTargetLabel,
                days: _penaltyDays,
                maxDays: _penaltyDaysLimit,
                onChanged: _setPenaltyDays,
              ),
            ],

            const SizedBox(height: 16),

            _buildSectionToggle(
              title: l10n.nowRewardTitle,
              enabled: _enableReward,
              onToggle: (v) => setState(() => _enableReward = v),
            ),
            if (_enableReward) ...[
              const SizedBox(height: 8),
              _buildChips(
                keyPrefix: 'promise-reward-chip',
                labels: promiseRewardChips(l10n),
                controller: _rewardDescController,
              ),
              const SizedBox(height: 8),
              _buildDescriptionField(
                key: const ValueKey('promise-reward-field'),
                controller: _rewardDescController,
                hint: l10n.nowRewardHint,
                moneyError: _rewardMentionsMoney
                    ? l10n.promiseMoneyBlocked
                    : null,
              ),
              _buildDaysPicker(
                label: l10n.nowRewardTargetLabel,
                days: _rewardDays,
                maxDays: _rewardDaysLimit,
                onChanged: _setRewardDays,
              ),
            ],

            const SizedBox(height: 24),

            // 제출 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('promise-submit'),
                onPressed: _isValid
                    ? () {
                        Navigator.pop(context, (
                          reward: _enableReward
                              ? PromiseReward(
                                  description: _rewardDescController.text
                                      .trim(),
                                  targetDays: _rewardDays,
                                )
                              : null,
                          penalty: _enablePenalty
                              ? PromisePenalty(
                                  description: _penaltyDescController.text
                                      .trim(),
                                  targetDays: _penaltyDays,
                                )
                              : null,
                        ));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textPrimary,
                  disabledBackgroundColor: AppColors.disabled,
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.nowProposePromise,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One-tap bets: tapping a chip fills the text (it can still be edited).
  Widget _buildChips({
    required String keyPrefix,
    required List<String> labels,
    required TextEditingController controller,
  }) {
    final current = controller.text.trim();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
            key: ValueKey('$keyPrefix-$i'),
            label: Text(labels[i]),
            selected: current == labels[i],
            showCheckmark: false,
            selectedColor: AppColors.primarySoft,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: current == labels[i]
                  ? AppColors.primary
                  : AppColors.outline.withValues(alpha: 0.6),
            ),
            labelStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: current == labels[i]
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
            onSelected: (_) => setState(() {
              controller.text = labels[i];
              controller.selection = TextSelection.collapsed(
                offset: labels[i].length,
              );
            }),
          ),
      ],
    );
  }

  Widget _buildDescriptionField({
    required Key key,
    required TextEditingController controller,
    required String hint,
    String? moneyError,
  }) {
    return TextField(
      key: key,
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.surface,
        errorText: moneyError,
        errorMaxLines: 3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      maxLength: 100,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildSectionToggle({
    required String title,
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: enabled,
          onChanged: onToggle,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildDaysPicker({
    required String label,
    required int days,
    required int maxDays,
    required ValueChanged<int> onChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Flexible(
          child: Text(
            '$label: ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        IconButton(
          onPressed: days > 1 ? () => onChanged(days - 1) : null,
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n.nowDaysSuffix(days),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: days < maxDays ? () => onChanged(days + 1) : null,
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.nowMaxDaysLabel(maxDays),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
