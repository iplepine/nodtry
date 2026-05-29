import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/time_formatter.dart';
import '../widgets/notification_setting_editor.dart';
// import '../../../../features/plan/domain/usecases/setting_alarm_use_case.dart'; // Unused
import '../../../../models/history_item.dart';
import 'package:nod_try/providers/repository_provider.dart';
import '../widgets/plan_history_views.dart';
import '../widgets/plan_progress_card.dart';

enum _HistoryViewMode { list, calendar, graph }

enum _PlanMenuAction { restartCompleted, restartActive, stop }

class PlanDetailScreen extends ConsumerStatefulWidget {
  final Plan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _showAppBarTitleNotifier;
  bool _targetTitleState = false;
  bool _isPoking = false; // Local loading state for Poke action
  DateTime? _optimisticLastPokeAt; // Optimistic UI state
  DateTime? _optimisticLastPokeAcknowledgedAt; // Optimistic UI state
  _HistoryViewMode _historyView = _HistoryViewMode.list;

  @override
  void initState() {
    super.initState();
    _showAppBarTitleNotifier = ValueNotifier(false);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showAppBarTitleNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Show title when scrolled past a certain threshold (e.g. 40)
    final show = _scrollController.offset > 40;
    if (show != _targetTitleState) {
      _targetTitleState = show;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAppBarTitleNotifier.value = _targetTitleState;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch live plan data
    final plansAsync = ref.watch(
      getPlansByUserIdStreamProvider(widget.plan.userId),
    );

    Plan plan = widget.plan;

    // If stream has data, try to find the updated plan
    if (plansAsync.hasValue) {
      final found = plansAsync.value!
          .where((p) => p.id == widget.plan.id)
          .firstOrNull;
      if (found != null) {
        plan = found;
      }
    }

    // l10n unused for now
    final item = plan.items.first;
    final time = item.notificationTime;
    final days = item.days;

    final currentUser = ref.watch(authStateChangesProvider).value;
    final isMine = currentUser?.uid == plan.userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: ValueListenableBuilder<bool>(
          valueListenable: _showAppBarTitleNotifier,
          builder: (context, show, child) {
            return AnimatedOpacity(
              opacity: show ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isMine) _buildPlanMenu(context, ref, plan),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Divider
                    Divider(
                      color: AppColors.textDisabled.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 32),

                    // Info Rows
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_today,
                      label: _getDaysText(days, AppLocalizations.of(context)!),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(
                      context,
                      icon: Icons.access_time,
                      label: _getTimeText(time, AppLocalizations.of(context)!),
                      trailing: isMine
                          ? Icon(
                              Icons.edit,
                              size: 16,
                              color: AppColors.textSecondary,
                            )
                          : null,
                      onTap: isMine
                          ? () =>
                                _showEditNotificationDialog(context, ref, plan)
                          : null,
                    ),
                    const SizedBox(height: 32),

                    // Actions (Partner Only)
                    if (!isMine) ...[
                      _buildActionButtons(context, ref, plan),
                      const SizedBox(height: 32),
                    ],

                    // Progress / Success rate card (always visible)
                    PlanProgressCard(plan: plan),

                    const SizedBox(height: 48),

                    // History Header
                    Text(
                      AppLocalizations.of(context)!.planDetailPracticeHistory,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildViewToggle(context),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // History Content (List / Calendar / Graph)
            if (plan.id != null)
              _buildHistorySliver(context, ref, plan)
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.planDetailNotSavedPlan,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            // Bottom Padding
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_HistoryViewMode>(
      segments: [
        ButtonSegment(
          value: _HistoryViewMode.list,
          label: Text(l10n.planDetailViewList),
          icon: const Icon(Icons.list_alt, size: 18),
        ),
        ButtonSegment(
          value: _HistoryViewMode.calendar,
          label: Text(l10n.planDetailViewCalendar),
          icon: const Icon(Icons.calendar_month, size: 18),
        ),
        ButtonSegment(
          value: _HistoryViewMode.graph,
          label: Text(l10n.planDetailViewGraph),
          icon: const Icon(Icons.bar_chart, size: 18),
        ),
      ],
      selected: {_historyView},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        setState(() => _historyView = selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildHistorySliver(
    BuildContext context,
    WidgetRef ref,
    Plan plan,
  ) {
    switch (_historyView) {
      case _HistoryViewMode.list:
        return _buildHistoryListSliver(context, ref, plan);
      case _HistoryViewMode.calendar:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverToBoxAdapter(
            child: PlanHistoryCalendarView(plan: plan),
          ),
        );
      case _HistoryViewMode.graph:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverToBoxAdapter(
            child: PlanHistoryGraphView(plan: plan),
          ),
        );
    }
  }

  Widget _buildHistoryListSliver(
    BuildContext context,
    WidgetRef ref,
    Plan plan,
  ) {
    return StreamBuilder<List<HistoryItem>>(
      stream: ref.watch(getPlanHistoryUseCaseProvider).execute(plan.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint('History Stream Error: ${snapshot.error}');
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    AppLocalizations.of(context)!
                        .planDetailLoadFailed(snapshot.error.toString()),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.planDetailNoRecords,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index.isOdd) return const Divider();
              final itemIndex = index ~/ 2;
              final item = items[itemIndex];
              return _buildHistoryItem(context, item);
            }, childCount: items.length * 2 - 1),
          ),
        );
      },
    );
  }

