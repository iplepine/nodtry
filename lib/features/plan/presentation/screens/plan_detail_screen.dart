import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/plan_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/time_formatter.dart';
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Row(
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
      ],
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
    if (time == null || time.type == 'none') return '시간 미정';
    // Use TimeFormatter logic ideally, or simple formatting
    final dt = DateTime(2020, 1, 1, time.hour, time.minute);
    return TimeFormatter.formatExactTime(dt);
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
