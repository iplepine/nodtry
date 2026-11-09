import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/plan_goal.dart';

/// The optional D-day goal inputs: preset chips (여행 · 결혼식 · 바디프로필 ·
/// 직접 입력), a short title field and a future-only date picker.
///
/// With [collapsible] (plan creation) it starts as one quiet row, "목표 날짜
/// (선택)", so making a promise stays a one-screen, low-friction flow; the
/// plan-detail sheet shows it open.
///
/// The widget is controlled: [title] / [date] come from the caller, and every
/// change is reported through the callbacks.
class PlanGoalEditor extends StatefulWidget {
  final String title;
  final DateTime? date;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onClear;
  final bool collapsible;
  final bool initiallyExpanded;

  /// "Today" for tests; the device clock otherwise.
  final DateTime? now;

  const PlanGoalEditor({
    super.key,
    required this.title,
    required this.date,
    required this.onTitleChanged,
    required this.onDateChanged,
    required this.onClear,
    this.collapsible = true,
    this.initiallyExpanded = false,
    this.now,
  });

  @override
  State<PlanGoalEditor> createState() => _PlanGoalEditorState();
}

class _PlanGoalEditorState extends State<PlanGoalEditor> {
  late final TextEditingController _titleController;
  final FocusNode _titleFocus = FocusNode();
  late bool _expanded;

  /// 직접 입력 was tapped (the title may still be empty).
  bool _customPicked = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _expanded =
        !widget.collapsible ||
        widget.initiallyExpanded ||
        widget.date != null ||
        widget.title.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant PlanGoalEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != _titleController.text) {
      _titleController.value = TextEditingValue(
        text: widget.title,
        selection: TextSelection.collapsed(offset: widget.title.length),
      );
    }
    // A goal that arrives later (an edited plan loads after the first frame)
    // opens the section.
    final gotGoal =
        oldWidget.date == null &&
        oldWidget.title.isEmpty &&
        (widget.date != null || widget.title.isNotEmpty);
    if (gotGoal && !_expanded) setState(() => _expanded = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  DateTime get _today => planGoalDateOnly(widget.now ?? DateTime.now());

  PlanGoalPreset? _selectedPreset(AppLocalizations l10n) {
    final title = widget.title.trim();
    for (final preset in PlanGoalPreset.values) {
      if (preset.title(l10n) == title) return preset;
    }
    if (_customPicked || title.isNotEmpty) return PlanGoalPreset.custom;
    return null;
  }

  void _pickPreset(AppLocalizations l10n, PlanGoalPreset preset) {
    final title = preset.title(l10n);
    if (title == null) {
      setState(() => _customPicked = true);
      // Keep a typed title; replace a preset's.
      final isPresetTitle = PlanGoalPreset.values.any(
        (p) => p.title(l10n) == widget.title.trim(),
      );
      if (isPresetTitle) widget.onTitleChanged('');
      // Only focus the field: a date picker opened here would take the focus
      // (and the keyboard) away before the user could type a title. The date
      // button and the "needs a date" hint cover the date afterwards.
      _titleFocus.requestFocus();
      return;
    }
    setState(() => _customPicked = false);
    widget.onTitleChanged(title);
    if (widget.date == null) _pickDate();
  }

  Future<void> _pickDate() async {
    final first = _today.add(const Duration(days: 1));
    final last = DateTime(_today.year + 5, _today.month, _today.day);
    var initial = widget.date ?? _today.add(const Duration(days: 30));
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null || !mounted) return;
    widget.onDateChanged(planGoalDateOnly(picked));
  }

  void _clear() {
    setState(() => _customPicked = false);
    _titleController.clear();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.collapsible) _buildToggle(l10n),
        if (_expanded) ...[
          if (widget.collapsible) const SizedBox(height: 8),
          _buildBody(context, l10n),
        ],
      ],
    );
  }

  Widget _buildToggle(AppLocalizations l10n) {
    final summary = planGoalLabel(
      l10n,
      title: widget.title,
      goalDate: widget.date,
      now: _today,
    );
    return InkWell(
      key: const ValueKey('plan-goal-toggle'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                !_expanded && summary != null ? summary : l10n.planGoalToggle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: !_expanded && summary != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    final selected = _selectedPreset(l10n);
    final date = widget.date;
    final hasAnything = date != null || widget.title.trim().isNotEmpty;
    final countdown = planGoalLabel(
      l10n,
      title: null,
      goalDate: date,
      now: _today,
    );
    final dateText = date == null
        ? l10n.planGoalPickDate
        : [
            MaterialLocalizations.of(context).formatMediumDate(date),
            ?countdown,
          ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in PlanGoalPreset.values)
              ChoiceChip(
                key: ValueKey('plan-goal-preset-${preset.name}'),
                label: Text(preset.chipLabel(l10n)),
                selected: selected == preset,
                showCheckmark: false,
                onSelected: (_) => _pickPreset(l10n, preset),
                selectedColor: AppColors.primarySoft,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected == preset
                      ? AppColors.primary
                      : AppColors.divider,
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected == preset
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('plan-goal-title-field'),
          controller: _titleController,
          focusNode: _titleFocus,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            LengthLimitingTextInputFormatter(kPlanGoalTitleMaxLength),
          ],
          onChanged: widget.onTitleChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: l10n.planGoalTitleHint,
            hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
            filled: true,
            fillColor: AppColors.surface,
            border: _border(AppColors.divider, 1),
            enabledBorder: _border(AppColors.divider, 1),
            focusedBorder: _border(AppColors.primary, 2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('plan-goal-date-button'),
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  dateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: date == null
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  side: BorderSide(
                    color: date == null ? AppColors.divider : AppColors.primary,
                  ),
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (hasAnything) ...[
              const SizedBox(width: 4),
              TextButton(
                key: const ValueKey('plan-goal-clear'),
                onPressed: _clear,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: Text(l10n.planGoalRemove),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            date == null && widget.title.trim().isNotEmpty
                ? l10n.planGoalNeedsDate
                : l10n.planGoalHint,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: date == null && widget.title.trim().isNotEmpty
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
