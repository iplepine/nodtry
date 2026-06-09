import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../routes/app_router.dart';
import '../../../../services/notification_service.dart';
import '../../domain/study_plan_template.dart';
// No repository_provider or home_provider needed here if only using the viewModel state

import '../widgets/plan_action_step.dart';
import '../widgets/plan_description_step.dart';
import '../widgets/plan_day_selection_step.dart';

import '../plan_create_state.dart';
import '../viewmodel/plan_create_viewmodel.dart';

/// 통합 계획 생성 화면 (Wizard 방식)
class PlanCreateScreen extends ConsumerStatefulWidget {
  final Plan? planToEdit;
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
  // Page Controller
  final PageController _pageController = PageController();

  // Step 1: 행동
  late TextEditingController _actionController;
  final FocusNode _actionFocus = FocusNode();

  // Step 3: 설명 (선택)
  late TextEditingController _descriptionController;
  final FocusNode _descriptionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if editing
    final plan = widget.planToEdit;
    final item = plan?.items.firstOrNull;

    _actionController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );

    // Init ViewModel directly via Intent or overrides?
    // Dispatch init intent after first build or use microtask
    if (plan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(planCreateViewModelProvider.notifier)
            .dispatch(InitializePlanIntent(plan));

        // 종료된 계획에서 "다시 시작"한 경우 마지막 단계로 이동
        if (widget.startAtLastStep) {
          // step을 마지막(3)까지 진행
          final vm = ref.read(planCreateViewModelProvider.notifier);
          vm.dispatch(const NextStepIntent()); // 1 -> 2
          vm.dispatch(const NextStepIntent()); // 2 -> 3
          _pageController.jumpToPage(2); // 0-indexed
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(planCreateViewModelProvider.notifier)
            .dispatch(const ResetIntent());
      });
    }

    _actionController.addListener(() {
      ref
          .read(planCreateViewModelProvider.notifier)
          .dispatch(UpdateActionIntent(_actionController.text));
    });
    _descriptionController.addListener(() {
      ref
          .read(planCreateViewModelProvider.notifier)
          .dispatch(UpdateDescriptionIntent(_descriptionController.text));
    });
    // ... existing ...

    NotificationService().init();
  }

  @override
  void dispose() {
    // 화면 종료 시 상태 초기화는 더 이상 dispose에서 ref를 사용하여 처리하지 않음
    // 대신 initState에서 진입 시 초기화하도록 변경

    _pageController.dispose();
    _actionController.dispose();
    _descriptionController.dispose();
    _actionFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _nextPage(int currentStep) {
    if (currentStep < 3) {
      if (currentStep == 1 && _actionController.text.trim().isEmpty) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.planTellUsActionFirst),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      ref
          .read(planCreateViewModelProvider.notifier)
          .dispatch(const NextStepIntent());
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _savePlan();
    }
  }

  void _prevPage(int currentStep) {
    if (currentStep > 1) {
      FocusManager.instance.primaryFocus?.unfocus();
      ref
          .read(planCreateViewModelProvider.notifier)
          .dispatch(const PrevStepIntent());
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _savePlan() async {
    try {
      await ref
          .read(planCreateViewModelProvider.notifier)
          .dispatch(const SavePlanIntent());

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.planProposalSaved),
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final message = e is PlanCreateAuthException
            ? l10n.planCreateErrorNoUser
            : l10n.planSaveError(e.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planCreateState =
        ref.watch(planCreateViewModelProvider).value ??
        PlanCreateState(notificationTime: NotificationTime.preset('dinner'));
    final connectedProfiles = ref.watch(connectedProfilesProvider).value ?? [];
    final partnerName = connectedProfiles.firstOrNull?.user.displayName;
    final currentStep = planCreateState.currentStep;
    const totalSteps = 3;

    return PopScope(
      canPop: currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentStep > 1) {
          _prevPage(currentStep);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () {
              if (currentStep > 1) {
                _prevPage(currentStep);
              } else {
                context.pop();
              }
            },
          ),
          titleSpacing: 0,
          title: Text(
            l10n.planStepHeader(currentStep, totalSteps),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: GestureDetector(
                onTap: () {
                  if (currentStep == 1 &&
                      _actionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.planTellUsActionFirst),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  _nextPage(currentStep);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (currentStep == 1 &&
                            _actionController.text.trim().isEmpty)
                        ? AppColors.textDisabled.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentStep == totalSteps ? l10n.planSummarySend : l10n.planNext,
                    style: TextStyle(
                      color:
                          (currentStep == 1 &&
                              _actionController.text.trim().isEmpty)
                          ? AppColors.textDisabled
                          : AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepContainer(
                      child: PlanActionStep(
                        controller: _actionController,
                        focusNode: _actionFocus,
                        categories: planCategoriesFor(l10n),
                        selectedCategoryId: planCreateState.selectedCategoryId,
                        onCategorySelected: (category) {
                          _actionController.clear();
                          _descriptionController.clear();
                          ref
                              .read(planCreateViewModelProvider.notifier)
                              .dispatch(SelectPlanCategoryIntent(category));
                          if (category.id == planCategoryCustom) {
                            _actionFocus.requestFocus();
                          } else {
                            FocusManager.instance.primaryFocus?.unfocus();
                          }
                        },
                        templates: [
                          ...studyPlanTemplatesFor(l10n),
                          ...verifiedRoutinesFor(l10n),
                        ],
                        selectedTemplateId: planCreateState.selectedTemplateId,
                        onTemplateSelected: (template) {
                          _actionController.text = template.action;
                          _actionController.selection = TextSelection.collapsed(
                            offset: _actionController.text.length,
                          );
                          _descriptionController.text = template.description;
                          ref
                              .read(planCreateViewModelProvider.notifier)
                              .dispatch(ApplyStudyTemplateIntent(template));
                        },
                        onActionCleared: () {
                          _actionController.clear();
                          _descriptionController.clear();
                          final customCategory = planCategoriesFor(l10n).firstWhere(
                            (category) => category.id == planCategoryCustom,
                          );
                          ref
                              .read(planCreateViewModelProvider.notifier)
                              .dispatch(
                                SelectPlanCategoryIntent(customCategory),
                              );
                          _actionFocus.requestFocus();
                        },
                      ),
                    ),
                    _buildStepContainer(
                      child: PlanDescriptionStep(
                        controller: _descriptionController,
                        focusNode: _descriptionFocus,
                      ),
                    ),
                    _buildStepContainer(
                      child: PlanDaySelectionStep(
                        selectedDays: planCreateState.selectedDays,
                        onDayToggle: (dayIndex) {
                          ref
                              .read(planCreateViewModelProvider.notifier)
                              .dispatch(ToggleDayIntent(dayIndex));
                        },
                        onDayPresetSelected: (selectedDays) {
                          ref
                              .read(planCreateViewModelProvider.notifier)
                              .dispatch(UpdateSelectedDaysIntent(selectedDays));
                        },
                        notificationTime: planCreateState.notificationTime,
                        onTimeChanged: (newTime) {
                          ref
                              .read(planCreateViewModelProvider.notifier)
                              .dispatch(UpdateNotificationTimeIntent(newTime));
                        },
                        selectedCategoryId: planCreateState.selectedCategoryId,
                        action: planCreateState.action,
                        partnerName: partnerName,
                        hasPartner: connectedProfiles.isNotEmpty,
                        onConnectPartner: () => context.push(AppRoutes.connect),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContainer({required Widget child}) {
    return SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(24.0), child: child),
    );
  }
}
