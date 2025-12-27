import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../models/home_state.dart';

/// 홈 화면 - Today Card 기반 관계 중심 홈
/// 
/// OnMyBehalf의 유일한 중심 화면
/// "오늘, 우리 사이에 오고 가야 할 말이 있나?"에만 답한다
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: 실제 데이터에서 상태를 가져와야 함
  // 임시로 상태를 관리하는 변수
  HomeCardState _currentState = HomeCardState.quietDay;

  @override
  void initState() {
    super.initState();
    // TODO: 실제 데이터 로드
    _loadHomeState();
  }

  Future<void> _loadHomeState() async {
    // TODO: 실제 데이터에서 상태 계산
    // - 보고 필요 여부 확인
    // - 확인 필요 여부 확인
    // - 상태 우선순위 적용
    
    // 임시: 여러 상태가 가능한 경우 우선순위 적용 예시
    final possibleStates = <HomeCardState>[];
    
    // TODO: 실제 로직으로 교체
    // if (hasReportNeeded) possibleStates.add(HomeCardState.reportNeeded);
    // if (hasCheckNeeded) possibleStates.add(HomeCardState.checkNeeded);
    // ...
    
    // 우선순위가 가장 높은 상태 선택
    final selectedState = possibleStates.isEmpty
        ? HomeCardState.quietDay
        : HomeCardStatePriority.selectHighestPriority(possibleStates);
    
    if (mounted) {
      setState(() {
        _currentState = selectedState;
      });
    }
  }

  void _handleDidIt() {
    // TODO: 수행 보고 생성 로직
    // 상태 전이: 상태 A → 상태 C
    setState(() {
      _currentState = HomeCardState.waitingForCheck;
    });
  }

  void _handleCheckIt() {
    // TODO: 확인/검증 화면으로 이동
    // Navigator.push(context, MaterialPageRoute(builder: (context) => VerificationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Today Card
                _TodayCard(
                  state: _currentState,
                  onDidIt: _handleDidIt,
                  onCheckIt: _handleCheckIt,
                ),
                
                const SizedBox(height: 24),
                
                // 보조 정보 (Context Footer)
                _ContextFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Today Card 위젯
class _TodayCard extends StatelessWidget {
  final HomeCardState state;
  final VoidCallback? onDidIt;
  final VoidCallback? onCheckIt;

  const _TodayCard({
    required this.state,
    this.onDidIt,
    this.onCheckIt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 메시지 영역
            _buildMessage(context, l10n),
            
            // 버튼 영역 (있는 경우만)
            if (_hasButton()) ...[
              const SizedBox(height: 24),
              _buildButton(context, l10n),
            ],
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
      case HomeCardState.checkNeeded:
        message = l10n.homeReceivedMessage;
        break;
      case HomeCardState.waitingForCheck:
        message = '${l10n.homeSentWaiting}\n${l10n.homeWaitingForCheck}';
        break;
      case HomeCardState.quietDay:
        message = l10n.homeQuietDay;
        break;
      case HomeCardState.checked:
        message = '${l10n.homeChecked}\n${l10n.homeThankYou}';
        break;
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

  bool _hasButton() {
    return state == HomeCardState.reportNeeded ||
        state == HomeCardState.checkNeeded;
  }

  Widget _buildButton(BuildContext context, AppLocalizations l10n) {
    if (state == HomeCardState.reportNeeded) {
      return PrimaryButton(
        text: l10n.homeDidIt,
        onPressed: onDidIt,
      );
    } else if (state == HomeCardState.checkNeeded) {
      return PrimaryButton(
        text: l10n.homeCheckIt,
        onPressed: onCheckIt,
      );
    }
    
    return const SizedBox.shrink();
  }
}

/// 보조 정보 (Context Footer)
/// 행동을 유도하지 않는 정보만 노출
class _ContextFooter extends StatelessWidget {
  const _ContextFooter();

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 데이터에서 가져오기
    // 임시로 예시 정보 표시
    final contextInfo = <String>[];
    
    // TODO: 실제 로직으로 교체
    // if (hasActivePlan) {
    //   contextInfo.add(l10n.homeContextWeek(week, totalWeeks));
    // }
    // if (hasEntrustedPlan) {
    //   contextInfo.add(l10n.homeContextEntrusted(partnerName));
    // }
    // if (hasManagingPlan) {
    //   contextInfo.add(l10n.homeContextManaging(managedName));
    // }
    
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

