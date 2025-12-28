import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/quiet_header.dart';
import '../../widgets/time_chip.dart';
import '../../widgets/plan_rail.dart';
import '../../models/home_state.dart';
import '../../utils/time_formatter.dart';
import '../../routes/app_router.dart';

/// 지금 탭 - Now Card 기반 관계 중심 홈
///
/// "지금 이 순간, 가장 먼저 신경 써야 할 건 무엇인가?"에 답한다
class NowTab extends StatefulWidget {
  const NowTab({super.key});

  @override
  State<NowTab> createState() => _NowTabState();
}

class _NowTabState extends State<NowTab> with SingleTickerProviderStateMixin {
  // TODO: 실제 데이터에서 상태를 가져와야 함
  // 실천자 영역
  HomeCardState? _primaryExecutorCard;
  List<HomeCardState> _secondaryExecutorCards = [];

  // 관리자 영역
  HomeCardState? _managerQuickCard;
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

    _loadHomeState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeState() async {
    // TODO: 실제 데이터에서 상태 계산
    // 스펙: '지금' 탭 카드 시간 선택 규칙
    // 1. 오늘 미완료 실천 행동
    // 2. 오늘 확인이 필요한 관리자 행동
    // 3. 오늘이 모두 완료된 경우, 가장 가까운 미래 행동 (D-1, D-2, 시간 단위)
    // 4. 아무 행동도 없을 경우 Quiet 상태

    // 임시 테스트 데이터 - 여러 상태를 시뮬레이션
    final possibleStates = <HomeCardState>[
      // 테스트 시나리오 1: 실천자 보고 필요 + 관리자 확인 필요 + 대기 중
      HomeCardState.reportNeeded, // Primary Executor Card
      HomeCardState.checkNeeded, // Manager Quick Card
      HomeCardState.waitingForCheck, // Secondary Executor Card
      HomeCardState.checked, // Secondary Executor Card
      // 테스트 시나리오 2: 관리자 확인 필요만
      // HomeCardState.checkNeeded,

      // 테스트 시나리오 3: 실천자 보고 필요만
      // HomeCardState.reportNeeded,
      // HomeCardState.checked,

      // 테스트 시나리오 4: 계획 없음
      // HomeCardState.planNeeded,

      // 테스트 시나리오 5: 조용한 하루 (스펙: 모든 조건 만족 시에만 표시)
      // HomeCardState.quietDay,
    ];

    // TODO: 실제 데이터에서 미래 행동 확인
    // - 오늘이 모두 완료된 경우, 가장 가까운 미래 행동 계산
    // - 시간 표현: D-1, D-2 또는 "3시간 남음" 형식

    // Step 1: Primary Executor Card 선택
    final primaryExecutorCard = HomeCardStatePriority.selectPrimaryExecutorCard(
      possibleStates,
    );

    // Step 2: Secondary Executor Cards 선택 (최대 3개)
    final secondaryExecutorCards =
        HomeCardStatePriority.selectSecondaryExecutorCards(
          possibleStates,
          primaryExecutorCard,
        );

    // Step 3: Manager Quick Card 선택
    final managerQuickCard = HomeCardStatePriority.selectManagerQuickCard(
      possibleStates,
    );

    // TODO: 실제 데이터에서 관리 대상 이름 가져오기
    // 임시: 테스트용 이름
    final managerPartnerName = managerQuickCard != null ? '민지' : null;

    // 스펙: Quiet 상태는 아래 조건을 모두 만족할 때만 표시
    // - 미완료 실천 행동 없음
    // - 확인 필요 관리자 행동 없음
    // - 가까운 미래 행동도 없음
    // TODO: 실제 데이터로 Quiet 상태 조건 확인

    if (mounted) {
      setState(() {
        _primaryExecutorCard = primaryExecutorCard;
        _secondaryExecutorCards = secondaryExecutorCards;
        _managerQuickCard = managerQuickCard;
        _managerQuickCardPartnerName = managerPartnerName;
      });

      // 애니메이션 시작
      _animationController.forward();
    }
  }

