import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Quiet Context Header
/// 
/// 안심용 맥락 표시줄
/// - 좌측: 관계 정보
/// - 중앙: 기간 정보
/// - 우측: 설정 진입
class QuietHeader extends StatelessWidget {
  final String? partnerName;
  final String? relationshipAlias;
  final HeaderPeriodState periodState;
  final int? currentWeek;
  final int? totalWeeks;
  final VoidCallback? onSettingsTap;

  const QuietHeader({
    super.key,
    this.partnerName,
    this.relationshipAlias,
    required this.periodState,
    this.currentWeek,
    this.totalWeeks,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    // Edge-to-edge: 상태바 영역까지 확장
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: statusBarHeight + 12,
        bottom: 12,
      ),
      child: Row(
        children: [
          // 좌측: 관계 정보
          Expanded(
            child: _buildRelationshipInfo(context),
          ),
          
          // 중앙: 기간 정보
          Expanded(
            child: _buildPeriodInfo(context),
          ),
          
          // 우측: 설정
          _buildSettingsButton(context),
        ],
      ),
    );
  }

  Widget _buildRelationshipInfo(BuildContext context) {
    // TODO: 실제 데이터에서 가져오기
    final displayName = partnerName ?? relationshipAlias ?? '';
    
    if (displayName.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Text(
      displayName,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPeriodInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    String periodText;
    
    switch (periodState) {
      case HeaderPeriodState.inProgress:
        if (currentWeek != null && totalWeeks != null) {
          periodText = l10n.headerWeekProgress(currentWeek!, totalWeeks!);
        } else {
          periodText = '';
        }
        break;
      case HeaderPeriodState.noPlan:
        periodText = l10n.headerNoPlan;
        break;
      case HeaderPeriodState.ended:
        periodText = l10n.headerPlanEnded;
        break;
    }
    
    if (periodText.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Center(
      child: Text(
        periodText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: onSettingsTap,
      child: Icon(
        Icons.settings_outlined,
        size: 20,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// 헤더 기간 상태
enum HeaderPeriodState {
  /// 진행 중
  inProgress,
  
  /// 계획 없음
  noPlan,
  
  /// 종료 직후
  ended,
}

