import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/quiet_header.dart';
import '../../models/history_item.dart';
import '../../widgets/history/history_card.dart';
import '../../providers/history_provider.dart';

/// 기록 탭 - 우리가 나눈 말의 흔적을 보는 곳
class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(historyItemsProvider);
    final filter = ref.watch(historyFilterProvider);

    return Column(
      children: [
        // 헤더
        QuietHeader(
          partnerName: null,
          periodState: HeaderPeriodState.inProgress,
          onSettingsTap: null,
        ),

        // 필터 토글
        _buildFilterToggle(context, ref, filter, l10n),

        const SizedBox(height: 8),

        // 기록 리스트
        Expanded(
          child: historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                const Center(child: Text('Error loading history')),
            data: (allItems) {
              final myUid = 'me'; // TODO: Get real UID
              final filteredItems = _filterItems(allItems, filter, myUid);

              if (filteredItems.isEmpty) {
                return _buildEmptyState(context, l10n, filter);
              }

              return _buildHistoryList(context, l10n, filteredItems);
            },
          ),
        ),
      ],
    );
  }

  List<HistoryItem> _filterItems(
    List<HistoryItem> items,
    HistoryFilter filter,
    String myUid,
  ) {
    switch (filter) {
      case HistoryFilter.all:
        return items;
      case HistoryFilter.me:
        return items.where((item) => item.executorId == myUid).toList();
      case HistoryFilter.partner:
        return items.where((item) => item.executorId != myUid).toList();
    }
  }

  Widget _buildFilterToggle(
    BuildContext context,
    WidgetRef ref,
    HistoryFilter currentFilter,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildFilterButton(
              context,
              ref,
              HistoryFilter.all,
              l10n.historyFilterAll,
              currentFilter == HistoryFilter.all,
            ),
            _buildFilterButton(
              context,
              ref,
              HistoryFilter.me,
              l10n.historyFilterMe,
              currentFilter == HistoryFilter.me,
            ),
            _buildFilterButton(
              context,
              ref,
              HistoryFilter.partner,
              l10n.historyFilterPartner,
              currentFilter == HistoryFilter.partner,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    WidgetRef ref,
    HistoryFilter filter,
    String label,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(historyFilterProvider.notifier).setFilter(filter),
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

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    HistoryFilter filter,
  ) {
    String message;
    switch (filter) {
      case HistoryFilter.all:
        message = l10n
            .historyEmpty; // TODO: Use more specific empty messages from spec if needed
        break;
      case HistoryFilter.me:
        message = "아직 내가 완료한 약속이 없어요.";
        break;
      case HistoryFilter.partner:
        message = "파트너가 아직 기록을 남기지 않았어요.";
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    AppLocalizations l10n,
    List<HistoryItem> items,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomPadding),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return HistoryCard(item: item);
      },
    );
  }
}
