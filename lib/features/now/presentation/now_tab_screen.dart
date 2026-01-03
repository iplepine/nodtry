import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../models/plan_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/quiet_header.dart';
import '../../../widgets/time_chip.dart';
import '../../../models/home_state.dart';
import 'now_tab_state.dart';
import '../../../routes/app_router.dart';
import '../../../utils/time_formatter.dart';
import 'now_tab_viewmodel.dart';
import 'now_tab_intent.dart';
import 'now_tab_fake_states.dart';

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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Primary Card 애니메이션: Fade + Scale
    _primaryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _primaryScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
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

  // 데이터 변경 감지 시 애니메이션 처리
  void _onDataLoaded() {
    if (mounted) {
      _animationController.forward(from: 0.0);
    }
  }

  Future<void> _handleDidIt() async {
    final primaryCard = ref.read(nowTabViewModelProvider).value?.primaryCard;
    if (primaryCard?.plan?.id == null) return;

    // 1. Shrink animation
    await _animationController.reverse();

    // 2. Dispatch Intent to ViewModel
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(CompletePlanIntent(primaryCard!.plan!.id!));
    } catch (e) {
      // Error handling (restore animation if failed)
      if (mounted) _animationController.forward();
    }
  }

  Future<void> _handleCheckIt() async {
    final managerCard = ref.read(nowTabViewModelProvider).value?.managerCard;
    // orElse: () => const HomeCardModel(state: HomeCardState.relaxedDay), removed as null check below covers
    // If we want a fallback or if managerCard is nullable, the null check below handles it.

    if (managerCard?.plan?.id == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('시작을 응원해요!'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Dispatch Intent
    await ref
        .read(nowTabViewModelProvider.notifier)
        .dispatch(CheckPartnerActionIntent(managerCard!.plan!.id!));
  }

  Future<void> _handleCheer() async {
    // TODO: 응원하기 API 호출. 현재는 확인하기와 동일하게 처리
    await _handleCheckIt();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.homeThankYou)),
      );
    }
  }

  Future<void> _handlePass() async {
    // TODO: 넘기기 API 호출
    ref.invalidate(nowTabViewModelProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nowActionPass)),
      );
    }
  }

  Future<void> _handleSkip() async {
    final primaryCard = ref.read(nowTabViewModelProvider).value?.primaryCard;
    if (primaryCard?.plan?.id == null) return;

    // 1. Shrink animation (optional, maybe fade out?)
    // For Skip, maybe just standard refresh or specific animation.
    // Let's reuse reverse animation for consistency.
    await _animationController.reverse();

    // 2. Dispatch Intent
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(SkipPlanIntent(primaryCard!.plan!.id!));
    } catch (e) {
      if (mounted) _animationController.forward();
    }
  }

  void _handleCreatePlan() {
    // 계획 생성 플로우 진입
    context.push(AppRoutes.planCreate);
  }

  /// Time Chip 텍스트 가져오기

  /// 정확한 시간 텍스트 가져오기 (롱 프레스용)
  String? _getExactTimeText(HomeCardModel model) {
    if (model.state == HomeCardState.overdue) {
      // 과거 미완료(Type 5)의 경우 정확한 시간보다는 상태가 중요하므로 null 반환 또는 별도 처리
      return null;
    }

    if (model.plan != null && model.plan!.items.isNotEmpty) {
      for (var item in model.plan!.items) {
        if (item.notificationTime != null &&
            item.notificationTime!.type != 'none') {
          final now = DateTime.now();
          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            item.notificationTime!.hour,
            item.notificationTime!.minute,
          );

          final exactTime = TimeFormatter.formatExactTime(scheduledTime);
          final diff = scheduledTime.difference(now);
          final absDiff = diff.abs();

          String suffix;
          if (diff.isNegative) {
            if (absDiff.inMinutes < 60) {
              suffix = '${absDiff.inMinutes}분 전 알림'; // "22:47 · 30분 전 알림"
            } else {
              suffix = '${absDiff.inHours}시간 전 알림';
            }
          } else {
            if (absDiff.inMinutes < 60) {
              suffix = '${absDiff.inMinutes}분 후 알림';
            } else {
              suffix = '${absDiff.inHours}시간 후 알림';
            }
          }

          return '$exactTime · $suffix';
        }
      }
    }
    return null;
  }

  /// Time Chip 텍스트 가져오기 (Vague Time 적용)
  String? _getTimeChipText(HomeCardModel model) {
    if (model.state == HomeCardState.overdue) {
      return '${AppLocalizations.of(context)!.pastUncompletedTimeChip} · ${AppLocalizations.of(context)!.timeChipPassed}';
      // "조금 전 · 지나갔어요" (기존 유지)
    }

    if (model.plan != null && model.plan!.items.isNotEmpty) {
      for (var item in model.plan!.items) {
        if (item.notificationTime != null &&
            item.notificationTime!.type != 'none') {
          final now = DateTime.now();
          // Use plan start date if it's in the future, otherwise assume today/relevant date
          // This is a simple heuristic for the 'Upcoming' debug scenario.
          // Ideally HomeCardModel should carry the target date.
          DateTime dateBase = now;
          if (model.plan != null && model.plan!.startDate.isAfter(now)) {
            dateBase = model.plan!.startDate;
          }

          final scheduledTime = DateTime(
            dateBase.year,
            dateBase.month,
            dateBase.day,
            item.notificationTime!.hour,
            item.notificationTime!.minute,
          );

          // Vague Time 적용
          final l10n = AppLocalizations.of(context)!;
          final vagueTime = TimeFormatter.formatForVagueTime(
            l10n,
            scheduledTime,
          );

          if (model.state == HomeCardState.nowAction) {
            // "점심쯤 · 아직 할 수 있어요" - Only show suffix if it is Today AND time has passed
            final isToday =
                dateBase.year == now.year &&
                dateBase.month == now.month &&
                dateBase.day == now.day;
            final isPast = now.isAfter(scheduledTime);

            if (isToday && isPast) {
              return '$vagueTime · ${l10n.timeChipStillActionable}';
            }
            return vagueTime;
          }
          return vagueTime; // "점심쯤"
        }
      }
    }
    return null;
  }

  /// Time Chip 타입 가져오기
  TimeChipType? _getTimeChipType(HomeCardModel model) {
    if (model.state == HomeCardState.overdue) {
      return TimeChipType.past;
    }

    final text = _getTimeChipText(model);
    if (text == null) return null;

    final l10n = AppLocalizations.of(context)!;
    if (text == l10n.timeChipNow) {
      return TimeChipType.now;
    } else if (text == l10n.timeChipJustNow) {
      return TimeChipType.past;
    } else if (text.contains('지남') || text == '어제' || text.endsWith('전')) {
      if (text.contains('지남') || text == '어제') return TimeChipType.past;
      if (text.contains('전')) return TimeChipType.upcoming;
      return TimeChipType.upcoming;
    } else {
      return TimeChipType.upcoming;
    }
  }

  /// Manager Quick Card용 Time Chip 텍스트
  String? _getManagerTimeChipText(HomeCardModel model) {
    return _getTimeChipText(model);
  }

  /// Manager Quick Card용 Time Chip 타입
  TimeChipType? _getManagerTimeChipType(HomeCardModel model) {
    return _getTimeChipType(model);
  }

  /// Secondary Executor Card용 Time Chip 텍스트
  String? _getSecondaryTimeChipText(HomeCardModel model) {
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
    final homeStateAsync = ref.watch(nowTabViewModelProvider);

    // 데이터 변경 감지하여 애니메이션 트리거
    ref.listen(nowTabViewModelProvider, (previous, next) {
      if (!next.hasValue) return;

      if (previous?.value == null) {
        _onDataLoaded();
        return;
      }

      final prevUiState = previous!.value!;
      final nextUiState = next.value!;

      // Manager Card 변경 여부 확인
      final managerChanged =
          prevUiState.managerCard?.plan?.id !=
          nextUiState.managerCard?.plan?.id;

      // Primary Card 변경 여부 확인
      final primaryChanged =
          prevUiState.primaryCard?.plan?.id !=
          nextUiState.primaryCard?.plan?.id;

      // 카드의 식별자가 변경되었을 때만 애니메이션 재시작
      if (managerChanged || primaryChanged) {
        _onDataLoaded();
      }
    });

    // 첫 진입 시에도 실행되도록 보장
    if (_animationController.status == AnimationStatus.dismissed &&
        homeStateAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onDataLoaded());
    }

    return homeStateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (NowTabState uiState) {
        // 상태 사용
        final primaryExecutorCard = uiState.primaryCard;
        final secondaryExecutorCards = uiState.secondaryCards;
        final managerQuickCard = uiState.managerCard;
        final managerPartnerName = managerQuickCard?.partnerName;

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
                                        begin: const Offset(
                                          0,
                                          0.15,
                                        ), // 시작/사라질 때 더 아래로
                                        end: Offset.zero, // 정상 위치
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
                                        onSkip: _handleSkip,
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
                                        exactTimeText: _getExactTimeText(
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
                                          ref
                                              .read(
                                                nowTabViewModelProvider
                                                    .notifier,
                                              )
                                              .dispatch(const RefreshIntent());
                                        },
                                        exactTimeText: _getExactTimeText(state),
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
                                    onCheer: _handleCheer, // Placeholder
                                    onPass: _handlePass, // Placeholder
                                    timeChipText: _getManagerTimeChipText(
                                      managerQuickCard,
                                    ),
                                    timeChipType: _getManagerTimeChipType(
                                      managerQuickCard,
                                    ),
                                    exactTimeText: _getExactTimeText(
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
            ),

            // Debug Fake State Toggle Button (Debug Only)
            if (kDebugMode)
              Positioned(
                bottom: 120, // Raised to avoid bottom nav overlap
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.bug_report, size: 20),
                  onPressed: () {
                    _showFakeStateSelector(context, ref);
                  },
                ),
              ),
          ],
        );
      },
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
                  children: NowTabFakeStates.all.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text(
                        'Primary: ${entry.value.primaryCard != null ? "O" : "X"}, '
                        'Secondary: ${entry.value.secondaryCards.length}, '
                        'Manager: ${entry.value.managerCard != null ? "O" : "X"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDisabled,
                        ),
                      ),
                      onTap: () {
                        ref
                            .read(nowTabViewModelProvider.notifier)
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
                    ref.invalidate(nowTabViewModelProvider);
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

class _PrimaryExecutorCard extends StatelessWidget {
  final HomeCardModel model;
  final VoidCallback? onDidIt;
  final VoidCallback? onSkip;
  final VoidCallback? onCreatePlan;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? recordGazeText;
  final String? exactTimeText;

  const _PrimaryExecutorCard({
    required this.model,
    this.onDidIt,
    this.onSkip,
    this.onCreatePlan,
    this.timeChipText,
    this.timeChipType,
    this.recordGazeText,
    this.exactTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withOpacity(0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timeChipText != null && timeChipType != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (exactTimeText != null)
                    Tooltip(
                      message: exactTimeText!,
                      triggerMode: TooltipTriggerMode.longPress,
                      child: TimeChip(text: timeChipText!, type: timeChipType!),
                    )
                  else
                    TimeChip(text: timeChipText!, type: timeChipType!),
                ],
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
            const SizedBox(height: 20),
            _buildButton(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, AppLocalizations l10n) {
    final title = model.plan?.items.firstOrNull?.title;
    final List<Widget> children = [];

    // Title (if applicable)
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

      // Description
      final description = model.plan?.items.firstOrNull?.description;
      if (description != null && description.isNotEmpty) {
        children.add(const SizedBox(height: 4));
        children.add(
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.left,
          ),
        );
      }
    }

    String? statusMessage = model.headerMessage;
    String? subMessage; // Added for Type 2-1, 2-2 A/B, etc.

    if (statusMessage == null) {
      switch (model.state) {
        case HomeCardState.nowAction: // Type 1: 지금 실천
          // statusMessage = l10n.homeNowTask; // Removed per user request
          break;
        case HomeCardState.overdue: // Type 5: 지난 실천
          // statusMessage = l10n.timePassedActorMessage; // Removed per user request
          // subMessage = l10n.timePassedActorSubMessage;
          break;
        case HomeCardState.emptyPlan: // Type 2-1: 계획 필요
          statusMessage = l10n.nowNoPlan;
          subMessage = l10n.nowNoPlanSubtitle;
          break;
        case HomeCardState.todayComplete: // Type 2-2 A: 오늘 완료
          statusMessage = l10n.nowTodayDone;
          // Sub-message for next promise can be handled via upcoming schedule if available
          break;
        case HomeCardState.todayEmpty: // Type 2-2 B: 여유로운 날
          statusMessage = l10n.nowQuietRest;
          break;
        case HomeCardState.nextAction: // Type 1-3: 다음 일정
          // Next Action usually uses headerMessage or defaults to nothing special
          break;
        default:
          break;
      }
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

    // Render Sub-message if exists (e.g. for Plan Needed)
    if (subMessage != null) {
      children.add(const SizedBox(height: 4));
      children.add(
        Text(
          subMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
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

    if (model.state == HomeCardState.nowAction) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (model.state == HomeCardState.overdue) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (model.state == HomeCardState.emptyPlan) {
      buttonText = l10n.nowCreatePlan;
      onPressed = onCreatePlan;
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: buttonTextColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
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
              buttonText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: buttonTextColor,
              ),
            ),
          ),
        ),
        if (model.state == HomeCardState.overdue && onSkip != null)
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 32),
              padding: const EdgeInsets.symmetric(vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.nowActionSkipToday,
              style: const TextStyle(
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
}

class _SecondaryExecutorCard extends StatelessWidget {
  final HomeCardModel model;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? exactTimeText;

  final VoidCallback? onReconcile;

  const _SecondaryExecutorCard({
    required this.model,
    this.timeChipText,
    this.timeChipType,
    this.onReconcile,
    this.exactTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Checked 상태인 경우 다른 레이아웃 적용
    if (model.state == HomeCardState.todayComplete) {
      return _buildCheckedCard(context, l10n);
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withOpacity(0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Fixed: Left alignment
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (model.partnerName != null) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        backgroundImage: model.partnerImageUrl != null
                            ? NetworkImage(model.partnerImageUrl!)
                            : null,
                        child: model.partnerImageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Removed _ReconcileMenu per user request
                  ],
                ),
                if (timeChipText != null && timeChipType != null) ...[
                  if (exactTimeText != null)
                    Tooltip(
                      message: exactTimeText!,
                      triggerMode: TooltipTriggerMode.longPress,
                      child: TimeChip(text: timeChipText!, type: timeChipType!),
                    )
                  else
                    TimeChip(text: timeChipText!, type: timeChipType!),
                ],
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

    // 긍정 메시지 중 하나 선택
    final messages = [
      l10n.nowLateCompletion,
      l10n.nowLateJustInTime,
      l10n.nowWithinToday,
    ];
    final message = messages[now.second % messages.length];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.nowStatusActuallyDone,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title.isNotEmpty ? title : '지나간 약속',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // 작은 말풍선 스타일 (Low Intensity)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                  topLeft: Radius.circular(2),
                ),
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
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

    // Title
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

      // Description
      final description = model.plan?.items.firstOrNull?.description;
      if (description != null && description.isNotEmpty) {
        children.add(const SizedBox(height: 4));
        children.add(
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.left,
          ),
        );
      }
    }

    String? statusMessage;
    // Secondary card doesn't usually use subMessage but for consistency can add if needed.
    // However, specs target mostly primary card.

    if (model.state == HomeCardState.partnerAction) {
      // "000님이 아침 약 챙겨먹기를... 했어요"
      // final action = ...
      // For now, simpler text construction
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '를\n'),
                // TODO: action type based suffix
                TextSpan(
                  text: l10n.nowPartnerDidIt,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Description
          if (model.plan?.items.firstOrNull?.description != null)
            Text(
              model.plan!.items.firstOrNull!.description!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
        ],
      );
    }

    switch (model.state) {
      case HomeCardState.partnerAction:
        statusMessage = '${l10n.homeChecked} · ${l10n.homeThankYou}';
        break;
      case HomeCardState.todayEmpty:
        statusMessage = l10n.nowQuietRest;
        break;
      case HomeCardState.overdue:
        // statusMessage = l10n.timePassedActorMessage;
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
  final VoidCallback? onCheer;
  final VoidCallback? onPass;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? exactTimeText;

  const _ManagerQuickCard({
    required this.model,
    this.partnerName,
    this.onCheckIt,
    this.onCheer,
    this.onPass,
    this.timeChipText,
    this.timeChipType,
    this.exactTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String headerText;
    if (model.state == HomeCardState.partnerAction) {
      headerText = l10n.nowPartnerDidIt;
    } else if (model.state == HomeCardState.partnerPlanCreate ||
        model.state == HomeCardState.partnerPlanModify) {
      // Type 3: "이런 약속을 제안했어요" or "약속을 조금 조정하고 있어요"
      // We can distinguish based on headerMessage if available or default to proposed
      // Or assuming default is proposed (Type 3-A)
      if (model.headerMessage == '조정 중' ||
          model.headerMessage == '같이 맞춰보는 중이에요') {
        // Example logic
        headerText = l10n.nowPartnerAdjusting;
      } else {
        headerText = l10n.nowPartnerProposed;
      }
    } else {
      headerText = model.headerMessage ?? l10n.homeReceivedMessage;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withOpacity(0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                if (partnerName != null) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    backgroundImage: model.partnerImageUrl != null
                        ? NetworkImage(model.partnerImageUrl!)
                        : null,
                    child: model.partnerImageUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    headerText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                if (timeChipText != null && timeChipType != null) ...[
                  const SizedBox(width: 8),
                  if (exactTimeText != null)
                    Tooltip(
                      message: exactTimeText!,
                      triggerMode: TooltipTriggerMode.longPress,
                      child: TimeChip(text: timeChipText!, type: timeChipType!),
                    )
                  else
                    TimeChip(text: timeChipText!, type: timeChipType!),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Title
            if (model.plan?.items.firstOrNull?.title != null) ...[
              SizedBox(
                width: double.infinity,
                child: Text(
                  model.plan!.items.firstOrNull!.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 4),
            ],
            // Scale & Period
            if (model.plan != null)
              _buildPlanDetails(context, model.plan!, l10n),
            const SizedBox(height: 8),
            // Description
            if (model.plan?.items.firstOrNull?.description != null) ...[
              SizedBox(
                width: double.infinity,
                child: Text(
                  model.plan!.items.firstOrNull!.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Button (Only for partnerActionShare/partnerPlanShare that needs action)
            if (model.state == HomeCardState.partnerPlanCreate ||
                model.state == HomeCardState.partnerPlanModify) ...[
              if (model.headerMessage != '함께하는 중') ...[
                const SizedBox(height: 20),
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
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (states) {
                              if (states.contains(WidgetState.pressed)) {
                                return AppColors.primaryPressed;
                              }
                              return null;
                            },
                          ),
                        ),
                    child: Text(
                      l10n.homeCheckIt,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ] else if (model.state == HomeCardState.partnerAction) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onCheckIt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.homeChecked,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onCheer, // TODO: Implement cheer logic
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.homeThankYou,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetails(
    BuildContext context,
    Plan plan,
    AppLocalizations l10n,
  ) {
    if (plan.items.isEmpty) return const SizedBox.shrink();
    final item = plan.items.first;

    // Period: 10.01 - 10.28
    final start = plan.startDate;
    final end = plan.endDate;
    final periodStr = '${start.month}.${start.day} - ${end.month}.${end.day}';

    // Days: Mon, Wed, Fri
    final daysStr = item.days.length == 7
        ? '매일' // TODO: l10n
        : item.days
              .map((d) => TimeFormatter.getWeekdayName(l10n, d))
              .join(', ');

    return SizedBox(
      width: double.infinity,
      child: Text(
        '$periodStr · $daysStr',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14, // Increased
        ),
        textAlign: TextAlign.left,
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

// _ReconcileMenu removed per user request (was unused after UI updates)
