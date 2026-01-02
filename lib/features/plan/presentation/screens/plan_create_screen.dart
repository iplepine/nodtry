import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../services/notification_service.dart';
// No repository_provider or home_provider needed here if only using the viewModel state

import '../widgets/plan_action_step.dart';
import '../widgets/plan_frequency_step.dart';
import '../widgets/plan_description_step.dart';
import '../widgets/plan_day_selection_step.dart';

import '../plan_create_state.dart';
import '../viewmodel/plan_create_viewmodel.dart';

/// 통합 계획 생성 화면 (Wizard 방식)
class PlanCreateScreen extends ConsumerStatefulWidget {
  const PlanCreateScreen({super.key});

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
    _actionController = TextEditingController();
    _descriptionController = TextEditingController();

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

    NotificationService().init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _actionController.dispose();
    _descriptionController.dispose();
    _actionFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _nextPage(int currentStep) {
    if (currentStep < 4) {
      if (currentStep == 1 && _actionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("어떤 약속을 할지 알려주세요!"),
            duration: Duration(seconds: 1),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("계획 제안이 완료되었습니다.\n상대방과 대화해보세요!"),
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("저장 중 오류가 발생했습니다: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planCreateState =
        ref.watch(planCreateViewModelProvider).value ??
        PlanCreateState(notificationTime: NotificationTime.preset('dinner'));
    final currentStep = planCreateState.currentStep;
    const totalSteps = 4;

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
            "약속 준비 중 · $currentStep/$totalSteps",
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
                      const SnackBar(
                        content: Text("어떤 약속을 할지 알려주세요!"),
                        duration: Duration(seconds: 1),
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
                        ? AppColors.textDisabled.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentStep == totalSteps ? l10n.planSummarySend : "다음",
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
                      ),
                    ),
                    _buildStepContainer(
                      child: PlanFrequencyStep(
                        selectedFrequency: planCreateState.selectedFrequency,
                        onFrequencySelected: (value) {
                          ref
                              .read(planCreateViewModelProvider.notifier)
                              .dispatch(UpdateFrequencyIntent(value));
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
                        notificationTime: planCreateState.notificationTime,
                        onTimeChanged: (newTime) {
                          ref
                              .read(planCreateViewModelProvider.notifier)
                              .dispatch(UpdateNotificationTimeIntent(newTime));
                        },
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
