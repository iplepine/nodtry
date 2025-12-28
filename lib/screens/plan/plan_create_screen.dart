import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plan_model.dart';
import '../../services/notification_service.dart';

/// 통합 계획 생성 화면
///
/// 모든 단계를 하나의 화면에서 처리
class PlanCreateScreen extends StatefulWidget {
  const PlanCreateScreen({super.key});

  @override
  State<PlanCreateScreen> createState() => _PlanCreateScreenState();
}

class _PlanCreateScreenState extends State<PlanCreateScreen> {
  // Step 1: 행동
  final TextEditingController _actionController = TextEditingController();

  // Step 2: 빈도
  int? _selectedFrequency;

  // Step 3: 설명 (선택)
  final TextEditingController _descriptionController = TextEditingController();

  // Step 4: 요일 (선택)
  final Set<int> _selectedDays = {}; // 0=월요일, 6=일요일

  // Step 5: 알림 시간 (선택 - 기본값: 저녁)
  NotificationTime _notificationTime = NotificationTime.preset('dinner');

  @override
  void initState() {
    super.initState();
    _selectedFrequency = 3; // 기본값: 주 3회

    // 알림 서비스 초기화 및 권한 요청 (여기서 할지, 버튼 클릭 시 할지 고민, 일단 초기화는 해둠)
    NotificationService().init();
  }

  @override
  void dispose() {
    _actionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.planMyPromise,
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: 행동 선택
                    _buildActionSection(l10n),
                    const SizedBox(height: 32),

                    // Step 2: 빈도 선택
                    _buildFrequencySection(l10n),
                    const SizedBox(height: 32),

                    // Step 3: 설명 (선택)
                    _buildDescriptionSection(l10n),
                    const SizedBox(height: 32),

                    // Step 4: 요일 선택 (선택)
                    _buildDaySelectionSection(l10n),
                    const SizedBox(height: 32),

                    // Step 5: 알림 시간 (선택)
                    _buildNotificationSection(l10n),
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
                  top: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: SafeArea(
                child: PrimaryButton(
                  text: l10n.planSummarySend,
                  onPressed: _actionController.text.trim().isNotEmpty
                      ? () async {
                          // TODO: 실제 Repository 저장 로직 구현
                          // 현재는 로그와 스낵바로 확인
                          final planItem = PlanItem(
                            title: _actionController.text,
                            count: 3, // placeholder
                            days: _selectedDays.toList(),
                            notificationTime: _notificationTime,
                          );

                          print("Saving Plan: ${planItem.toMap()}");

                          // 알림 스케줄링 테스트
                          if (_selectedDays.isNotEmpty) {
                            await NotificationService().requestPermissions();
                            await NotificationService().schedulePlanReminder(
                              planId:
                                  DateTime.now().millisecondsSinceEpoch ~/ 1000,
                              title: planItem.title,
                              hour: _notificationTime.hour,
                              minute: _notificationTime.minute,
                              days: planItem.days,
                            );
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "계획이 저장되고 알림이 설정되었습니다 (${_notificationTime.hour}:${_notificationTime.minute})",
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            context.pop();
                          }
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(AppLocalizations l10n) {
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
        const SizedBox(height: 16),
        TextField(
          controller: _actionController,
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
          ),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildFrequencySection(AppLocalizations l10n) {
    final options = [
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

  Widget _buildFrequencyCard(_FrequencyOption option, AppLocalizations l10n) {
    final isSelected = _selectedFrequency == option.value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFrequency = option.value;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
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

  Widget _buildDescriptionSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planDescriptionTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.planDescriptionSubtitle,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.planDescriptionHint,
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
          ),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.planDescriptionOptional,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelectionSection(AppLocalizations l10n) {
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
          l10n.planDaySubtitle,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final isSelected = _selectedDays.contains(index);
            return _buildDayChip(
              context,
              index,
              dayNames[index],
              isSelected,
              l10n,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.planDaySkip,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDayChip(
    BuildContext context,
    int dayIndex,
    String dayName,
    bool isSelected,
    AppLocalizations l10n,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedDays.remove(dayIndex);
            } else {
              _selectedDays.add(dayIndex);
            }
          });
        },
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

  Widget _buildNotificationSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "알림 시간 (선택)", // TODO: l10n
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "제 시간에 못 해도 괜찮아요. 오늘 안에만 하면 돼요.", // Warm copy
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildNotificationChip(l10n, 'morning', "아침"),
              const SizedBox(width: 8),
              _buildNotificationChip(l10n, 'lunch', "점심"),
              const SizedBox(width: 8),
              _buildNotificationChip(l10n, 'dinner', "저녁"),
              const SizedBox(width: 8),
              _buildNotificationChip(l10n, 'bedtime', "자기 전"),
              const SizedBox(width: 8),
              _buildCustomTimeChip(context, l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationChip(
    AppLocalizations l10n,
    String value,
    String label,
  ) {
    final isSelected =
        _notificationTime.type == 'preset' && _notificationTime.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _notificationTime = NotificationTime.preset(value);
          });
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
    );
  }

  Widget _buildCustomTimeChip(BuildContext context, AppLocalizations l10n) {
    final isCustom = _notificationTime.type == 'custom';
    final label = isCustom
        ? "${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}"
        : "직접 설정";

    return ChoiceChip(
      label: Text(label),
      selected: isCustom,
      onSelected: (selected) async {
        if (selected) {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: _notificationTime.hour,
              minute: _notificationTime.minute,
            ),
          );
          if (picked != null) {
            setState(() {
              _notificationTime = NotificationTime.custom(
                picked.hour,
                picked.minute,
              );
            });
          }
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isCustom ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isCustom ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: isCustom ? AppColors.primary : AppColors.divider),
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
