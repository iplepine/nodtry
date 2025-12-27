import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// 기록 탭 - 우리가 나눈 말의 흔적을 보는 곳
/// 
/// 성과를 분석하는 곳이 아니라 기억을 보는 곳
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // TODO: 실제 데이터에서 기록 가져오기
    final historyItems = <_HistoryItem>[];
    
    return historyItems.isEmpty
        ? _buildEmptyState(context, l10n)
        : _buildHistoryList(context, l10n, historyItems);
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.historyEmpty,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
    List<_HistoryItem> items,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _HistoryItemCard(item: item);
      },
    );
  }
}

/// 기록 항목 데이터 모델 (임시)
class _HistoryItem {
  final DateTime date;
  final String status; // "했어", "확인됐어요", "이번엔 못 했어"
  final String? comment; // 선택적 코멘트

  _HistoryItem({
    required this.date,
    required this.status,
    this.comment, // 실제 데이터 연동 시 사용됨
  });
  
  // comment가 null이 아닌지 확인하는 getter
  bool get hasComment => comment != null && comment!.isNotEmpty;
}

/// 기록 항목 카드
class _HistoryItemCard extends StatelessWidget {
  final _HistoryItem item;

  const _HistoryItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(item.date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  item.status,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            if (item.hasComment) ...[
              const SizedBox(height: 8),
              Text(
                item.comment!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // TODO: 다국어 날짜 포맷
    return '${date.year}.${date.month}.${date.day}';
  }
}

