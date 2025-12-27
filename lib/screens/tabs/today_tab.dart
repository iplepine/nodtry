import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../models/home_state.dart';

/// 오늘 탭 - Today Card 기반 관계 중심 홈
/// 
/// "오늘, 우리 사이에 오고 가야 할 말이 있나?"에만 답한다
class TodayTab extends StatefulWidget {
  const TodayTab({super.key});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  // TODO: 실제 데이터에서 상태를 가져와야 함
  HomeCardState _currentState = HomeCardState.quietDay;

  @override
  void initState() {
    super.initState();
    _loadHomeState();
  }

  Future<void> _loadHomeState() async {
    // TODO: 실제 데이터에서 상태 계산
    final possibleStates = <HomeCardState>[];
    
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
    setState(() {
      _currentState = HomeCardState.waitingForCheck;
    });
  }

  void _handleCheckIt() {
    // TODO: 확인/검증 화면으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            _buildMessage(context, l10n),
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

