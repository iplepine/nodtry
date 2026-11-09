part of '../us_screen.dart';

class _ActivePlanListSection extends ConsumerWidget {
  final String userId;
  final String title;
  final bool isMe;

  const _ActivePlanListSection({
    required this.userId,
    required this.title,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(activePlansProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      context.pushNamed('all-plans', extra: userId),
                  child: Text(
                    l10n.usSeeAll,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List
        plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? l10n.usEmptyMine : l10n.usEmptyPartner,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => context.push(AppRoutes.planCreate),
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ).copyWith(
                                overlayColor:
                                    WidgetStateProperty.resolveWith<Color?>((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.pressed,
                                      )) {
                                        return AppColors.primaryPressed;
                                      }
                                      return null;
                                    }),
                              ),
                          child: Text(
                            l10n.usCreatePlanShort,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }
            return Column(
              children: [
                ...plans.map(
                  (plan) => PlanCard(
                    plan: plan,
                    isOwner: isMe,
                    onTap: () {
                      context.pushNamed('plan-detail', extra: plan);
                    },
                    onEdit: isMe
                        ? () {
                            context.pushNamed('plan-create', extra: plan);
                          }
                        : null,
                    onDelete: isMe
                        ? () => _showDeletePlanDialog(context, ref, plan)
                        : null,
                    // No cheer button here: it only showed a "sent" snackbar
                    // and never reached the partner. 인정/응원 lives on the
                    // Now tab where it is actually delivered.
                  ),
                ),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.planCreate),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.5),
                          ),
                          color: AppColors.surface.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.usCreatePlan,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, stack) => Text(
            l10n.historyErrorUnknown,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _showDeletePlanDialog(BuildContext context, WidgetRef ref, Plan plan) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.usDeletePlanTitle),
          content: Text(l10n.usDeletePlanBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.usCancel,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close Dialog
                try {
                  if (plan.id != null) {
                    // 1. Cancel related alarms
                    await ref.read(settingAlarmUseCaseProvider).cancel(plan);

                    // 2. Delete plan from repository
                    await ref
                        .read(recordRepositoryProvider)
                        .deletePlan(plan.id!);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.usPlanDeleted,
                          ),
                        ),
                      );
                      // Refresh plans by invalidating the provider
                      ref.invalidate(activePlansProvider(userId));
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.usDeleteFailed,
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(
                l10n.usDelete,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
