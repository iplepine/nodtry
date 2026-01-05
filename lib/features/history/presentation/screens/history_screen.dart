import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:nod_try/theme/app_colors.dart';
import '../../../../widgets/quiet_header.dart';
import '../../../../models/history_item.dart';
import '../../../../widgets/history/history_card.dart';
import '../../../../widgets/history/plan_summary_card.dart';
import '../../../../providers/repository_provider.dart'; // for myProfileProvider
import '../history_state.dart';
import '../history_viewmodel.dart';
import '../history_fake_states.dart';
import 'package:intl/intl.dart';

/// 기록 탭 (History Tab)
/// 우리가 나눈 약속의 흔적을 보는 곳
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyStateAsync = ref.watch(historyViewModelProvider);
    final myProfileAsync = ref.watch(myProfileProvider);
    final myUid = myProfileAsync.value?.uid ?? 'me';

    ref.listen(historyViewModelProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        if (previous?.hasError != true) {
          final error = next.error;
          String errorMessage = '알 수 없는 오류가 발생했습니다.';
          String? errorUrl;

          if (error.toString().contains('failed-precondition') ||
              error.toString().contains('requires an index')) {
            errorMessage = '데이터 조회에 필요한 인덱스가 없습니다.\n개발자에게 이 화면을 캡처해서 보내주세요.';
            final urlRegExp = RegExp(
              r'https://console\.firebase\.google\.com[^\s]*',
            );
            final match = urlRegExp.firstMatch(error.toString());
            if (match != null) {
              errorUrl = match.group(0);
            }
          } else {
            errorMessage = error.toString();
          }

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('오류 발생'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMessage),
                  if (errorUrl != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '생성 링크:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      errorUrl,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      }
    });

    return Stack(
      children: [
        Column(
          children: [
            // 헤더
            QuietHeader(
              partnerName: null,
              periodState: HeaderPeriodState.inProgress,
              onSettingsTap: null,
            ),

            const SizedBox(height: 8),

            // 기록 리스트
            Expanded(
              // 에러가 있어도 데이터가 있으면 보여줌 (Dialog로 에러 알림)
              child: historyStateAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (state) {
                  if (state.activeItems.isEmpty &&
                      state.finishedPlanSummaries.isEmpty) {
                    return _buildEmptyState(context, l10n);
                  }

                  return CustomScrollView(
                    slivers: [
                      // 1. 진행 중인 약속 섹션
                      if (state.activeItems.isNotEmpty) ...[
                        _buildSectionHeader(context, '진행 중인 약속'),
                        ..._buildGroupedActiveItems(
                          state.activeItems,
                          myUid,
                          ref,
                        ),
                      ],

                      // 2. 종료된 약속 섹션
                      if (state.finishedPlanSummaries.isNotEmpty) ...[
                        _buildSectionHeader(context, '종료된 약속'),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final summary = state.finishedPlanSummaries[index];
                            return PlanSummaryCard(summary: summary);
                          }, childCount: state.finishedPlanSummaries.length),
                        ),
                      ],

                      // 하단 여백 (탭바 공간 확보)
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        // Debug Fake State Toggle Button (Debug Only)
        if (kDebugMode)
          Positioned(
            bottom: 120, // Raised to avoid bottom nav overlap
            right: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'history_debug_fab', // Unique tag to avoid conflicts
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.bug_report, size: 20),
              onPressed: () {
                _showFakeStateSelector(context, ref);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedActiveItems(
    List<HistoryItem> items,
    String myUid,
    WidgetRef ref,
  ) {
    final grouped = <DateTime, List<HistoryItem>>{};
    for (var item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final widgets = <Widget>[];

    for (var date in sortedDates) {
      // 날짜 헤더
      widgets.add(
        SliverToBoxAdapter(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                _formatSectionDate(date),
                style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
              ),
            ),
          ),
        ),
      );

      // 해당 날짜의 아이템들
      final dateItems = grouped[date]!;
      widgets.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = dateItems[index];
            final isMe = item.executorId == myUid || item.executorId == 'me';

            return HistoryCard(
              item: item,
              isMe: isMe,
              onReconcile: () => _showReconcileSheet(context, ref, item),
            );
          }, childCount: dateItems.length),
        ),
      );
    }

    return widgets;
  }

  String _formatSectionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return '오늘';
    if (date == yesterday) return '어제';
    return DateFormat('yyyy년 M월 d일').format(date);
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
                '지난 기록 소명하기',
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

              _buildActionButton(
                context,
                l10n.homeDidIt,
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
              _buildActionButton(context, '보류할게요', AppColors.textSecondary, () {
                ref
                    .read(historyViewModelProvider.notifier)
                    .dispatch(ReconcileIntent(item.id, HistoryStatus.rested));
                Navigator.pop(context);
              }),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Text(
        "아직 기록된 약속이 없어요",
        style: TextStyle(color: AppColors.textDisabled),
      ),
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

  void _showFakeStateSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Debug: FakeState 선택',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: HistoryFakeStates.all.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text(
                        'Active: ${entry.value.activeItems.length}, '
                        'Finished: ${entry.value.finishedPlanSummaries.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDisabled,
                        ),
                      ),
                      onTap: () {
                        ref
                            .read(historyViewModelProvider.notifier)
                            .setFakeState(entry.value);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ 적용됨: ${entry.key}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(historyViewModelProvider);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔄 실제 데이터로 복구됨'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                  ),
                  icon: Icon(Icons.refresh, color: AppColors.primary),
                  label: Text(
                    '실제 데이터로 복구',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
