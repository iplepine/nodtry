import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:nod_try/theme/app_colors.dart';
import '../../../../widgets/app_underlined_text.dart';
import '../../../../widgets/quiet_header.dart';
import '../../../../models/history_item.dart';
import '../../../../widgets/history/history_card.dart';
import '../../../../widgets/history/plan_summary_card.dart';
import '../../../../providers/repository_provider.dart'; // for myProfileProvider
import '../../../../utils/build_flags.dart';
import '../history_state.dart';
import '../history_viewmodel.dart';
import '../history_fake_states.dart';
import '../../../duo/application/duo_stats_provider.dart';
import '../../../duo/presentation/duo_widgets.dart';
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
    // The same 둘운완 stats as the Now header and the Us hero.
    final duoStats = ref.watch(duoStatsProvider);

    // A 인정 / 기록 변경 that failed: say so, keep the list.
    ref.listen(historyActionFailureProvider, (previous, next) {
      if (previous != null && next != previous) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.nowActionFailed)));
      }
    });

    ref.listen(historyViewModelProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        if (previous?.hasError != true) {
          final error = next.error;
          String errorMessage = l10n.historyErrorUnknown;
          String? errorUrl;

          if (error.toString().contains('failed-precondition') ||
              error.toString().contains('requires an index')) {
            errorMessage = l10n.historyErrorIndexMissing;
            final urlRegExp = RegExp(
              r'https://console\.firebase\.google\.com[^\s]*',
            );
            final match = urlRegExp.firstMatch(error.toString());
            if (match != null) {
              errorUrl = match.group(0);
            }
          } else if (error.toString().contains('not-found') ||
              error.toString().contains('No document to update')) {
            errorMessage = l10n.historyErrorAlreadyDeleted;
          } else {
            errorMessage = error.toString();
          }

          showDialog(
            context: context,
            builder: (context) {
              final dl10n = AppLocalizations.of(context)!;
              return AlertDialog(
                title: Text(dl10n.historyErrorTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(errorMessage),
                    if (errorUrl != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        dl10n.historyErrorCreationLink,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      AppUnderlinedText.selectable(
                        errorUrl,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(dl10n.historyOk),
                  ),
                ],
              );
            },
          );
        }
      }
    });

    return Stack(
      children: [
        Column(
          children: [
            // 헤더
            if (historyStateAsync.hasValue)
              QuietHeader(
                partnerName: historyStateAsync.value!.partnerName,
                periodState: historyStateAsync.value!.headerPeriodState,
              ),

            const SizedBox(height: 8),

            // 필터 칩 제거됨
            const SizedBox(height: 8),

            // 기록 리스트
            Expanded(
              // 에러가 있어도 데이터가 있으면 보여줌 (Dialog로 에러 알림)
              child: historyStateAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppLocalizations.of(context)!.historyErrorUnknown,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                data: (state) {
                  if (state.activeItems.isEmpty &&
                      state.finishedPlanSummaries.isEmpty) {
                    return _buildEmptyState(context, l10n);
                  }

                  return CustomScrollView(
                    slivers: [
                      // 0. 주간 펄스 카드 — this week from the 둘운완 stats.
                      if (duoStats != null && state.activeItems.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _WeeklyPulseCard(
                            stats: duoStats,
                            partnerLabel:
                                state.partnerName ??
                                l10n.historyWeeklyPartnerLabel,
                            l10n: l10n,
                          ),
                        ),

                      // 1. 진행 중인 약속 섹션
                      if (state.activeItems.isNotEmpty) ...[
                        _buildSectionHeader(context, l10n.historySectionActive),
                        ..._buildGroupedActiveItems(
                          context,
                          state.activeItems,
                          myUid,
                          ref,
                          l10n,
                        ),
                      ],

                      // 2. 종료된 약속 섹션
                      if (state.finishedPlanSummaries.isNotEmpty) ...[
                        _buildSectionHeader(context, l10n.historySectionFinished),
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
        if (kDebugMode && !BuildFlags.storeScreenshotMode)
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
    BuildContext context,
    List<HistoryItem> items,
    String myUid,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final grouped = <DateTime, List<HistoryItem>>{};
    for (var item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final widgets = <Widget>[];

    // 직전 카드의 plan id를 추적해서 같은 plan이 이어질 때 제목 반복을 생략한다.
    // (날짜 그룹 경계는 무시: 같은 약속이 연속 며칠이면 제목 노이즈가 크기 때문.)
    String? prevPlanId;
    bool isFirstItem = true;

    for (var date in sortedDates) {
      // 날짜 헤더
      widgets.add(
        SliverToBoxAdapter(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                _formatSectionDate(date, l10n),
                style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
              ),
            ),
          ),
        ),
      );

      // 해당 날짜의 아이템들 — 직전 비교를 위해 SliverToBoxAdapter로 풀어서 추가.
      final dateItems = grouped[date]!;
      for (var item in dateItems) {
        final isMe = item.executorId == myUid || item.executorId == 'me';
        final showTitle = isFirstItem || item.planId != prevPlanId || item.planId == null;

        widgets.add(
          SliverToBoxAdapter(
            child: HistoryCard(
              item: item,
              isMe: isMe,
              showTitle: showTitle,
              onReconcile: () => _showReconcileSheet(context, ref, item),
            ),
          ),
        );

        prevPlanId = item.planId;
        isFirstItem = false;
      }
    }

    return widgets;
  }

  String _formatSectionDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return l10n.historyToday;
    if (date == yesterday) return l10n.historyYesterday;
    return DateFormat(l10n.historyDatePattern, l10n.localeName).format(date);
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
                l10n.historyReconcileTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.historyReconcileSubtitle,
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
              _buildActionButton(context, l10n.historyReconcileHold, AppColors.textSecondary, () {
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
        l10n.historyEmpty,
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

/// 상단 주간 펄스 카드.
/// 이번 주(월~일) 나/짝꿍의 하루를 둘운완 기준으로 보여 준다 — 지금 탭 헤더,
/// 우리 탭과 같은 [DuoStats]라서 세 화면의 숫자가 어긋나지 않는다.
class _WeeklyPulseCard extends StatelessWidget {
  final DuoStats stats;
  final String partnerLabel;
  final AppLocalizations l10n;

  const _WeeklyPulseCard({
    required this.stats,
    required this.partnerLabel,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final myDone = stats.week.where((d) => d.me.isDone).length;
    final partnerDone = stats.week.where((d) => d.partner.isDone).length;

    return Container(
      key: const ValueKey('history-weekly-pulse'),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.historyWeeklyPulseTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (stats.hasPartner)
                Text(
                  l10n.duoWeekDuoDays(stats.weekDuoDays),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: [
                _CountChip(
                  label: l10n.historyWeeklyMeLabel,
                  count: myDone,
                  color: AppColors.primary,
                ),
                if (stats.hasPartner)
                  _CountChip(
                    label: partnerLabel,
                    count: partnerDone,
                    // Text colour: the readable honey, not the yellow fill.
                    color: AppColors.accentWine,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DuoWeekDots(
            week: stats.week,
            showPartner: stats.hasPartner,
            meLabel: l10n.historyWeeklyMeLabel,
            partnerLabel: partnerLabel,
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count/7',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
