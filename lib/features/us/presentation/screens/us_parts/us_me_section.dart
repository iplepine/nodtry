part of '../us_screen.dart';

/// 섹션 A: 나 (Me)
class _MeSection extends StatelessWidget {
  final AppLocalizations l10n;
  final String name;
  final String? statusMessage;
  final String? profileImageUrl;
  final String? inviteCode;
  final VoidCallback onEditProfile;

  /// Copies the code (and logs `invite_shared {channel: copy}`).
  final VoidCallback onCopyInviteCode;

  /// 파트너가 이미 연결된 상태인지. 연결됨이면 초대 코드 행을 카드에서 숨김
  /// (페르소나 합의: 사용자가 더 안 쓸 정보가 큰 자리 차지하는 것 해소).
  final bool hasConnectedPartner;

  const _MeSection({
    required this.l10n,
    required this.name,
    this.statusMessage,
    this.profileImageUrl,
    this.inviteCode,
    required this.onEditProfile,
    required this.onCopyInviteCode,
    this.hasConnectedPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 타이틀
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.usMeTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () => context.push(AppRoutes.settings), // 설정 화면 이동
              icon: Icon(
                Icons.settings_outlined,
                color: AppColors.textSecondary,
              ),
              tooltip: l10n.settingsTitle, // "설정"
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 프로필 카드 — 그림자/border를 Promise 카드와 같은 호흡으로 통일.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 프로필 이미지
                  if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: profileImageUrl!,
                      imageBuilder: (context, imageProvider) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.surface,
                        highlightColor: Colors.white,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(width: 16),

                  // 이름 및 편집
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onEditProfile,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: AppUnderlinedText(
                                  l10n.usProfileEdit,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 상태 메시지 (간단 입력)
                        InkWell(
                          onTap: onEditProfile,
                          child: Text(
                            statusMessage ?? l10n.usStatusMessagePlaceholder,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: statusMessage == null
                                      ? AppColors.textDisabled
                                      : AppColors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 파트너 연결 안 됨 → 초대 코드를 큰 자리에 노출.
              // 연결됨 → 카드에서 빼서 인지 부하 줄임 (필요시 설정 안에).
              if (!hasConnectedPartner) ...[
                const SizedBox(height: 20),
                Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 16),
                _MeActionButton(
                  icon: Icons.qr_code,
                  label: l10n.usMyInviteCode,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        inviteCode ?? l10n.usNoInviteCode,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  onTap: () {
                    if (inviteCode != null) onCopyInviteCode();
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MeActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
            if (trailing == null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textDisabled,
              ),
          ],
        ),
      ),
    );
  }
}
