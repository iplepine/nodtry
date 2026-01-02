import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:nod_try/theme/app_colors.dart';
import '../../../../widgets/quiet_header.dart';
import '../../../../models/history_item.dart';
import '../../../../widgets/history/history_card.dart';
import '../../../../providers/repository_provider.dart'; // for myProfileProvider
import '../history_state.dart';
import '../history_viewmodel.dart';

/// 기록 탭 (History Tab / Record Tab)
/// 우리가 나눈 말의 흔적을 보는 곳
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyStateAsync = ref.watch(historyViewModelProvider);
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
        historyStateAsync.when(
          data: (state) =>
              _buildFilterToggle(context, ref, state.currentFilter, l10n),
          loading: () => const SizedBox(height: 48), // Spacer during loading
          error: (_, __) => const SizedBox(height: 48),
        ),

        const SizedBox(height: 8),

        // 기록 리스트
        Expanded(
          child: historyStateAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (state) {
              final items = state.items;
              if (items.isEmpty) {
                return _buildEmptyState(context, l10n, state.currentFilter);
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100), // Tab bar spacing
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
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
    final l10n = AppLocalizations.of(context)!;
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
              _buildActionButton(
                context,
                l10n.homeDidIt, // "했어"
                AppColors.primary,
                () {
                  ref
                      .read(historyViewModelProvider.notifier)
                      .dispatch(
                        ReconcileIntent(item.id, HistoryStatus.actuallyDone),
                      );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                '보류할게요', // TODO: L10n
                AppColors.textSecondary,
                () {
                  ref
                      .read(historyViewModelProvider.notifier)
                      .dispatch(ReconcileIntent(item.id, HistoryStatus.rested));
                  Navigator.pop(context);
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
    HistoryFilterType currentFilter,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            _buildFilterButton(
              context,
              ref,
              HistoryFilterType.all,
              '모두', // TODO: L10n.historyFilterAll
              currentFilter == HistoryFilterType.all,
            ),
            _buildFilterButton(
              context,
              ref,
              HistoryFilterType.me,
              '나',
              currentFilter == HistoryFilterType.me,
            ),
            _buildFilterButton(
              context,
              ref,
              HistoryFilterType.partner,
              '파트너',
              currentFilter == HistoryFilterType.partner,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    WidgetRef ref,
    HistoryFilterType filter,
    String label,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref
            .read(historyViewModelProvider.notifier)
            .dispatch(SetFilterIntent(filter)),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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

  Widget _buildEmptyState(context, l10n, HistoryFilterType filter) {
    String message = "기록이 없어요";
    if (filter == HistoryFilterType.me) message = "나의 기록이 없어요";
    if (filter == HistoryFilterType.partner) message = "파트너의 기록이 없어요";

    return Center(
      child: Text(message, style: TextStyle(color: AppColors.textDisabled)),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
