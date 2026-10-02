import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../routes/app_router.dart';
import '../../../../services/notification_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/error_reporter.dart';
import '../../../../utils/korean_particle.dart';
import '../../../connect/application/partner_label_provider.dart';
import '../../../connect/presentation/widgets/invite_share_panel.dart';
import '../../../onboarding/domain/onboarding_gate.dart';
import '../../domain/workout_template.dart';
import '../plan_create_state.dart';
import '../viewmodel/plan_create_viewmodel.dart';
import '../widgets/plan_schedule_pickers.dart';
import '../widgets/workout_tile_grid.dart';

/// Making (or editing) a workout promise on one screen: workout tile → one-line
/// promise → weekdays → deadline → (optional memo) → pinky promise.
class PlanCreateScreen extends ConsumerStatefulWidget {
  /// The plan to edit, or an id-less copy of one to start again from.
  final Plan? planToEdit;

  /// Kept for route compatibility (`?startAtLastStep=true`); the screen has a
  /// single step, so there is nothing to jump to.
  final bool startAtLastStep;

  const PlanCreateScreen({
    super.key,
    this.planToEdit,
    this.startAtLastStep = false,
  });

  @override
  ConsumerState<PlanCreateScreen> createState() => _PlanCreateScreenState();
}

class _PlanCreateScreenState extends ConsumerState<PlanCreateScreen> {
  late final TextEditingController _actionController;
  late final TextEditingController _descriptionController;
  final FocusNode _actionFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  late bool _memoExpanded;

  /// Editing a saved plan (as opposed to creating, or restarting from a copy).
  bool get _isEditing => widget.planToEdit?.id != null;

