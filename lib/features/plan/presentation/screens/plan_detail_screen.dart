import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/plan_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/time_formatter.dart';
import '../widgets/notification_setting_editor.dart';
// import '../../../../features/plan/domain/usecases/setting_alarm_use_case.dart'; // Unused
import '../../../../models/history_item.dart';
import 'package:nod_try/providers/repository_provider.dart';

class PlanDetailScreen extends ConsumerWidget {
  final Plan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // l10n unused for now
    final item = plan.items.first;
    final time = item.notificationTime;
    final days = item.days;

    final currentUser = ref.watch(authStateChangesProvider).value;
    final isMine = currentUser?.uid == plan.userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isMine) ...[
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.textPrimary),
              onPressed: () => _showRestartPlanDialog(context, ref),
            ),
            IconButton(
              icon: Icon(Icons.stop_circle_outlined, color: AppColors.error),
              onPressed: () => _showStopCurrentPlanDialog(context, ref),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              if (item.description != null && item.description!.isNotEmpty) ...[
                Text(
                  item.description!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Divider
              Divider(color: AppColors.textDisabled.withOpacity(0.2)),
              const SizedBox(height: 32),

              // Info Rows
              _buildInfoRow(
                context,
                icon: Icons.calendar_today,
                label: _getDaysText(days),
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                context,
                icon: Icons.access_time,
                label: _getTimeText(time),
                trailing: isMine
                    ? Icon(Icons.edit, size: 16, color: AppColors.textSecondary)
                    : null,
                onTap: isMine
                    ? () => _showEditNotificationDialog(context, ref)
                    : null,
              ),
              const SizedBox(height: 48),

              // History Header
              Text(
                '실천 기록',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // History List
              if (plan.id != null)
                Expanded(
                  child: StreamBuilder<List<HistoryItem>>(
                    stream: ref
                        .watch(getPlanHistoryUseCaseProvider)
                        .execute(plan.id!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        debugPrint('History Stream Error: ${snapshot.error}');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '기록을 불러오지 못했어요.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            '아직 기록이 없어요.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (c, i) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildHistoryItem(context, item);
                        },
                      );
                    },
                  ),
                )
              else
                Center(
                  child: Text(
                    '저장된 계획이 아닙니다.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, HistoryItem item) {
    IconData icon = Icons.help_outline;
    Color color = AppColors.textDisabled;

    switch (item.status) {
      case HistoryStatus.done:
      case HistoryStatus.actuallyDone:
      case HistoryStatus.verified:
        icon = Icons.check_circle;
        color = AppColors.primary;
        break;
      case HistoryStatus.skipped:
        icon = Icons.cancel_outlined;
        color = AppColors.textDisabled;
        break;
      case HistoryStatus.rested:
        icon = Icons.hotel;
        color = AppColors.secondary;
        break;
    }

    // Format Date: e.g. 1/12 (Mon)
    // Simple util or manual
    final dateStr = '${item.date.month}/${item.date.day}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        _getHistoryStatusText(item.status),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: item.note != null && item.note!.isNotEmpty
          ? Text(item.note!, style: TextStyle(color: AppColors.textSecondary))
          : null,
      trailing: Text(
        dateStr,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  String _getHistoryStatusText(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.done:
      case HistoryStatus.actuallyDone:
      case HistoryStatus.verified:
        return '완료';
      case HistoryStatus.skipped:
        return '건너뜀';
      case HistoryStatus.rested:
        return '휴식';
    }
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  String _getDaysText(List<int> days) {
    // 1=Mon, 7=Sun
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    if (days.length == 7) return '매일';

    // Sort just in case
    final sortedDays = List<int>.from(days)..sort();
    return sortedDays.map((d) => weekDays[d - 1]).join(', ');
  }

  String _getTimeText(NotificationTime? time) {
    if (time == null || time.type == 'none') {
      // Show target time (which is the goal time) even if alarm is off
      // But if time is null, just show Undecided.
      // Wait, current logic: if type == 'none', return '시간 미정'?
      // The User wants "Time is set, Notification is optional".
      // So if type == 'none' BUT time is set (hour/minute non zero or we trust hour/min), we should show time.
      // NotificationTime.none() has 0:0.
      // If I update logic to preserve time even if type='none', I should display it.
      if (time != null && (time.hour != 0 || time.minute != 0)) {
        // We have a time, but alarm is off.
        // Display time.
        final dt = DateTime(2020, 1, 1, time.targetHour, time.targetMinute);
        return TimeFormatter.formatExactTime(dt);
      }
      return '시간 미정';
    }
    // Alarm ON
    final dt = DateTime(2020, 1, 1, time.targetHour, time.targetMinute);
    return TimeFormatter.formatExactTime(dt);
  }

  void _showEditNotificationDialog(BuildContext context, WidgetRef ref) {
    final notificationTime =
        plan.items.first.notificationTime ?? NotificationTime.none();
    // We need state for the editor.
    NotificationTime tempTime = notificationTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Editor
                    // Import needed? It's in the project already.
                    // I will add import at top of file.
                    // Assuming widget is imported.
                    // NotificationSettingEditor is a widget I created.
                    // I will need to replace the imports in this file too.
                    NotificationSettingEditor(
                      notificationTime: tempTime,
                      onTimeChanged: (newTime) {
                        setState(() {
                          tempTime = newTime;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (plan.id == null) return;

                          try {
                            // 1. Update Plan
                            final updatedItems = List<PlanItem>.from(
                              plan.items,
                            );
                            final firstItem = updatedItems[0];
                            // PlanItem is immutable, copy manually or assume single item update
                            // PlanItem doesn't have copyWith in snippet? I should check or create new.
                            // PlanItem(..., notificationTime: tempTime, ...)
                            final updatedItem = PlanItem(
                              title: firstItem.title,
                              days: firstItem.days,
                              count: firstItem.count,
                              description: firstItem.description,
                              notificationTime: tempTime,
                            );
                            updatedItems[0] = updatedItem;

                            final updatedPlan = plan.copyWith(
                              items: updatedItems,
                            );

                            await ref
                                .read(recordRepositoryProvider)
                                .updatePlan(updatedPlan);

                            // 2. Reschedule Alarm
                            await ref
                                .read(settingAlarmUseCaseProvider)
                                .execute(updatedPlan);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('알림 설정이 저장되었어요.')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('저장 실패: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStopCurrentPlanDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('약속을 그만할까요?'),
        content: const Text('그만하더라도 지금까지의 실천 기록은 유지돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close Dialog
              try {
                if (plan.id != null) {
                  // 1. Cancel related alarms
                  await ref.read(settingAlarmUseCaseProvider).cancel(plan);

                  // 2. Stop plan
                  await ref.read(recordRepositoryProvider).stopPlan(plan.id!);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('약속이 중단되었습니다.')),
                    );
                    context.pop();
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('처리 실패: $e')));
                }
              }
            },
            child: Text('그만하기', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showRestartPlanDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 스케줄로 다시 시작할까요?'), // 25자 이내 권장
        content: const Text(
          '현재 약속은 중단 처리되고\n새로운 약속 만들기로 이동해요.\n기존 기록은 안전하게 보관돼요.',
        ), // 줄바꿈으로 가독성 확보
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close Dialog

              try {
                if (plan.id != null) {
                  // 1. Cancel Alarms
                  await ref.read(settingAlarmUseCaseProvider).cancel(plan);

                  // 2. Stop Current Plan
                  await ref.read(recordRepositoryProvider).stopPlan(plan.id!);
                }

                if (context.mounted) {
                  // 3. Navigate to Create Screen with 'template'
                  // We pass the plan BUT verify in ViewModel to treat it as new if needed
                  // Or manually strip ID here if ViewModel logic relies on ID presence
                  // Let's pass it, and rely on PlanCreateViewModel treating it as template logic
                  // Actually, PlanCreateViewModel logic: "if (intent is InitializePlanIntent) has ID -> Existing"
                  // So we must pass a COPY without ID to treat as NEW.
                  context.pushNamed(
                    'plan-create',
                    extra: plan.copyWith(id: null), // ID 제거하여 전달 -> 신규 생성 모드
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('처리 실패: $e')));
                }
              }
            },
            child: Text('다시 시작', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
