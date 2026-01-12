import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

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
  final VoidCallback? onSettingsTap;

  const QuietHeader({
    super.key,
    this.partnerName,
    this.relationshipAlias,
    required this.periodState,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    // Edge-to-edge: 상태바 영역까지 확장
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: statusBarHeight + 12,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 좌측: 관계 정보
          Expanded(child: _buildRelationshipInfo(context)),

          // 우측: 설정 (있는 경우에만)
          if (onSettingsTap != null) _buildSettingsButton(context),
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

    // Only apply format if partnerName is provided (assuming relationshipAlias might be "Jimin" too, but safe to format)
    final l10n = AppLocalizations.of(context)!;
    final text = partnerName != null
        ? l10n.headerWithPartner(displayName)
        : displayName;

    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    if (onSettingsTap == null) {
      return const SizedBox(
        width: 20,
      ); // Maintain spacing/layout balance or shrink
    }

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
