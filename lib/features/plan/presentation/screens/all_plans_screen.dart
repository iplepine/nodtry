import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
          isMe ? l10n.allPlansTitleMine : l10n.allPlansTitlePartner,
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
                l10n.allPlansEmpty,
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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.allPlansDeleteTitle),
          content: Text(l10n.allPlansDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.allPlansCancel, style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  if (plan.id != null) {
                    await ref
                        .read(settingAlarmUseCaseProvider)
                        .cancel(plan);
                    await ref.read(recordRepositoryProvider).deletePlan(plan.id!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.allPlansDeleted)),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.allPlansDeleteFailed(e.toString()))));
                  }
                }
              },
              child: Text(l10n.allPlansDelete, style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }
}