  void _handleDidIt() {
    // TODO: 수행 보고 생성 로직
    // 상태 전이: reportNeeded → waitingForCheck
    setState(() {
      _primaryExecutorCard = null;
      _secondaryExecutorCards = [HomeCardState.waitingForCheck];
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
    // TODO: 실제 데이터에서 계획 상태 확인
    // 임시: planNeeded 상태면 noPlan, 아니면 activePlan
    if (_primaryExecutorCard == HomeCardState.planNeeded) {
      return PlanRailState.noPlan;
    }
    // TODO: pendingApproval 상태 확인
    return PlanRailState.activePlan;
  }

  /// Plan Rail 요약 텍스트 생성
  String? _getPlanSummary() {
    // TODO: 실제 데이터에서 계획 정보 가져오기
    // 예: "운동 · 주 3회 · 월/수/금"
    return '운동 · 주 3회 · 월/수/금';
  }

  /// Time Chip 텍스트 가져오기
  ///
  /// 스펙: 시간 표현은 상대적 표현만 사용
  /// - D-1, D-2 (미래)
  /// - 3시간 남음, 30분 남음 (미래)
  /// - 곧 (미래)
  /// - 3시간 전, 어제 (과거)
  String? _getTimeChipText(HomeCardState state) {
    // TODO: 실제 데이터에서 시간 정보 가져오기
    // 임시: 테스트용
    switch (state) {
      case HomeCardState.reportNeeded:
        // 오늘 미완료 실천 행동 → "지금"
        return '지금';
      case HomeCardState.planNeeded:
        // 계획 없음 → Time Chip 없음
        return null;
      case HomeCardState.waitingForCheck:
        // 확인 대기 중 → 과거 시간 표시 가능
        // TODO: 실제 보고 시간에서 경과 시간 계산
        // 예: "2시간 전"
        return null; // 임시로 null, 실제 데이터 연동 시 계산
      case HomeCardState.checked:
        // 확인 완료 → 과거 시간 표시 가능
        // TODO: 실제 확인 시간에서 경과 시간 계산
        // 예: "어제"
        return null; // 임시로 null, 실제 데이터 연동 시 계산
      default:
        return null;
    }
  }

  /// Time Chip 타입 가져오기
  TimeChipType? _getTimeChipType(HomeCardState state) {
    if (_getTimeChipText(state) == null) return null;

    final text = _getTimeChipText(state)!;
    if (text == '지금') {
      return TimeChipType.now;
    } else if (text == '곧') {
      return TimeChipType.soon;
    } else if (text.contains('전') || text == '어제' || text == '방금 전') {
      // 과거 시간 표현
      return TimeChipType.past;
    } else {
      // D-1, D-2, 3시간 남음 등 (미래)
      return TimeChipType.upcoming;
    }
  }

  /// Manager Quick Card용 Time Chip 텍스트
  String? _getManagerTimeChipText(HomeCardState state) {
    // TODO: 실제 데이터에서 시간 정보 가져오기
    // 관리자 카드는 확인이 필요한 상태이므로 "지금" 또는 시간 정보 표시
    if (state == HomeCardState.checkNeeded) {
      // 임시: 테스트용
      return '지금';
    }
    return null;
  }

  /// Manager Quick Card용 Time Chip 타입
  TimeChipType? _getManagerTimeChipType(HomeCardState state) {
    if (_getManagerTimeChipText(state) == null) return null;

    final text = _getManagerTimeChipText(state)!;
    if (text == '지금') {
      return TimeChipType.now;
    } else if (text == '곧') {
      return TimeChipType.soon;
    } else if (text.contains('전') || text == '어제' || text == '방금 전') {
      return TimeChipType.past;
    } else {
      return TimeChipType.upcoming;
    }
  }

  /// Secondary Executor Card용 Time Chip 텍스트
  ///
  /// 과거 시간 표현: "2시간 전", "어제" 등
  String? _getSecondaryTimeChipText(HomeCardState state) {
    // TODO: 실제 데이터에서 시간 정보 가져오기
    switch (state) {
      case HomeCardState.waitingForCheck:
        // 확인 대기 중 → 보고한 시간부터 경과 시간 표시
        // TODO: 실제 보고 시간에서 경과 시간 계산
        // 예: DateTime.now().difference(보고시간)을 TimeFormatter.formatTimePast()로 변환
        // 임시 테스트 데이터
        final pastDuration = const Duration(hours: 2);
        return TimeFormatter.formatTimePast(pastDuration);
      case HomeCardState.checked:
        // 확인 완료 → 확인된 시간부터 경과 시간 표시
        // TODO: 실제 확인 시간에서 경과 시간 계산
        // 임시 테스트 데이터
        final pastDuration = const Duration(days: 1);
        return TimeFormatter.formatTimePast(pastDuration);
      default:
        return null;
    }
  }

  /// Secondary Executor Card용 Time Chip 타입
  TimeChipType? _getSecondaryTimeChipType(HomeCardState state) {
    if (_getSecondaryTimeChipText(state) == null) return null;

    final text = _getSecondaryTimeChipText(state)!;
    if (text.contains('전') || text == '어제' || text == '방금 전') {
      return TimeChipType.past;
    } else {
      return TimeChipType.upcoming;
    }
  }

  /// 기록의 시선 텍스트 생성
  ///
  /// "이번 주 약속 중 2번째", "4주 중 2주차", "이미 3번은 했어요" 등
  /// 사실 전달형 표현으로 외부 시선 느낌 제공
  String? _getRecordGazeText(HomeCardState state) {
    final l10n = AppLocalizations.of(context)!;

    // TODO: 실제 데이터에서 가져오기
    // 임시 테스트 데이터
    switch (state) {
      case HomeCardState.reportNeeded:
        // 이번 주 약속 중 N번째
        final weekCount = 2; // TODO: 실제 데이터
        return l10n.recordGazeWeekCount(weekCount);
      case HomeCardState.planNeeded:
        // 계획이 없을 때는 기록의 시선 표시 안 함
        return null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 데이터에서 계획 상태 가져오기
    final planRailState = _getPlanRailState();
    final planSummary = _getPlanSummary();

    return Column(
      children: [
        // 헤더
        QuietHeader(
          partnerName: null, // TODO: 실제 데이터에서 가져오기
          periodState:
              HeaderPeriodState.inProgress, // 임시: 텍스트 숨김 (User Feedback)
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
                bottom:
                    MediaQuery.of(context).padding.bottom +
                    80, // 하단 탭 높이 + 안전 영역
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ============================================
                  // 실천자 영역 (Executor Area)
                  // ============================================

                  // Primary Executor Card (큰 카드, 1개)
                  if (_primaryExecutorCard != null) ...[
                    FadeTransition(
                      opacity: _primaryFadeAnimation,
                      child: ScaleTransition(
                        scale: _primaryScaleAnimation,
                        child: _PrimaryExecutorCard(
                          state: _primaryExecutorCard!,
                          onDidIt: _handleDidIt,
                          onCreatePlan: _handleCreatePlan,
                          timeChipText: _getTimeChipText(_primaryExecutorCard!),
                          timeChipType: _getTimeChipType(_primaryExecutorCard!),
                          recordGazeText: _getRecordGazeText(
                            _primaryExecutorCard!,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Plan Rail (고정 진입점) - Primary Card 아래
                  PlanRail(
                    state: planRailState,
                    planSummary: planSummary,
                    onNewPlanTap: _handleCreatePlan,
                  ),

                  // Secondary Executor Cards (작은 카드, 0~3개)
                  if (_secondaryExecutorCards.isNotEmpty) ...[
                    ..._secondaryExecutorCards.map(
                      (state) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FadeTransition(
                          opacity: _secondaryFadeAnimation,
                          child: _SecondaryExecutorCard(
                            state: state,
                            timeChipText: _getSecondaryTimeChipText(state),
                            timeChipType: _getSecondaryTimeChipType(state),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ============================================
                  // 관리자 영역 (Manager Area)
                  // ============================================

                  // Manager Quick Card (작은 카드, 버튼 있음)
                  if (_managerQuickCard != null) ...[
                    FadeTransition(
                      opacity: _managerFadeAnimation,
                      child: _ManagerQuickCard(
                        state: _managerQuickCard!,
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

                  // 보조 정보 (Context Footer)
                  _ContextFooter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary Executor Card 위젯 (큰 카드)
class _PrimaryExecutorCard extends StatelessWidget {
  final HomeCardState state;
  final VoidCallback? onDidIt;
  final VoidCallback? onCreatePlan;
  final String? timeChipText; // Time Chip 표시 텍스트 (예: "D-1", "3시간 남음")
  final TimeChipType? timeChipType; // Time Chip 타입
  final String? recordGazeText; // 기록의 시선 텍스트 (예: "이번 주 약속 중 2번째", "4주 중 2주차")

  const _PrimaryExecutorCard({
    required this.state,
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
      color: AppColors.surface.withValues(
        alpha: 0.7,
      ), // Theme A: Soft Dark Stone (Opacity 0.7)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Time Chip (카드 상단 우측)
            if (timeChipText != null && timeChipType != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [TimeChip(text: timeChipText!, type: timeChipType!)],
              ),
            if (timeChipText != null && timeChipType != null)
              const SizedBox(height: 12),
            _buildMessage(context, l10n),
            // 기록의 시선 (사실 전달)
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

    switch (state) {
      case HomeCardState.reportNeeded:
        message = l10n.homeNowTask;
        break;
      case HomeCardState.planNeeded:
        message = l10n.nowNoPlan;
        break;
      default:
        message = '';
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
    // Theme A: Primary (Velvet Wine Plum #552A3E)
    final buttonTextColor = Colors.white; // Primary 위에는 흰색 텍스트

    VoidCallback? onPressed;
    String buttonText;

    if (state == HomeCardState.reportNeeded) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (state == HomeCardState.planNeeded) {
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
              backgroundColor: AppColors.primary, // Theme A: Velvet Wine Plum
              foregroundColor: buttonTextColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.primaryPressed; // Theme A: Deep Velvet Wine
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

/// Secondary Executor Card 위젯 (작은 카드)
class _SecondaryExecutorCard extends StatelessWidget {
  final HomeCardState state;
  final String? timeChipText; // Time Chip 표시 텍스트 (예: "2시간 전", "어제")
  final TimeChipType? timeChipType; // Time Chip 타입

  const _SecondaryExecutorCard({
    required this.state,
    this.timeChipText,
    this.timeChipType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(
        alpha: 0.7,
      ), // Theme A: Soft Dark Stone (Opacity 0.7)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Time Chip (상단 우측)
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

    switch (state) {
      case HomeCardState.waitingForCheck:
        message = '${l10n.homeSentWaiting}\n${l10n.homeWaitingForCheck}';
        break;
      case HomeCardState.checked:
        message = '${l10n.homeChecked}\n${l10n.homeThankYou}';
        break;
      case HomeCardState.quietDay:
        // 스펙: Quiet 상태는 "지금은 잠시 쉬어도 돼요" 또는 "당분간 신경 쓸 일은 없어요"
        // TODO: 실제 데이터에 따라 적절한 메시지 선택
        message = l10n.nowQuietRest;
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

/// Manager Quick Card 위젯 (작은 카드, 버튼 있음)
class _ManagerQuickCard extends StatelessWidget {
  final HomeCardState state;
  final String? partnerName; // 관리 대상 이름
  final VoidCallback? onCheckIt;
  final String? timeChipText; // Time Chip 표시 텍스트
  final TimeChipType? timeChipType; // Time Chip 타입

  const _ManagerQuickCard({
    required this.state,
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
      color: AppColors.surface.withValues(
        alpha: 0.6,
      ), // Theme A: Soft Dark Stone (Opacity 0.6, 실천자보다 약함)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // 프로필 아이콘, 메시지, Time Chip (가로 배치)
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
                // Time Chip (우측 상단)
                if (timeChipText != null && timeChipType != null) ...[
                  const SizedBox(width: 8),
                  TimeChip(text: timeChipText!, type: timeChipType!),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // 작은 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCheckIt,
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary, // Theme A: Velvet Wine Plum
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
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return AppColors
                              .primaryPressed; // Theme A: Deep Velvet Wine
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

/// 보조 정보 (Context Footer)
class _ContextFooter extends StatelessWidget {
  const _ContextFooter();

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 데이터에서 가져오기
    final contextInfo = <String>[];

    if (contextInfo.isEmpty) {
      return const SizedBox.shrink();
    }

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
