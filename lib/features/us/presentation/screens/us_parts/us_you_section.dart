part of '../us_screen.dart';

/// 섹션 B: 너 (You)
class _YouSection extends ConsumerWidget {
  final AppLocalizations l10n;
  final List<ConnectedUser> connectedProfiles;

  const _YouSection({required this.l10n, required this.connectedProfiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(partnerLabelProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.usYouTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 새 연결 추가 버튼 (헤더에서 제거)
            /*
            connectedAsync.when(
              data: (people) {
                if (people.isEmpty) return const SizedBox.shrink();
                return InkWell(
                  onTap: () {
                    context.push(AppRoutes.connect);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Semantics(
                    label: l10n.usAddConnectionLabel,
                    button: true,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            */
          ],
        ),
        const SizedBox(height: 20),

        if (connectedProfiles.isEmpty)
          _buildEmptyState(context)
        else
          ...connectedProfiles.map((person) {
            final isPartner = person.user.uid == label.partnerUid;
            final name =
                label.preferredFor(
                  person.user.uid,
                  displayName: person.user.displayName,
                ) ??
                l10n.usUnknownUser;
            return Column(
              children: [
                _PersonCard(
                  person: person,
                  l10n: l10n,
                  title: name,
                  // With a nickname, the real name stays visible underneath.
                  realName: isPartner && label.hasNickname
                      ? partnerDisplayNameOrNull(person.user.displayName)
                      : null,
                  hasNickname: isPartner && label.hasNickname,
                  onEditNickname: () => showPartnerNicknameSheet(context),
                  onDisconnect: () =>
                      _showDisconnectDialog(context, ref, person),
                  onReport: () => _reportPartner(context, ref, person),
                ),
                // 파트너 계획 리스트 추가
                Padding(
                  padding: const EdgeInsets.only(left: 1, right: 1, bottom: 24),
                  child: _ActivePlanListSection(
                    userId: person.user.uid,
                    title: l10n.usPartnerPlanTitle(name),
                    isMe: false,
                  ),
                ),
              ],
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _showDisconnectDialog(
    BuildContext context,
    WidgetRef ref,
    ConnectedUser person,
  ) async {
    await confirmAndDisconnectPartner(context, ref, person);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider,
          style: BorderStyle.none,
        ), // Border removed for softer look
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 48,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.usEmptyMatesTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.usEmptyMatesSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textDisabled),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // 초대하기 버튼
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.connect),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.send, size: 18),
            label: Text(
              l10n.usAddConnectionLabel, // "연결 추가" or "초대하기"
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// 사람 카드
/// A `mailto:` report about the partner to the support inbox, with their id
/// (nothing else personal). Disconnecting stays the way to block them.
Future<void> _reportPartner(
  BuildContext context,
  WidgetRef ref,
  ConnectedUser person,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = supportMailUri(
    subject: l10n.usReportPartnerSubject,
    body: l10n.usReportPartnerBody(person.user.uid),
  );
  final opened = await ref.read(externalLinkLauncherProvider)(uri);
  if (!opened) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.proofReportMailFailed(kSupportEmail))),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final ConnectedUser person; // ConnectedUser 사용
  final AppLocalizations l10n;

  /// What I call this person: nickname ?? display name ?? 짝꿍.
  final String title;

  /// The display name, shown under [title] when a nickname is set.
  final String? realName;
  final bool hasNickname;
  final VoidCallback onEditNickname;
  final VoidCallback onDisconnect;

  /// 짝꿍 신고하기: anything the partner sends (photos, notes, messages,
  /// promises) can be reported, not only a single photo.
  final VoidCallback onReport;

  const _PersonCard({
    required this.person,
    required this.l10n,
    required this.title,
    this.realName,
    required this.hasNickname,
    required this.onEditNickname,
    required this.onDisconnect,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('us-partner-card'),
          onTap: onEditNickname,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (person.user.profileImageUrl != null &&
                    person.user.profileImageUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: person.user.profileImageUrl!,
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      radius: 20,
                      backgroundImage: imageProvider,
                    ),
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppColors.surface,
                      highlightColor: Colors.white,
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.secondary,
                      child: Icon(Icons.person, color: AppColors.textPrimary),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      title.isNotEmpty
                          ? String.fromCharCode(title.runes.first)
                          : '?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (realName != null && realName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          realName!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (person.user.statusMessage != null &&
                          person.user.statusMessage!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          person.user.statusMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // A couple is one mutual pair. The one-way
                          // 지지받는 중 / 응원하는 중 badges framed the link as
                          // one person watching the other, so they are hidden.
                          if (person.isMutual)
                            _RelationshipBadge(
                              text: l10n.usBadgeMutual,
                              color: AppColors.primary,
                              textColor: Colors.white,
                            ),
                          InkWell(
                            key: const ValueKey('us-edit-nickname'),
                            onTap: onEditNickname,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 11,
                                    color: AppColors.primaryPressed,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    hasNickname
                                        ? l10n.usEditNickname
                                        : l10n.usSetNickname,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryPressed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 5명 페르소나 합의: destructive 액션이 카드에 직노출되면
                // 관계 화면의 첫인상이 "끊을 수 있다"로 프레이밍됨. 더보기 메뉴로 격리.
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.textDisabled,
                    size: 20,
                  ),
                  tooltip: l10n.usDisconnectTooltip,
                  position: PopupMenuPosition.under,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      key: const ValueKey('us-report-partner'),
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.usReportPartner),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.link_off,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.usDisconnectTooltip,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'disconnect') {
                      onDisconnect();
                    } else if (value == 'report') {
                      onReport();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelationshipBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _RelationshipBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
