import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';

/// 우리 탭 - 안전 기지 & 연결 허브
///
/// "나(Me)"와 "너(You)"의 관계를 관리하는 공간
class UsTab extends StatefulWidget {
  const UsTab({super.key});

  @override
  State<UsTab> createState() => _UsTabState();
}

class _UsTabState extends State<UsTab> {
  // TODO: 실제 데이터는 Provider/Repository에서 관리
  String? _name;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _name ?? l10n.usDefaultNameMe;

    // TODO: 실제 데이터 연동
    final connectedPeople = <_ConnectedPerson>[
      // 예시 데이터
      // _ConnectedPerson(name: "지민", isSupported: true, isCheering: false),
      // _ConnectedPerson(name: "현수", isSupported: true, isCheering: true),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // 하단 탭 공간 확보
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Me Section
              _MeSection(
                l10n: l10n,
                name: displayName,
                statusMessage: _statusMessage,
                onEditProfile: () => _showEditProfileDialog(
                  context,
                  displayName,
                  _statusMessage,
                ),
              ),

              const SizedBox(height: 48),

              // 2. You Section
              _YouSection(l10n: l10n, people: connectedPeople),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    String currentName,
    String? currentStatus,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    final TextEditingController statusController = TextEditingController(
      text: currentStatus,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          "프로필 편집", // TODO: L10n
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 프로필 사진 편집 (Placeholder)
            GestureDetector(
              onTap: () {
                // TODO: 이미지 피커 연동
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 이름 입력
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "이름", // TODO: L10n
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            // 상태 메시지 입력
            TextField(
              controller: statusController,
              decoration: InputDecoration(
                labelText: "상태 메시지", // TODO: L10n
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("취소", style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _name = nameController.text;
                _statusMessage = statusController.text.isEmpty
                    ? null
                    : statusController.text;
              });
              Navigator.pop(context);
            },
            child: Text("저장", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

/// 섹션 A: 나 (Me)
class _MeSection extends StatelessWidget {
  final AppLocalizations l10n;
  final String name;
  final String? statusMessage;
  final VoidCallback onEditProfile;

  const _MeSection({
    required this.l10n,
    required this.name,
    this.statusMessage,
    required this.onEditProfile,
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
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 프로필 카드
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 프로필 이미지
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
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onEditProfile,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  l10n.usProfileEdit,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        decoration: TextDecoration.underline,
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
                      "ABCD-1234", // TODO: 실제 코드
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                  ],
                ),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: "ABCD-1234"));

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.codeCopied)));
                },
              ),
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

/// 섹션 B: 너 (You)
class _YouSection extends StatelessWidget {
  final AppLocalizations l10n;
  final List<_ConnectedPerson> people;

  const _YouSection({required this.l10n, required this.people});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.usYouTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            // 새 연결 추가 버튼
            InkWell(
              onTap: () {
                // TODO: 초대 화면
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.add_circle,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (people.isEmpty)
          _buildEmptyState(context)
        else
          ...people.map((person) => _PersonCard(person: person, l10n: l10n)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
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
        ],
      ),
    );
  }
}

/// 관계 모델
class _ConnectedPerson {
  final String name;
  final bool isSupported; // 지지받는 중 (They manage Me)
  final bool isCheering; // 응원하는 중 (I manage Them)

  _ConnectedPerson({
    required this.name,
    required this.isSupported,
    required this.isCheering,
  });

  bool get isMutual => isSupported && isCheering;
}

/// 사람 카드
class _PersonCard extends StatelessWidget {
  final _ConnectedPerson person;
  final AppLocalizations l10n;

  const _PersonCard({required this.person, required this.l10n});

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
          onTap: () {
            // TODO: 상세 관계 화면 이동
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.secondary,
                  child: Text(
                    person.name[0],
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
                        person.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (person.isMutual)
                            _RelationshipBadge(
                              text: l10n.usBadgeMutual,
                              color: AppColors.primary,
                              textColor: Colors.white,
                            )
                          else ...[
                            if (person.isSupported)
                              _RelationshipBadge(
                                text: l10n.usBadgeSupported,
                                color: const Color(0xFFEBE6E1), // Warm Sand
                                textColor: AppColors.textSecondary,
                              ),
                            if (person.isCheering)
                              _RelationshipBadge(
                                text: l10n.usBadgeCheering,
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                textColor: AppColors.primary,
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textDisabled),
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
