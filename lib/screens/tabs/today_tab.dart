import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/quiet_header.dart';
import '../../models/home_state.dart';

/// 오늘 탭 - Today Card 기반 관계 중심 홈
/// 
/// "오늘, 우리 사이에 오고 가야 할 말이 있나?"에만 답한다
class TodayTab extends StatefulWidget {
  const TodayTab({super.key});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab>
    with SingleTickerProviderStateMixin {
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
    _primaryFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _primaryScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Secondary Card 애니메이션: Fade
    _secondaryFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Manager Card 애니메이션: Fade
    _managerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadHomeState();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeState() async {
    // TODO: 실제 데이터에서 상태 계산
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
      
      // 테스트 시나리오 5: 조용한 하루
      // HomeCardState.quietDay,
    ];
    
    // Step 1: Primary Executor Card 선택
    final primaryExecutorCard = HomeCardStatePriority.selectPrimaryExecutorCard(possibleStates);
    
    // Step 2: Secondary Executor Cards 선택 (최대 3개)
    final secondaryExecutorCards = HomeCardStatePriority.selectSecondaryExecutorCards(
      possibleStates,
      primaryExecutorCard,
    );
    
    // Step 3: Manager Quick Card 선택
    final managerQuickCard = HomeCardStatePriority.selectManagerQuickCard(possibleStates);
    
    // TODO: 실제 데이터에서 관리 대상 이름 가져오기
    // 임시: 테스트용 이름
    final managerPartnerName = managerQuickCard != null ? '민지' : null;
    
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
    // TODO: 계획 생성 플로우 진입
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 헤더
        QuietHeader(
          partnerName: null, // TODO: 실제 데이터에서 가져오기
          periodState: HeaderPeriodState.noPlan, // TODO: 실제 상태 확인
          onSettingsTap: () {
            // TODO: 우리 탭으로 이동
          },
        ),
        
        // Today Card
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 80, // 하단 탭 높이 + 안전 영역
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Secondary Executor Cards (작은 카드, 0~3개)
                  if (_secondaryExecutorCards.isNotEmpty) ...[
                    ..._secondaryExecutorCards.map((state) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FadeTransition(
                        opacity: _secondaryFadeAnimation,
                        child: _SecondaryExecutorCard(state: state),
                      ),
                    )),
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

  const _PrimaryExecutorCard({
    required this.state,
    this.onDidIt,
    this.onCreatePlan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      elevation: 1,
      color: AppColors.surface, // Theme A: Soft Dark Stone (#DFD9D4)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildMessage(context, l10n),
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
        message = l10n.homeTodayTask;
        break;
      case HomeCardState.planNeeded:
        message = l10n.todayNoPlan;
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
      buttonText = l10n.todayCreatePlan;
      onPressed = onCreatePlan;
    } else {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Theme A: Velvet Wine Plum
          foregroundColor: buttonTextColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.primaryPressed; // Theme A: Deep Velvet Wine
              }
              return null;
            },
          ),
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

  const _SecondaryExecutorCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      elevation: 0,
      color: AppColors.surface.withValues(alpha: 0.7), // Theme A: Soft Dark Stone (Opacity 0.7)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: _buildMessage(context, l10n),
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
        message = l10n.homeQuietDay;
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

  const _ManagerQuickCard({
    required this.state,
    this.partnerName,
    this.onCheckIt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      elevation: 0,
      color: AppColors.surface.withValues(alpha: 0.6), // Theme A: Soft Dark Stone (Opacity 0.6, 실천자보다 약함)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // 프로필 아이콘과 메시지 (가로 배치)
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
              ],
            ),
            const SizedBox(height: 12),
            // 작은 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                      onPressed: onCheckIt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // Theme A: Velvet Wine Plum
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return AppColors.primaryPressed; // Theme A: Deep Velvet Wine
                            }
                            return null;
                          },
                        ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }
}

