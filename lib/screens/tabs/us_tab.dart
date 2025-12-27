import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/quiet_header.dart';

/// 우리 탭 - 사람과 관계를 관리하는 공간
/// 
/// "지금 우리가 어떻게 연결돼 있는지"를 보여준다
class UsTab extends StatelessWidget {
  const UsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // TODO: 실제 데이터에서 연결된 사람 목록 가져오기
    final connectedPeople = <_ConnectedPerson>[];
    
    return Column(
      children: [
        // 헤더
        QuietHeader(
          partnerName: null, // TODO: 실제 데이터에서 가져오기
          periodState: HeaderPeriodState.noPlan, // TODO: 실제 상태 확인
          onSettingsTap: () {
            // TODO: 우리 탭의 설정 섹션으로 스크롤 또는 이동
          },
        ),
        
        // 내용
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                
                // 연결된 사람 목록
                if (connectedPeople.isEmpty)
                  _buildEmptyState(context, l10n)
                else ...[
                  Text(
                    l10n.usConnectedPeople,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...connectedPeople.map((person) => _PersonCard(person: person)),
                ],
                
                const SizedBox(height: 32),
                
                // 새 사람 초대 버튼
                PrimaryButton(
                  text: l10n.usInviteNew,
                  onPressed: () {
                    // TODO: 초대 화면으로 이동
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.usNoConnections,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 연결된 사람 데이터 모델 (임시)
class _ConnectedPerson {
  final String name;
  final bool isManaging; // true: 관리 중, false: 맡긴 중

  _ConnectedPerson({
    required this.name,
    required this.isManaging,
  });
}

/// 사람 카드
class _PersonCard extends StatelessWidget {
  final _ConnectedPerson person;

  const _PersonCard({required this.person});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 프로필 아이콘
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            // 이름과 상태
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    person.isManaging ? l10n.usManaging : l10n.usEntrusted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

