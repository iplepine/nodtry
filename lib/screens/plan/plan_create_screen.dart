import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plan_model.dart';
import '../../services/notification_service.dart';

import 'widgets/plan_action_step.dart';
import 'widgets/plan_frequency_step.dart';
import 'widgets/plan_description_step.dart';
import 'widgets/plan_day_selection_step.dart';
// import 'widgets/plan_notification_step.dart'; // Merged into Day Selection step

/// 통합 계획 생성 화면 (Wizard 방식)
///
/// 5단계의 PageView로 구성되어 순차적으로 진행
class PlanCreateScreen extends StatefulWidget {
  const PlanCreateScreen({super.key});

  @override
  State<PlanCreateScreen> createState() => _PlanCreateScreenState();
}

class _PlanCreateScreenState extends State<PlanCreateScreen> {
  // Page Controller
  final PageController _pageController = PageController();
  int _currentStep = 1;
  static const int _totalSteps = 4; // Reduced from 5 to 4

  // Step 1: 행동
  final TextEditingController _actionController = TextEditingController();
  final FocusNode _actionFocus = FocusNode();

  // Step 2: 빈도
  int? _selectedFrequency;

  // Step 3: 설명 (선택)
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocus = FocusNode();

  // Step 4: 요일 (선택)
  final Set<int> _selectedDays = {}; // 0=월요일, 6=일요일

  // Step 5: 알림 시간 (선택 - 기본값: 저녁)
  NotificationTime _notificationTime = NotificationTime.preset('dinner');

  @override
  void initState() {
    super.initState();
    _selectedFrequency = 3; // 기본값: 주 3회

    // 알림 서비스 초기화
    NotificationService().init();

    // 입력 상태 변경 감지하여 UI 업데이트 (버튼 활성화/비활성화)
    _actionController.addListener(_onActionChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _actionController.removeListener(_onActionChanged);
    _actionController.dispose();
    _descriptionController.dispose();
    _actionFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _onActionChanged() {
    setState(() {});
  }

  void _nextPage() {
    if (_currentStep < _totalSteps) {
      // Validation for Step 1
      if (_currentStep == 1 && _actionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("어떤 약속을 할지 알려주세요!"), // Simple validation message
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      // Focus Handling
      FocusManager.instance.primaryFocus?.unfocus();

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _savePlan();
    }
  }

  void _prevPage() {
    if (_currentStep > 1) {
      FocusManager.instance.primaryFocus?.unfocus();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _savePlan() async {
    // Final Validation just in case
    if (_actionController.text.trim().isEmpty) return;

    final planItem = PlanItem(
      title: _actionController.text,
      count: _selectedFrequency ?? 3,
      days: _selectedDays.toList(),
      notificationTime: _notificationTime,
    );

    // Check permissions and schedule if needed
    if (_selectedDays.isNotEmpty || _notificationTime.type != 'none') {
      // Note: Requesting permissions at the end might be better UX than interruption
      await NotificationService().requestPermissions();
      await NotificationService().schedulePlanReminder(
        planId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: planItem.title,
        hour: _notificationTime.hour,
        minute: _notificationTime.minute,
        days: planItem.days,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("계획 제안이 완료되었습니다.\n상대방과 대화해보세요!"),
          duration: Duration(seconds: 2),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // MediaQuery를 사용하여 안전하게 키보드 높이 감지
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 1) {
          _prevPage();
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
              if (_currentStep > 1) {
                _prevPage();
              } else {
                context.pop();
              }
            },
          ),
          titleSpacing: 0,
          title: Text(
            "약속 준비 중 · $_currentStep/$_totalSteps",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: isKeyboardVisible
                  ? GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentStep == _totalSteps
                              ? l10n.planSummarySend
                              : "다음",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: List.generate(_totalSteps, (index) {
                        final isActive = index < _currentStep;
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: isActive ? 12 : 6,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Content (PageView)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable swipe to enforce flow
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index + 1;
                    });
                  },
                  children: [
                    // Step 1: Action (행동)
                    _buildStepContainer(
                      child: PlanActionStep(
                        controller: _actionController,
                        focusNode: _actionFocus,
                      ),
                    ),

                    // Step 2: Frequency (빈도)
                    _buildStepContainer(
                      child: PlanFrequencyStep(
                        selectedFrequency: _selectedFrequency,
                        onFrequencySelected: (value) {
                          setState(() {
                            _selectedFrequency = value;
                          });
                        },
                      ),
                    ),

                    // Step 3: Description (설명)
                    _buildStepContainer(
                      child: PlanDescriptionStep(
                        controller: _descriptionController,
                        focusNode: _descriptionFocus,
                      ),
                    ),

                    // Step 4: Days & Notification (요일 + 알림)
                    _buildStepContainer(
                      child: PlanDaySelectionStep(
                        selectedDays: _selectedDays,
                        onDayToggle: (dayIndex) {
                          setState(() {
                            if (_selectedDays.contains(dayIndex)) {
                              _selectedDays.remove(dayIndex);
                            } else {
                              _selectedDays.add(dayIndex);
                            }
                          });
                        },
                        notificationTime: _notificationTime,
                        onTimeChanged: (newTime) {
                          setState(() {
                            _notificationTime = newTime;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Button (Visible only when keyboard is hidden to avoid crowding)
              if (!isKeyboardVisible) _buildBottomBar(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContainer({required Widget child}) {
    // Padded container for consistency
    return SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(24.0), child: child),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    String buttonText = "다음";
    if (_currentStep == _totalSteps) {
      buttonText = l10n.planSummarySend; // "이렇게 제안할게요"
    }

    bool isButtonEnabled = true;
    if (_currentStep == 1 && _actionController.text.trim().isEmpty) {
      isButtonEnabled = false;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1.0)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.textDisabled.withValues(
                alpha: 0.3,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: isButtonEnabled ? _nextPage : null,
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
