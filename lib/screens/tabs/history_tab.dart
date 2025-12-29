import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/quiet_header.dart';
import '../../models/history_item.dart';
import '../../widgets/history/history_card.dart';
import '../../providers/repository_provider.dart';

/// 기록 탭 - 우리가 나눈 말의 흔적을 보는 곳
///
/// 성과를 분석하는 곳이 아니라 기억을 보는 곳
class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.watch(recordRepositoryProvider);

    return FutureBuilder<List<HistoryItem>>(
      future: repository.getHistoryItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading history'));
        }

        final historyItems = snapshot.data ?? [];

        return Column(
          children: [
            // 헤더
            QuietHeader(
              partnerName: null, // TODO: 실제 데이터에서 가져오기
              periodState:
                  HeaderPeriodState.inProgress, // 임시: 텍스트 숨김 (User Feedback)
              onSettingsTap: null,
            ),

            // 기록 리스트
            Expanded(
              child: historyItems.isEmpty
                  ? _buildEmptyState(context, l10n)
                  : _buildHistoryList(context, l10n, historyItems),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 24),
            Text(
              l10n.historyEmpty,
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
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return HistoryCard(item: item);
      },
    );
  }
}