  PlanCreateViewModel get _viewModel =>
      ref.read(planCreateViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    final plan = widget.planToEdit;
    final item = plan?.items.firstOrNull;

    _actionController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _memoExpanded = (item?.description ?? '').trim().isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (plan != null) {
        _viewModel.dispatch(InitializePlanIntent(plan));
      } else {
        // The provider outlives the screen: start clean, then offer the
        // partner's weekdays as the default.
        _viewModel.dispatch(const ResetIntent());
        unawaited(_viewModel.dispatch(const PrefillPartnerDaysIntent()));
      }
    });

    // Usually done at app start already; idempotent, and never fatal here.
    unawaited(
      NotificationService().init().catchError((Object e) {
        debugPrint('[PlanCreate] notification init skipped: $e');
      }),
    );
  }

  @override
  void dispose() {
    _actionController.dispose();
    _descriptionController.dispose();
    _actionFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _selectWorkout(WorkoutTemplate template) async {
    await _viewModel.dispatch(SelectWorkoutIntent(template));
    if (!mounted) return;
    final action = ref.read(planCreateViewModelProvider).value?.action;
    if (action != null && action != _actionController.text) {
      _actionController.value = TextEditingValue(
        text: action,
        selection: TextSelection.collapsed(offset: action.length),
      );
    }
    if (template.type == WorkoutType.other || action?.trim().isEmpty == true) {
      _actionFocus.requestFocus();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _clearAction() {
    _actionController.clear();
    _viewModel.dispatch(const UpdateActionIntent(''));
    _actionFocus.requestFocus();
  }

  String _missingMessage(AppLocalizations l10n, PlanCreateMissing missing) {
    switch (missing) {
      case PlanCreateMissing.action:
        return l10n.planTellUsActionFirst;
      case PlanCreateMissing.days:
        return l10n.planCreateDaysRequired;
      case PlanCreateMissing.deadline:
        return l10n.planCreateDeadlineRequired;
    }
  }

  void _showMissing(PlanCreateMissing missing) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_missingMessage(l10n, missing)),
        duration: const Duration(seconds: 2),
      ),
    );
    if (missing == PlanCreateMissing.action) _actionFocus.requestFocus();
  }

  Future<void> _save(String partnerName) async {
    final current = ref.read(planCreateViewModelProvider).value;
    if (current == null || current.isSaving) return;
    final missing = current.missingField;
    if (missing != null) {
      _showMissing(missing);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      await _viewModel.dispatch(const SavePlanIntent());
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final saved = ref.read(planCreateViewModelProvider).value?.originalPlan;
      final String message;
      if (_isEditing) {
        message = l10n.planEditSaved;
      } else if (saved?.managerId != null) {
        message = l10n.planSavedWithPartner(partnerName);
      } else {
        message = l10n.planSavedSolo;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      // The spec's invite order: the promise first, then "나 운동 약속
      // 걸었어, 봐줘" — offered once, right after the first solo promise.
      if (!_isEditing && saved?.managerId == null) {
        await _offerInviteAfterFirstPromise();
        if (!mounted) return;
      }
      context.pop();
    } on PlanCreateIncompleteException catch (e) {
      if (mounted) _showMissing(e.missing);
    } catch (e, stack) {
      // The user gets a plain message, so the detail has to go somewhere.
      ErrorReporter.record(e, stack, reason: 'savePlan');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final message = e is PlanCreateAuthException
            ? l10n.planCreateErrorNoUser
            : l10n.planSaveError;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _offerInviteAfterFirstPromise() async {
    final partners = ref.read(connectedProfilesProvider).value;
    if (partners == null || partners.isNotEmpty) return;
    final OnboardingStore store;
    try {
      store = ref.read(onboardingStoreProvider);
    } catch (_) {
      return; // no SharedPreferences (tests)
    }
    if (store.invitePromptedAfterPlan) return;
    await store.markInvitePromptedAfterPlan();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              key: const ValueKey('plan-saved-invite'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.planSavedInviteTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.planSavedInviteBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                InviteSharePanel(
                  surface: 'plan_saved',
                  onShared: () => Navigator.of(sheetContext).pop(),
                ),
                TextButton(
                  key: const ValueKey('plan-saved-invite-later'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text(l10n.connectSuccessLater),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planState =
        ref.watch(planCreateViewModelProvider).value ??
        PlanCreateState(
          notificationTime: NotificationTime.custom(kDefaultDeadlineHour, 0),
        );
    final partner = ref.watch(connectedProfilesProvider).value?.firstOrNull;
    final hasPartner = partner != null;
    // Nickname ?? display name ?? 짝꿍 (spec §3).
    final partnerName = ref.watch(partnerLabelProvider).resolve(l10n);
    final isSaving = planState.isSaving;

    final String ctaLabel;
    if (_isEditing) {
      ctaLabel = l10n.planEditCta;
    } else if (hasPartner) {
      ctaLabel = l10n.planCreateCtaWithPartner(
        partnerName,
        withJosa(partnerName, '이랑/랑'),
      );
    } else {
      ctaLabel = l10n.planCreateCtaSolo;
    }

    return PopScope(
      canPop: !isSaving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: isSaving ? null : () => context.pop(),
          ),
          titleSpacing: 0,
          title: Text(
            _isEditing ? l10n.planEditTitle : l10n.planCreateTitle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: _buildForm(
                    l10n,
                    planState,
                    hasPartner: hasPartner,
                    partnerName: partnerName,
                  ),
                ),
              ),
              _BottomBar(
                summary: l10n.planPreviewMeta(
                  planState.selectedDays.isEmpty
                      ? '-'
                      : planDaysLabel(l10n, planState.selectedDays),
                  planDeadlineLabel(l10n, planState.notificationTime),
                ),
                partnerNotice: hasPartner
                    ? l10n.planCreatePartnerNotice(partnerName)
                    : null,
                ctaLabel: ctaLabel,
                isSaving: isSaving,
                isComplete: planState.canSave,
                onPressed: () => _save(partnerName),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    AppLocalizations l10n,
    PlanCreateState planState, {
    required bool hasPartner,
    required String partnerName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasPartner && !_isEditing
              ? l10n.planCreateHeaderWithPartner(partnerName)
              : l10n.planWhatToPromise,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.planPromiseHint,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        WorkoutTileGrid(
          templates: workoutTemplatesFor(l10n),
          selected: planState.workoutType,
          onSelected: _selectWorkout,
        ),
        const SizedBox(height: 28),
        _SectionLabel(l10n.planMine),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('plan-action-field'),
          controller: _actionController,
          focusNode: _actionFocus,
          textInputAction: TextInputAction.done,
          onChanged: (text) => _viewModel.dispatch(UpdateActionIntent(text)),
          decoration: InputDecoration(
            hintText: l10n.planActionHint,
            hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
            filled: true,
            fillColor: AppColors.surface,
            border: _inputBorder(AppColors.divider, 1),
            enabledBorder: _inputBorder(AppColors.divider, 1),
            focusedBorder: _inputBorder(AppColors.primary, 2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: planState.action.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.planClearAction,
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _clearAction,
                  ),
          ),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        const SizedBox(height: 28),
        _SectionLabel(l10n.planCreateDaysTitle),
        const SizedBox(height: 10),
        PlanWeekdayPicker(
          selectedDays: planState.selectedDays,
          presets: workoutFrequencyPresets(l10n),
          onDayToggle: (index) => _viewModel.dispatch(ToggleDayIntent(index)),
          onPresetSelected: (days) =>
              _viewModel.dispatch(UpdateSelectedDaysIntent(days)),
        ),
        if (planState.selectedDays.isEmpty)
          _Hint(l10n.planCreateDaysRequired, emphasized: true)
        else if (hasPartner && planState.showsPartnerDays)
          _Hint(l10n.planCreateDaysFromPartner(partnerName)),
        const SizedBox(height: 28),
        _SectionLabel(l10n.planCreateDeadlineTitle),
        const SizedBox(height: 10),
        PlanDeadlinePicker(
          value: planState.notificationTime,
          presets: workoutDeadlinePresets(l10n),
          onChanged: (time) =>
              _viewModel.dispatch(UpdateNotificationTimeIntent(time)),
        ),
        _Hint(l10n.planCreateDeadlineHint),
        if (!hasPartner) ...[
          const SizedBox(height: 20),
          _SoloCard(
            text: l10n.planPartnerPreviewWithout,
            actionLabel: l10n.planConnectPartner,
            onAction: () => context.push(AppRoutes.connect),
          ),
        ],
        const SizedBox(height: 24),
        _buildMemo(l10n),
      ],
    );
  }

  Widget _buildMemo(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const ValueKey('plan-memo-toggle'),
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() => _memoExpanded = !_memoExpanded);
            if (_memoExpanded) _descriptionFocus.requestFocus();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.planCreateMemoToggle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  _memoExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_memoExpanded) ...[
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('plan-memo-field'),
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            maxLines: 3,
            onChanged: (text) =>
                _viewModel.dispatch(UpdateDescriptionIntent(text)),
            decoration: InputDecoration(
              hintText: l10n.planDescriptionHint,
              hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
              filled: true,
              fillColor: AppColors.surface,
              border: _inputBorder(AppColors.divider, 1),
              enabledBorder: _inputBorder(AppColors.divider, 1),
              focusedBorder: _inputBorder(AppColors.primary, 2),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
        ],
      ],
    );
  }

  static OutlineInputBorder _inputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final bool emphasized;
  const _Hint(this.text, {this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
          color: emphasized ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SoloCard extends StatelessWidget {
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _SoloCard({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          TextButton.icon(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom area: plan summary, the "your partner will know" line and
/// the pinky-promise button.
class _BottomBar extends StatelessWidget {
  final String summary;
  final String? partnerNotice;
  final String ctaLabel;
  final bool isSaving;
  final bool isComplete;
  final VoidCallback onPressed;

  const _BottomBar({
    required this.summary,
    required this.partnerNotice,
    required this.ctaLabel,
    required this.isSaving,
    required this.isComplete,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final notice = partnerNotice;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            summary,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (notice != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    notice,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('plan-create-cta'),
              // Stays tappable while incomplete so a tap can say what is
              // missing; only a save in flight disables it.
              onPressed: isSaving ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: isComplete
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.45,
                ),
                disabledForegroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                // Merge with the theme so the app font family is kept.
                textStyle:
                    (Theme.of(context).textTheme.labelLarge ??
                            const TextStyle())
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(ctaLabel, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