  /// 약속 상세 우상단 메뉴. 빨간 정지 아이콘이 톤에 안 맞는다는 피드백을 반영해
  /// 재시작 / 중단 두 액션을 하나의 PopupMenuButton으로 모은다.
  /// - active: "새 스케줄로 다시 시작" + "약속 중단"(빨강 텍스트)
  /// - completed/stopped: "이 약속으로 다시 만들기"
  Widget _buildPlanMenu(BuildContext context, WidgetRef ref, Plan plan) {
    if (plan.state != PlanState.active &&
        plan.state != PlanState.completed &&
        plan.state != PlanState.stopped) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<_PlanMenuAction>(
      tooltip: l10n.planDetailMoreMenu,
      icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
      onSelected: (action) {
        switch (action) {
          case _PlanMenuAction.restartCompleted:
            _showCreateFromCompletedDialog(context, ref);
            break;
          case _PlanMenuAction.restartActive:
            _showRestartPlanDialog(context, ref);
            break;
          case _PlanMenuAction.stop:
            _showStopCurrentPlanDialog(context, ref);
            break;
        }
      },
      itemBuilder: (context) {
        if (plan.state == PlanState.completed ||
            plan.state == PlanState.stopped) {
          return [
            PopupMenuItem(
              value: _PlanMenuAction.restartCompleted,
              child: Row(
                children: [
                  Icon(
                    Icons.refresh,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.planDetailMenuRestartCompleted),
                ],
              ),
            ),
          ];
        }
        // active
        return [
          PopupMenuItem(
            value: _PlanMenuAction.restartActive,
            child: Row(
              children: [
                Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(l10n.planDetailMenuRestartActive),
              ],
            ),
          ),
          PopupMenuItem(
            value: _PlanMenuAction.stop,
            child: Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.planDetailMenuStop,
                  style: TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, HistoryItem item) {
    IconData icon = Icons.help_outline;
    Color color = AppColors.textDisabled;

    switch (item.status) {
      case HistoryStatus.done:
      case HistoryStatus.actuallyDone:
      case HistoryStatus.verified:
        icon = Icons.check_circle;
        color = AppColors.primary;
        break;
      case HistoryStatus.skipped:
        icon = Icons.cancel_outlined;
        color = AppColors.textDisabled;
        break;
      case HistoryStatus.rested:
        icon = Icons.hotel;
        color = AppColors.secondary;
        break;
      case HistoryStatus.rescued:
        icon = Icons.volunteer_activism;
        color = AppColors.secondary;
        break;
    }

    // Format Date: e.g. 1/12 (Mon)
    // Simple util or manual
    final dateStr = '${item.date.month}/${item.date.day}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        _getHistoryStatusText(item.status, AppLocalizations.of(context)!),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: item.note != null && item.note!.isNotEmpty
          ? Text(item.note!, style: TextStyle(color: AppColors.textSecondary))
          : null,
      trailing: Text(
        dateStr,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  String _getHistoryStatusText(HistoryStatus status, AppLocalizations l10n) {
    switch (status) {
      case HistoryStatus.done:
      case HistoryStatus.actuallyDone:
      case HistoryStatus.verified:
        return l10n.planDetailRecordDone;
      case HistoryStatus.skipped:
        return l10n.planDetailRecordSkipped;
      case HistoryStatus.rested:
        return l10n.planDetailRecordRested;
      case HistoryStatus.rescued:
        return l10n.planDetailRecordRescued;
    }
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Plan plan) {
    // Check for Poke availability
    // Prioritize Optimistic State if available
    final effectiveLastPokeAt = _optimisticLastPokeAt ?? plan.lastPokeAt;
    final effectiveLastPokeAcknowledgedAt =
        _optimisticLastPokeAcknowledgedAt ?? plan.lastPokeAcknowledgedAt;

    final now = DateTime.now();

    // Check if poked today
    bool isSameDay(DateTime? value) {
      if (value == null) return false;
      final local = value.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }

    final isPokedToday =
        isSameDay(effectiveLastPokeAt) &&
        !isSameDay(effectiveLastPokeAcknowledgedAt);

    // 파트너가 오늘 이미 완료/스킵/휴식/실천인정한 경우 똑똑 불필요
    final isHandledToday =
        plan.completedDates.any(isSameDay) ||
        plan.skippedDates.any(isSameDay) ||
        plan.restedDates.any(isSameDay) ||
        plan.rescuedDates.any(isSameDay);

    final isPokeDisabled = isPokedToday || isHandledToday || _isPoking;

    // Debug Log
    debugPrint('[PlanDetail] Plan ID: ${plan.id}');
    debugPrint(
      '[PlanDetail] lastPokeAt: $effectiveLastPokeAt (Local: ${effectiveLastPokeAt?.toLocal()})',
    );
    debugPrint(
      '[PlanDetail] lastPokeAcknowledgedAt: $effectiveLastPokeAcknowledgedAt (Local: ${effectiveLastPokeAcknowledgedAt?.toLocal()})',
    );
    debugPrint('[PlanDetail] Now: $now');
    debugPrint(
      '[PlanDetail] isPokedToday: $isPokedToday, _isPoking: $_isPoking',
    );

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isPokeDisabled
            ? null
            : () async {
                setState(() => _isPoking = true); // Disable immediately
                try {
                  await ref.read(pokePartnerUseCaseProvider).execute(plan.id!);
                  if (context.mounted) {
                    // Optimistic Update: Force local state to "Poked Today"
                    setState(() {
                      _optimisticLastPokeAt = DateTime.now();
                      _optimisticLastPokeAcknowledgedAt = null;
                      _isPoking = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.planDetailPokeSent)),
                    );
                  }
                } catch (e) {
                  if (mounted) setState(() => _isPoking = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.planDetailPokeFailed(e.toString()))));
                  }
                }
              },
        icon: _isPoking
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.touch_app, size: 18),
        label: Text(
          isHandledToday
              ? AppLocalizations.of(context)!.planDetailPokeAlreadyDone
              : isPokedToday
                  ? AppLocalizations.of(context)!.planDetailPokeDoneToday
                  : (_isPoking ? AppLocalizations.of(context)!.planDetailPokeSending : AppLocalizations.of(context)!.planDetailPokeAsk),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: isPokeDisabled
                ? AppColors.textDisabled.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.5),
          ),
          foregroundColor: isPokeDisabled
              ? AppColors.textDisabled
              : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  String _getDaysText(List<int> days, AppLocalizations l10n) {
    // 1=Mon, 7=Sun
    final weekDays = [
      l10n.planDetailDayMon,
      l10n.planDetailDayTue,
      l10n.planDetailDayWed,
      l10n.planDetailDayThu,
      l10n.planDetailDayFri,
      l10n.planDetailDaySat,
      l10n.planDetailDaySun,
    ];
    if (days.length == 7) return l10n.planDetailEveryDay;

    // Sort just in case
    final sortedDays = List<int>.from(days)..sort();
    return sortedDays.map((d) => weekDays[d - 1]).join(', ');
  }

  String _getTimeText(NotificationTime? time, AppLocalizations l10n) {
    if (time == null || time.type == 'none') {
      if (time != null && (time.hour != 0 || time.minute != 0)) {
        final dt = DateTime(2020, 1, 1, time.targetHour, time.targetMinute);
        return TimeFormatter.formatExactTime(dt);
      }
      return l10n.planDetailTimeUnset;
    }
    final dt = DateTime(2020, 1, 1, time.targetHour, time.targetMinute);
    return TimeFormatter.formatExactTime(dt);
  }

  void _showEditNotificationDialog(
    BuildContext context,
    WidgetRef ref,
    Plan sourcePlan,
  ) {
    final notificationTime =
        sourcePlan.items.first.notificationTime ?? NotificationTime.none();
    // We need state for the editor.
    NotificationTime tempTime = notificationTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Editor
                    // Import needed? It's in the project already.
                    // I will add import at top of file.
                    // Assuming widget is imported.
                    // NotificationSettingEditor is a widget I created.
                    // I will need to replace the imports in this file too.
                    NotificationSettingEditor(
                      notificationTime: tempTime,
                      onTimeChanged: (newTime) {
                        setState(() {
                          tempTime = newTime;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (sourcePlan.id == null) return;

                          try {
                            // 1. Update Plan
                            final updatedItems = List<PlanItem>.from(
                              sourcePlan.items,
                            );
                            final firstItem = updatedItems[0];
                            // PlanItem is immutable, copy manually or assume single item update
                            // PlanItem doesn't have copyWith in snippet? I should check or create new.
                            // PlanItem(..., notificationTime: tempTime, ...)
                            final updatedItem = PlanItem(
                              title: firstItem.title,
                              days: firstItem.days,
                              count: firstItem.count,
                              description: firstItem.description,
                              notificationTime: tempTime,
                            );
                            updatedItems[0] = updatedItem;

                            final updatedPlan = sourcePlan.copyWith(
                              items: updatedItems,
                            );
                            final repository = ref.read(
                              recordRepositoryProvider,
                            );
                            final settingAlarmUseCase = ref.read(
                              settingAlarmUseCaseProvider,
                            );

                            await repository.updatePlan(updatedPlan);
                            await settingAlarmUseCase.execute(updatedPlan);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.planDetailNotificationSaved)),
                              );
                            }
                          } catch (e) {
                            try {
                              await ref
                                  .read(recordRepositoryProvider)
                                  .updatePlan(sourcePlan);
                              await ref
                                  .read(settingAlarmUseCaseProvider)
                                  .execute(sourcePlan);
                            } catch (rollbackError) {
                              debugPrint(
                                '[PlanDetail] Failed to rollback notification change: $rollbackError',
                              );
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.planDetailNotificationSaveFailed)),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.planDetailSave,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStopCurrentPlanDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.planDetailStopTitle),
          content: Text(l10n.planDetailStopBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.planDetailCancel, style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close Dialog
                try {
                  if (widget.plan.id != null) {
                    await ref
                        .read(settingAlarmUseCaseProvider)
                        .cancel(widget.plan);

                    await ref
                        .read(recordRepositoryProvider)
                        .stopPlan(widget.plan.id!);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.planDetailStopped)),
                      );
                      context.pop();
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.planDetailActionFailed(e.toString()))));
                  }
                }
              },
              child: Text(l10n.planDetailStop, style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  void _showCreateFromCompletedDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.planDetailRestartTitle),
          content: Text(l10n.planDetailRestartBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.planDetailCancel, style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (context.mounted) {
                  context.pushNamed(
                    'plan-create',
                    extra: widget.plan.copyWith(id: null),
                    queryParameters: {'startAtLastStep': 'true'},
                  );
                }
              },
              child: Text(l10n.planDetailRestart, style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showRestartPlanDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.planDetailRestartWithScheduleTitle),
          content: Text(l10n.planDetailReplaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.planDetailCancel, style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close Dialog

                try {
                  if (widget.plan.id != null) {
                    await ref
                        .read(settingAlarmUseCaseProvider)
                        .cancel(widget.plan);

                    await ref
                        .read(recordRepositoryProvider)
                        .stopPlan(widget.plan.id!);
                  }

                  if (context.mounted) {
                    context.pushNamed(
                      'plan-create',
                      extra: widget.plan.copyWith(id: null),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.planDetailActionFailed(e.toString()))));
                  }
                }
              },
              child: Text(l10n.planDetailRestart, style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

}
