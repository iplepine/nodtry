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
          IconButton(
            icon: Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () {
              // Navigate to Edit Mode
              context.pushNamed(
                'plan-create',
                extra: plan, // Pass plan object for editing
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _showDeleteCurrentPlanDialog(context, ref),
          ),
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

  void _showDeleteCurrentPlanDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('약속을 삭제할까요?'),
        content: const Text('삭제하면 되돌릴 수 없어요.'),
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
                  await ref.read(recordRepositoryProvider).deletePlan(plan.id!);
                  if (context.mounted) {
                    context.pop(); // Close Detail Screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('약속이 삭제되었습니다.')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
                }
              }
            },
            child: Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
