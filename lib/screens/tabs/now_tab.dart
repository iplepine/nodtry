import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/quiet_header.dart';
import '../../widgets/time_chip.dart';
import '../../widgets/plan_rail.dart';
import '../../models/home_state.dart';
import '../../routes/app_router.dart';
import '../../providers/home_provider.dart';
import '../../utils/time_formatter.dart';

/// 지금 탭 - Now Card 기반 관계 중심 홈
class NowTab extends ConsumerStatefulWidget {
  const NowTab({super.key});

  @override
  ConsumerState<NowTab> createState() => _NowTabState();
}

class _NowTabState extends ConsumerState<NowTab>
    with SingleTickerProviderStateMixin {
  // 실천자 영역
  HomeCardModel? _primaryExecutorCard;
  List<HomeCardModel> _secondaryExecutorCards = [];

  // 관리자 영역
  HomeCardModel? _managerQuickCard;
  String? _managerQuickCardPartnerName; // 관리 대상 이름

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
  void _updateStateFromProvider(List<HomeCardModel> possibleModels) {
    // 리스트 복사
    final models = List<HomeCardModel>.from(possibleModels);

    // 실제 데이터가 없을 경우(신규 유저) planNeeded 상태 추가
    if (models.isEmpty) {
      models.add(const HomeCardModel(state: HomeCardState.planNeeded));
    }

    // Step 1: Primary Executor Card 선택
    final primaryExecutorCard = HomeCardStatePriority.selectPrimaryExecutorCard(
      models,
    );

    // Step 2: Secondary Executor Cards 선택 (최대 3개)
    final secondaryExecutorCards =
        HomeCardStatePriority.selectSecondaryExecutorCards(
          models,
          primaryExecutorCard,
        );

    // Step 3: Manager Quick Card 선택
    final managerQuickCard = HomeCardStatePriority.selectManagerQuickCard(
      models,
    );

    // TODO: 실제 데이터에서 관리 대상 이름 가져오기 (Model에 포함됨)
    final managerPartnerName = managerQuickCard?.partnerName;

    if (mounted) {
      setState(() {
        _primaryExecutorCard = primaryExecutorCard;
        _secondaryExecutorCards = secondaryExecutorCards;
        _managerQuickCard = managerQuickCard;
        _managerQuickCardPartnerName = managerPartnerName;
      });

      // 애니메이션 시작 (처음부터 다시 재생)
      _animationController.forward(from: 0.0);
    }
  }

  void _handleDidIt() {
    // TODO: 수행 보고 생성 로직
    // 상태 전이: reportNeeded → waitingForCheck
    setState(() {
      _primaryExecutorCard = null;
      _secondaryExecutorCards = [
        const HomeCardModel(state: HomeCardState.waitingForCheck),
      ];
    });
  }

  void _handleCheckIt() {
    // TODO: 확인/검증 화면으로 이동
  }

  void _handleCreatePlan() {
    // 계획 생성 플로우 진입
    context.push(AppRoutes.planCreate);
  }

  /// Plan Rail 상태 결정
  PlanRailState _getPlanRailState() {
    if (_primaryExecutorCard?.state == HomeCardState.planNeeded ||
        _primaryExecutorCard == null) {
      return PlanRailState.noPlan;
    }
    // TODO: pendingApproval 상태 확인
    return PlanRailState.activePlan;
  }

  /// Plan Rail 요약 텍스트 생성
  String? _getPlanSummary() {
    // TODO: 실제 데이터에서 계획 정보 가져오기
    return null;
  }

  /// Time Chip 텍스트 가져오기
  String? _getTimeChipText(HomeCardModel model) {
    if (model.state == HomeCardState.pastUncompleted) {
      return AppLocalizations.of(context)!.pastUncompletedTimeChip;
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
          return TimeFormatter.formatForTimeChip(scheduledTime);
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

    // 데이터 변경 감지하여 UI 업데이트
    ref.listen(homeCardStateProvider, (previous, next) {
      next.whenData((states) {
        _updateStateFromProvider(states);
      });
    });

    return homeStateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (states) {
        // 데이터가 로드되었을 때, 로컬 상태가 아직 초기화 안되었다면 업데이트
        if (_primaryExecutorCard == null) {
          // build 중 setState 방지를 위해 post frame callback 사용
          // 단, 무한 루프 방지 필요 (상태가 이미 설정되었는지 확인)
          // 여기서는 _primaryExecutorCard가 null일 때만 호출하므로 어느정도 안전
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateStateFromProvider(states);
          });
        }

        final planRailState = _getPlanRailState();
        final planSummary = _getPlanSummary();

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
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Executor Area
                      if (_primaryExecutorCard != null) ...[
                        FadeTransition(
                          opacity: _primaryFadeAnimation,
                          child: ScaleTransition(
                            scale: _primaryScaleAnimation,
                            child: _PrimaryExecutorCard(
                              model: _primaryExecutorCard!,
                              onDidIt: _handleDidIt,
                              onCreatePlan: _handleCreatePlan,
                              timeChipText: _getTimeChipText(
                                _primaryExecutorCard!,
                              ),
                              timeChipType: _getTimeChipType(
                                _primaryExecutorCard!,
                              ),
                              recordGazeText: _getRecordGazeText(
                                _primaryExecutorCard!,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Plan Rail
                      if (planRailState != PlanRailState.noPlan)
                        PlanRail(
                          state: planRailState,
                          planSummary: planSummary,
                          onNewPlanTap: _handleCreatePlan,
                        ),
                      // Secondary Executor Cards
                      if (_secondaryExecutorCards.isNotEmpty) ...[
                        ..._secondaryExecutorCards.map(
                          (state) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FadeTransition(
                              opacity: _secondaryFadeAnimation,
                              child: _SecondaryExecutorCard(
                                model: state,
                                timeChipText: _getSecondaryTimeChipText(state),
                                timeChipType: _getSecondaryTimeChipType(state),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Manager Area
                      if (_managerQuickCard != null) ...[
                        FadeTransition(
                          opacity: _managerFadeAnimation,
                          child: _ManagerQuickCard(
                            model: _managerQuickCard!,
                            partnerName: _managerQuickCardPartnerName,
                            onCheckIt: _handleCheckIt,
                            timeChipText: _getManagerTimeChipText(
                              _managerQuickCard!,
                            ),
                            timeChipType: _getManagerTimeChipType(
                              _managerQuickCard!,
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
          children: [
            if (timeChipText != null && timeChipType != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
                textAlign: TextAlign.center,
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
    String message;
    // model.plan 데이터가 있으면 사용
    if (model.plan != null && model.plan!.items.isNotEmpty) {
      message = model.plan!.items.first.title; // MVP: 첫 번째 아이템 타이틀
    } else {
      switch (model.state) {
        case HomeCardState.reportNeeded:
          message = l10n.homeNowTask;
          break;
        case HomeCardState.pastUncompleted:
          message = l10n.timePassedActorMessage;
          break;
        case HomeCardState.planNeeded:
          message = l10n.nowNoPlan;
          break;
        default:
          message = '';
      }
    }
    return Text(
      message,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
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

  const _SecondaryExecutorCard({
    required this.model,
    this.timeChipText,
    this.timeChipType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            if (timeChipText != null && timeChipType != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [TimeChip(text: timeChipText!, type: timeChipType!)],
              ),
            if (timeChipText != null && timeChipType != null)
              const SizedBox(height: 8),
            _buildMessage(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, AppLocalizations l10n) {
    String message;
    switch (model.state) {
      case HomeCardState.waitingForCheck:
        message = '${l10n.homeSentWaiting}\n${l10n.homeWaitingForCheck}';
        break;
      case HomeCardState.checked:
        message = '${l10n.homeChecked}\n${l10n.homeThankYou}';
        break;
      case HomeCardState.quietDay:
        message = l10n.nowQuietRest;
        break;
      case HomeCardState.pastUncompleted:
        message = l10n.pastUncompletedMessage;
        break;
      default:
        message = '';
    }
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
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
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.primary,
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
