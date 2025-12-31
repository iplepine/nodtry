import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/quiet_header.dart';
import '../../widgets/time_chip.dart';
import '../../models/home_state.dart';
import '../../models/history_item.dart';
import '../../routes/app_router.dart';
import '../../providers/home_provider.dart';
import '../../providers/repository_provider.dart';
import '../../utils/time_formatter.dart';

/// 지금 탭 - Now Card 기반 관계 중심 홈
class NowTab extends ConsumerStatefulWidget {
  const NowTab({super.key});

  @override
  ConsumerState<NowTab> createState() => _NowTabState();
}

class _NowTabState extends ConsumerState<NowTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _primaryFadeAnimation;
  late Animation<double> _primaryScaleAnimation;
  late Animation<double> _secondaryFadeAnimation;
  late Animation<double> _managerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Primary Card 애니메이션: Fade + Scale
    _primaryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _primaryScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Secondary Card 애니메이션: Fade
    _secondaryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Manager Card 애니메이션: Fade
    _managerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 데이터 로드 및 상태 계산 로직 (Riverpod watch 결과를 기반으로 처리)
  // 데이터 로드 및 상태 계산 로직 (Riverpod watch 결과를 기반으로 처리)
  // 데이터 변경 감지 시 애니메이션 처리
  void _onDataLoaded() {
    if (mounted) {
      _animationController.forward(from: 0.0);
    }
  }

  Future<void> _handleDidIt() async {
    final primaryCard = ref
        .read(homeCardStateProvider)
        .value
        ?.firstWhere((m) => m.state.canBeExecutorPrimary);
    if (primaryCard?.plan?.id == null) return;

    // 1. Shrink animation
    await _animationController.reverse();

    // 2. Report to repository
    try {
      await ref
          .read(recordRepositoryProvider)
          .reportCompletion(primaryCard!.plan!.id!);
      // 3. Refresh data
      ref.invalidate(homeCardStateProvider);
    } catch (e) {
      // Error handling (restore animation if failed)
      _animationController.forward();
    }
  }

  void _handleCheckIt() {
    // TODO: 확인/검증 화면으로 이동
  }

  void _handleCreatePlan() {
    // 계획 생성 플로우 진입
    context.push(AppRoutes.planCreate);
  }

  /// Time Chip 텍스트 가져오기
  String? _getTimeChipText(HomeCardModel model) {
    if (model.state == HomeCardState.pastUncompleted) {
      return '${AppLocalizations.of(context)!.pastUncompletedTimeChip} · ${AppLocalizations.of(context)!.timeChipPassed}';
    }

    if (model.plan != null && model.plan!.items.isNotEmpty) {
      // Find the item for current weekday
      // But RealRecordRepository filtered plan items.
      // Assuming plan.items contains only relevant items or we iterate.
      for (var item in model.plan!.items) {
        if (item.notificationTime != null &&
            item.notificationTime!.type != 'none') {
          // Create DateTime for today with HH:mm
          final now = DateTime.now();
          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            item.notificationTime!.hour,
            item.notificationTime!.minute,
          );
          final baseTime = TimeFormatter.formatForTimeChip(scheduledTime);
          if (model.state == HomeCardState.reportNeeded) {
            return '$baseTime · ${AppLocalizations.of(context)!.timeChipStillActionable}';
          }
          return baseTime;
        }
      }
    }
    return null;
  }

  /// Time Chip 타입 가져오기
  TimeChipType? _getTimeChipType(HomeCardModel model) {
    if (model.state == HomeCardState.pastUncompleted) {
      return TimeChipType.past;
    }

    final text = _getTimeChipText(model);
    if (text == null) return null;

    if (text == '지금!') {
      // TimeFormatter returns '지금!'
      return TimeChipType.now;
    } else if (text == '방금 전') {
      return TimeChipType.past; // or now? Spec says '1분 전' -> 지금. '5분' -> 방금 전.
    } else if (text.contains('지남') || text == '어제' || text.endsWith('전')) {
      // 'N시간 전' (미래) vs 'N시간 지남' (과거)
      // TimeFormatter distinguishes: '지남' for past, '전' for future (oops in logic?)
      // Wait, TimeFormatter: 'N분 지남' (Past), 'N분 전' (Future)
      if (text.contains('지남') || text == '어제') return TimeChipType.past;
      if (text.contains('전')) return TimeChipType.upcoming; // Future
      return TimeChipType.upcoming;
    } else {
      return TimeChipType.upcoming;
    }
  }

  /// Manager Quick Card용 Time Chip 텍스트
  String? _getManagerTimeChipText(HomeCardModel model) {
    return _getTimeChipText(model); // Use standard time chip logic for now
  }

  /// Manager Quick Card용 Time Chip 타입
  TimeChipType? _getManagerTimeChipType(HomeCardModel model) {
    return _getTimeChipType(model);
  }

  /// Secondary Executor Card용 Time Chip 텍스트
  String? _getSecondaryTimeChipText(HomeCardModel model) {
    // Reuse primary logic
    return _getTimeChipText(model);
  }

  /// Secondary Executor Card용 Time Chip 타입
  TimeChipType? _getSecondaryTimeChipType(HomeCardModel model) {
    return _getTimeChipType(model);
  }

  /// 기록의 시선 텍스트 생성
  String? _getRecordGazeText(HomeCardModel model) {
    // TODO: 히스토리 기반 칭찬/독려 메시지
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Provider 구독
    final homeStateAsync = ref.watch(homeCardStateProvider);

    // 데이터 변경 감지하여 애니메이션만 트리거
    ref.listen(homeCardStateProvider, (previous, next) {
      if (next.hasValue) {
        _onDataLoaded();
      }
    });

    return homeStateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (rawModels) {
        final models = List<HomeCardModel>.from(rawModels);
        if (models.isEmpty) {
          models.add(const HomeCardModel(state: HomeCardState.planNeeded));
        }

        // 상태 계산 (매 빌드마다 수행하거나, 필요 시 Provider에서 미리 계산하는 것이 좋음)
        final primaryExecutorCard =
            HomeCardStatePriority.selectPrimaryExecutorCard(models);
        final secondaryExecutorCards =
            HomeCardStatePriority.selectSecondaryExecutorCards(
              models,
              primaryExecutorCard,
            );
        final managerQuickCard = HomeCardStatePriority.selectManagerQuickCard(
          models,
        );
        final managerPartnerName = managerQuickCard?.partnerName;

        return Column(
          children: [
            // 헤더
            QuietHeader(
              partnerName: null,
              periodState: HeaderPeriodState.inProgress,
              onSettingsTap: null,
            ),
            // Now Card
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 24,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Executor Area (Primary Action)
                      if (primaryExecutorCard != null) ...[
                        FadeTransition(
                          opacity: _primaryFadeAnimation,
                          child: ScaleTransition(
                            scale: _primaryScaleAnimation,
                            child: SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: Offset.zero,
                                    end: const Offset(0, 0.2), // 살짝 아래로 이동
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Curves.easeIn,
                                    ),
                                  ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FractionallySizedBox(
                                  widthFactor: 0.9,
                                  child: _PrimaryExecutorCard(
                                    model: primaryExecutorCard,
                                    onDidIt: _handleDidIt,
                                    onCreatePlan: _handleCreatePlan,
                                    timeChipText: _getTimeChipText(
                                      primaryExecutorCard,
                                    ),
                                    timeChipType: _getTimeChipType(
                                      primaryExecutorCard,
                                    ),
                                    recordGazeText: _getRecordGazeText(
                                      primaryExecutorCard,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Secondary Executor Cards (My Contexts)
                      if (secondaryExecutorCards.isNotEmpty) ...[
                        ...secondaryExecutorCards.map(
                          (state) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FadeTransition(
                              opacity: _secondaryFadeAnimation,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FractionallySizedBox(
                                  widthFactor: 0.85,
                                  child: _SecondaryExecutorCard(
                                    model: state,
                                    timeChipText: _getSecondaryTimeChipText(
                                      state,
                                    ),
                                    timeChipType: _getSecondaryTimeChipType(
                                      state,
                                    ),
                                    onReconcile: () {
                                      // 데이터 갱신
                                      ref.invalidate(homeCardStateProvider);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Manager Area (Partner's Requests)
                      if (managerQuickCard != null) ...[
                        FadeTransition(
                          opacity: _managerFadeAnimation,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.88,
                              child: _ManagerQuickCard(
                                model: managerQuickCard,
                                partnerName: managerPartnerName,
                                onCheckIt: _handleCheckIt,
                                timeChipText: _getManagerTimeChipText(
                                  managerQuickCard,
                                ),
                                timeChipType: _getManagerTimeChipType(
                                  managerQuickCard,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Footer
                      const _ContextFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrimaryExecutorCard extends StatelessWidget {
  final HomeCardModel model;
  final VoidCallback? onDidIt;
  final VoidCallback? onCreatePlan;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? recordGazeText;

  const _PrimaryExecutorCard({
    required this.model,
    this.onDidIt,
    this.onCreatePlan,
    this.timeChipText,
    this.timeChipType,
    this.recordGazeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timeChipText != null && timeChipType != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [TimeChip(text: timeChipText!, type: timeChipType!)],
              ),
            if (timeChipText != null && timeChipType != null)
              const SizedBox(height: 12),
            _buildMessage(context, l10n),
            if (recordGazeText != null) ...[
              const SizedBox(height: 8),
              Text(
                recordGazeText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.left,
              ),
            ],
            const SizedBox(height: 24),
            _buildButton(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, AppLocalizations l10n) {
    final title = model.plan?.items.firstOrNull?.title;
    final List<Widget> children = [];

    if (title != null) {
      children.add(
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          textAlign: TextAlign.left,
        ),
      );
    }

    String? statusMessage;
    switch (model.state) {
      case HomeCardState.reportNeeded:
        statusMessage = l10n.homeNowTask;
        break;
      case HomeCardState.pastUncompleted:
        statusMessage = l10n.timePassedActorMessage;
        break;
      case HomeCardState.planNeeded:
        statusMessage = l10n.nowNoPlan;
        break;
      default:
        break;
    }

    if (statusMessage != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(
        Text(
          statusMessage,
          style:
              (title != null
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    color: title != null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    height: 1.5,
                  ),
          textAlign: TextAlign.left,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildButton(BuildContext context, AppLocalizations l10n) {
    final buttonTextColor = Colors.white;
    VoidCallback? onPressed;
    String buttonText;

    if (model.state == HomeCardState.reportNeeded) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (model.state == HomeCardState.planNeeded) {
      buttonText = l10n.nowCreatePlan;
      onPressed = onCreatePlan;
    } else {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: buttonTextColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.primaryPressed;
                }
                return null;
              }),
            ),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: buttonTextColor,
          ),
        ),
      ),
    );
  }
}

class _SecondaryExecutorCard extends StatelessWidget {
  final HomeCardModel model;
  final String? timeChipText;
  final TimeChipType? timeChipType;

  final VoidCallback? onReconcile;

  const _SecondaryExecutorCard({
    required this.model,
    this.timeChipText,
    this.timeChipType,
    this.onReconcile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Checked 상태인 경우 다른 레이아웃 적용
    if (model.state == HomeCardState.checked) {
      return _buildCheckedCard(context, l10n);
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (model.state == HomeCardState.pastUncompleted)
                  _ReconcileMenu(
                    planId: model.plan?.id ?? '',
                    onSuccess: onReconcile,
                  )
                else
                  const SizedBox.shrink(),
                if (timeChipText != null && timeChipType != null)
                  TimeChip(text: timeChipText!, type: timeChipType!),
              ],
            ),
            if (timeChipText != null && timeChipType != null)
              const SizedBox(height: 8),
            _buildMessage(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckedCard(BuildContext context, AppLocalizations l10n) {
    final title = model.plan?.items.firstOrNull?.title ?? '';
    final now = DateTime.now();
    final dateStr = '${now.month}.${now.day} (${_getWeekdayStr(now.weekday)})';

    // 긍정 메시지 중 하나 선택 (실제로는 기록 데이터에서 가져와야 함)
    final messages = [
      l10n.nowLateCompletion,
      l10n.nowLateJustInTime,
      l10n.nowWithinToday,
    ];
    final message = messages[now.second % messages.length];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.5), // 살짝 더 연하게
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.nowStatusActuallyDone,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekdayStr(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  Widget _buildMessage(BuildContext context, AppLocalizations l10n) {
    final title = model.plan?.items.firstOrNull?.title;
    final List<Widget> children = [];

    if (title != null) {
      children.add(
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          textAlign: TextAlign.left,
        ),
      );
    }

    String? statusMessage;
    switch (model.state) {
      case HomeCardState.waitingForCheck:
        statusMessage = '${l10n.homeSentWaiting} · ${l10n.homeWaitingForCheck}';
        break;
      case HomeCardState.checked:
        statusMessage = '${l10n.homeChecked} · ${l10n.homeThankYou}';
        break;
      case HomeCardState.quietDay:
        statusMessage = l10n.nowQuietRest;
        break;
      case HomeCardState.pastUncompleted:
        statusMessage = l10n.pastUncompletedMessage;
        break;
      default:
        break;
    }

    if (statusMessage != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 4));
      children.add(
        Text(
          statusMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: title != null
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            height: 1.4,
          ),
          textAlign: TextAlign.left,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _ManagerQuickCard extends StatelessWidget {
  final HomeCardModel model;
  final String? partnerName;
  final VoidCallback? onCheckIt;
  final String? timeChipText;
  final TimeChipType? timeChipType;

  const _ManagerQuickCard({
    required this.model,
    this.partnerName,
    this.onCheckIt,
    this.timeChipText,
    this.timeChipType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                if (partnerName != null) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary, // 파트너의 액션임을 강조
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    l10n.homeReceivedMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                if (timeChipText != null && timeChipType != null) ...[
                  const SizedBox(width: 8),
                  TimeChip(text: timeChipText!, type: timeChipType!),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCheckIt,
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return AppColors.primaryPressed;
                        }
                        return null;
                      }),
                    ),
                child: Text(
                  l10n.homeCheckIt,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextFooter extends StatelessWidget {
  const _ContextFooter();

  @override
  Widget build(BuildContext context) {
    final contextInfo = <String>[];
    if (contextInfo.isEmpty) return const SizedBox.shrink();

    return Column(
      children: contextInfo.map((info) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            info,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }
}

class _ReconcileMenu extends ConsumerWidget {
  final String planId;
  final VoidCallback? onSuccess;

  const _ReconcileMenu({required this.planId, this.onSuccess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<HistoryStatus>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
      tooltip: l10n.reconcileTitle,
      onSelected: (status) async {
        await ref.read(recordRepositoryProvider).reconcilePlan(planId, status);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.reconcileDoneMessage)));
          onSuccess?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: HistoryStatus.actuallyDone,
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 18),
              const SizedBox(width: 8),
              Text(l10n.reconcileActuallyDone),
            ],
          ),
        ),
        PopupMenuItem(
          value: HistoryStatus.rested,
          child: Row(
            children: [
              const Icon(Icons.bedtime_outlined, size: 18),
              const SizedBox(width: 8),
              Text(l10n.reconcileTookRest),
            ],
          ),
        ),
        PopupMenuItem(
          value: HistoryStatus.skipped,
          child: Row(
            children: [
              const Icon(Icons.arrow_forward_outlined, size: 18),
              const SizedBox(width: 8),
              Text(l10n.reconcileSkip),
            ],
          ),
        ),
      ],
    );
  }
}
