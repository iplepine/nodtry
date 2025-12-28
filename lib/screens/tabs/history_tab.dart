import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/quiet_header.dart';
import '../../models/history_item.dart';
import '../../widgets/history/history_card.dart';

/// 기록 탭 - 우리가 나눈 말의 흔적을 보는 곳
///
/// 성과를 분석하는 곳이 아니라 기억을 보는 곳
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Mock Data
    final historyItems = [
      HistoryItem(
        date: DateTime.now().subtract(const Duration(days: 1)), // 어제
        title: '책 30분 읽기',
        status: HistoryStatus.verified,
        comment: '어제도 고마워요. 덕분에 책 읽는 시간이 생겼어요.',
        verifierName: '지민',
        verifierImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
      ),
      HistoryItem(
        date: DateTime.now().subtract(const Duration(days: 2)), // 2일 전
        title: '책 30분 읽기',
        status: HistoryStatus.done,
        comment: '오늘은 조금 늦었지만 완료!',
      ),
      HistoryItem(
        date: DateTime.now().subtract(const Duration(days: 3)), // 3일 전
        title: '책 30분 읽기',
        status: HistoryStatus.skipped,
        comment: '이번엔 못 했어',
        verifierName: '지민',
        verifierImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
      ),
      HistoryItem(
        date: DateTime.now().subtract(const Duration(days: 4)), // 4일 전
        title: '책 30분 읽기',
        status: HistoryStatus.verified,
        comment: '꾸준히 하는 모습 멋져요',
        verifierName: '지수',
        verifierImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jisoo',
      ),
    ];

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
            // TODO: Add action button to switch to US tab or Plan creation if needed
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
