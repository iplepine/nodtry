import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/quiet_header.dart';
import '../../models/history_item.dart';
import '../../widgets/history/history_card.dart';
import '../../viewmodels/record_tab_viewmodel.dart';
import '../../providers/repository_provider.dart'; // for myProfileProvider

/// 기록 탭 (History Tab / Record Tab)
/// 우리가 나눈 말의 흔적을 보는 곳
class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(recordTabViewModelProvider);
    final viewModel = ref.read(recordTabViewModelProvider.notifier);
    final currentFilter = viewModel.currentFilter;
    final myProfileAsync = ref.watch(myProfileProvider);
    final myUid = myProfileAsync.value?.uid ?? 'me';

    return Column(
      children: [
        // 헤더
        QuietHeader(
          partnerName: null,
          periodState: HeaderPeriodState.inProgress,
          onSettingsTap: null,
        ),

        // 필터 토글
        _buildFilterToggle(context, ref, currentFilter, l10n),

        const SizedBox(height: 8),

        // 기록 리스트
        Expanded(
          child: historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyState(context, l10n, currentFilter);
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100), // Tab bar spacing
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  // Determine isMe based on executorId
                  // Note: In Mock, executorId is 'me' or 'partner'.
                  // In Real, it will be UID.
                  // For now, check both for robust mock support.
                  final isMe =
                      item.executorId == myUid || item.executorId == 'me';

                  return HistoryCard(
                    item: item,
                    isMe: isMe,
                    onReconcile: () => _showReconcileSheet(context, ref, item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showReconcileSheet(
    BuildContext context,
    WidgetRef ref,
    HistoryItem item,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '지난 기록 소명하기', // TODO: L10n
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '이 날의 약속, 사실 어땠나요?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Actions
              _ReconcileOption(
                icon: Icons.check_circle_outline,
                color: AppColors.secondary,
                label: '사실 했어요',
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(recordTabViewModelProvider.notifier)
                      .reconcile(item.id, HistoryStatus.actuallyDone);
                },
              ),
              const SizedBox(height: 16),
              _ReconcileOption(
                icon: Icons.hotel,
                color: Colors.grey,
                label: '넘어갔지만, 오늘은 쉬었어요', // Rested
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(recordTabViewModelProvider.notifier)
                      .reconcile(item.id, HistoryStatus.rested);
                },
              ),
              // Cancel
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterToggle(
    BuildContext context,
    WidgetRef ref,
    FilterType currentFilter,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            _buildFilterButton(
              context,
              ref,
              FilterType.all,
              '모두', // TODO: L10n.historyFilterAll
              currentFilter == FilterType.all,
            ),
            _buildFilterButton(
              context,
              ref,
              FilterType.me,
              '나',
              currentFilter == FilterType.me,
            ),
            _buildFilterButton(
              context,
              ref,
              FilterType.partner,
              '파트너',
              currentFilter == FilterType.partner,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    WidgetRef ref,
    FilterType filter,
    String label,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(recordTabViewModelProvider.notifier).setFilter(filter),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(context, l10n, FilterType filter) {
    String message = "기록이 없어요";
    if (filter == FilterType.me) message = "나의 기록이 없어요";
    if (filter == FilterType.partner) message = "파트너의 기록이 없어요";

    return Center(
      child: Text(message, style: TextStyle(color: AppColors.textDisabled)),
    );
  }
}

class _ReconcileOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ReconcileOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
