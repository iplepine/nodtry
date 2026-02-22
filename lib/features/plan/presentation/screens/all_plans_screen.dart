import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/plan_model.dart';
import '../../../../widgets/plan/plan_card.dart';
import '../../../../providers/plan_list_provider.dart';
import '../../../../providers/repository_provider.dart';

class AllPlansScreen extends ConsumerWidget {
  final String userId;

  const AllPlansScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPlansAsync = ref.watch(allPlansProvider(userId));
    final myProfile = ref.watch(myProfileProvider).value;
    final isMe = myProfile?.uid == userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isMe ? "나의 모든 약속" : "파트너의 모든 약속",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: allPlansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Text(
                "등록된 약속이 없어요",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          // Sort by createdAt descending
          final sortedPlans = List<Plan>.from(plans)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: sortedPlans.length,
            itemBuilder: (context, index) {
              final plan = sortedPlans[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlanCard(
                  plan: plan,
                  isOwner: isMe,
                  onTap: () {
                    context.pushNamed('plan-detail', extra: plan);
                  },
                  onEdit:
                      isMe &&
                          (plan.state == PlanState.active ||
                              plan.state == PlanState.pendingApproval ||
                              plan.state == PlanState.rejected)
                      ? () {
                          context.pushNamed('plan-create', extra: plan);
                        }
                      : null,
                  onDelete: isMe
                      ? () => _showDeletePlanDialog(context, ref, plan)
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showDeletePlanDialog(BuildContext context, WidgetRef ref, Plan plan) {
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
              Navigator.pop(context);
              try {
                if (plan.id != null) {
                  await ref.read(recordRepositoryProvider).deletePlan(plan.id!);
                  if (context.mounted) {
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
