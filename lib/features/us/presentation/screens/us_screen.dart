import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:nod_try/theme/app_colors.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../routes/app_router.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../models/connected_user.dart';
import '../../../../models/plan_model.dart';
import '../../../../widgets/app_underlined_text.dart';
import '../../../../widgets/plan/plan_card.dart';
import '../../../../providers/plan_list_provider.dart';
import '../us_state.dart';
import '../us_viewmodel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// 우리 탭 - 안전 기지 & 연결 허브
///
/// "나(Me)"와 "너(You)"의 관계를 관리하는 공간
class UsScreen extends ConsumerStatefulWidget {
  const UsScreen({super.key});

  @override
  ConsumerState<UsScreen> createState() => _UsScreenState();
}

class _UsScreenState extends ConsumerState<UsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usStateAsync = ref.watch(usViewModelProvider);

    // 에러 발생 시 다이얼로그 노출
    ref.listen(usViewModelProvider, (previous, next) {
      if (next.hasValue && next.value?.errorNotification != null) {
        showDialog(
          context: context,
          builder: (context) {
            final dl10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(dl10n.usNoticeTitle),
              content: Text(next.value!.errorNotification!),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(usViewModelProvider.notifier).clearError();
                  },
                  child: Text(dl10n.usOk),
                ),
              ],
            );
          },
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 100), // 하단 탭 공간 확보
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Me Section
              usStateAsync.when(
                data: (state) {
                  final user = state.myProfile;
                  return Column(
                    children: [
                      // 게스트 경고 메시지 (익명 유저인 경우)
                      if (user?.isAnonymous ?? false)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFF4E5,
                            ), // Soft Orange background
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD180)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFFF9800), // Orange
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.usGuestWarningMessage,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF5D4037),
                                            height: 1.4,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () =>
                                          _showLinkAccountOptionDialog(context),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Color(
                                                    0xFFE65100,
                                                  ), // Darker Orange
                                                  width: 1.0,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              l10n.usGuestWarningAction,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFFE65100,
                                                    ), // Darker Orange
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 12,
                                            color: Color(0xFFE65100),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      _MeSection(
                        l10n: l10n,
                        name: (user?.displayName?.isNotEmpty ?? false)
                            ? user!.displayName!
                            : l10n.usDefaultNameMe,
                        statusMessage: user?.statusMessage,
                        profileImageUrl: user?.profileImageUrl,
                        onEditProfile: () => _showEditProfileDialog(
                          context,
                          user?.displayName ?? l10n.usDefaultNameMe,
                          user?.statusMessage,
                          user?.profileImageUrl,
                        ),
                        inviteCode: user?.inviteCode,
                      ),

                      if (user != null) ...[
                        const SizedBox(height: 24),
                        _ActivePlanListSection(
                          userId: user.uid,
                          title: l10n.usMyPlanTitle,
                          isMe: true,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) {
                  // 만약 데이터가 이미 있다면 에러 메시지 대신 이전 데이터를 보여줌으로써 화면 깜빡임 방지
                  final previousUser = ref.read(myProfileProvider).value;
                  if (previousUser != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MeSection(
                          l10n: l10n,
                          name: (previousUser.displayName?.isNotEmpty ?? false)
                              ? previousUser.displayName!
                              : l10n.usDefaultNameMe,
                          statusMessage: previousUser.statusMessage,
                          profileImageUrl: previousUser.profileImageUrl,
                          onEditProfile: () => _showEditProfileDialog(
                            context,
                            previousUser.displayName ?? l10n.usDefaultNameMe,
                            previousUser.statusMessage,
                            previousUser.profileImageUrl,
                          ),
                          inviteCode: previousUser.inviteCode,
                        ),
                        const SizedBox(height: 24),
                        _ActivePlanListSection(
                          userId: previousUser.uid,
                          title: l10n.usMyPlanTitle,
                          isMe: true,
                        ),
                      ],
                    );
                  }
                  return Center(child: Text('${l10n.usLoadError}: $err'));
                },
              ),

              const SizedBox(height: 48),

              // 2. You Section
              usStateAsync.maybeWhen(
                data: (state) => _YouSection(
                  l10n: l10n,
                  connectedProfiles: state.connectedProfiles,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinkAccountOptionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.usGuestWarningAction,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ref
                        .read(usViewModelProvider.notifier)
                        .dispatch(const UsIntent.linkGoogle());
                  },
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: Text(l10n.loginWithGoogle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEmailLinkDialog(context, ref);
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: Text(l10n.usLinkEmailAction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEmailLinkDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.usLinkEmailTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.usLinkEmailContent),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: l10n.usEmailLabel,
                  hintText: l10n.emailHint,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return l10n.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: l10n.usPasswordLabel,
                  hintText: l10n.passwordHint,
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return l10n.weakPassword;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                ref
                    .read(usViewModelProvider.notifier)
                    .dispatch(
                      UsIntent.linkEmail(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.usLinkEmailSuccess)),
                );
              }
            },
            child: Text(l10n.usLinkConfirm),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    String currentName,
    String? currentStatus,
    String? currentImageUrl,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Removed unused controllers and variable

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return _EditProfileDialogContent(
            name: currentName,
            status: currentStatus,
            imageUrl: currentImageUrl,
            l10n: l10n,
            ref: ref,
          );
        },
      ),
    );
  }
}

/// 섹션 A: 나 (Me)
class _MeSection extends StatelessWidget {
  final AppLocalizations l10n;
  final String name;
  final String? statusMessage;
  final String? profileImageUrl;
  final String? inviteCode;
  final VoidCallback onEditProfile;

  const _MeSection({
    required this.l10n,
    required this.name,
    this.statusMessage,
    this.profileImageUrl,
    this.inviteCode,
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
              tooltip: l10n.settingsTitle, // "설정"
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
                    Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                  ],
                ),
                onTap: () {
                  if (inviteCode != null) {
                    Clipboard.setData(ClipboardData(text: inviteCode!));

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.codeCopied)));
                  }
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
class _YouSection extends ConsumerWidget {
  final AppLocalizations l10n;
  final List<ConnectedUser> connectedProfiles;

  const _YouSection({required this.l10n, required this.connectedProfiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          ...connectedProfiles.map(
            (person) => Column(
              children: [
                _PersonCard(
                  person: person,
                  l10n: l10n,
                  onDisconnect: () =>
                      _showDisconnectDialog(context, ref, person),
                ),
                // 파트너 계획 리스트 추가
                Padding(
                  padding: const EdgeInsets.only(left: 1, right: 1, bottom: 24),
                  child: _ActivePlanListSection(
                    userId: person.user.uid,
                    title: l10n.usPartnerPlanTitle(
                      person.user.displayName ?? l10n.usUnknownUser,
                    ),
                    isMe: false,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _showDisconnectDialog(
    BuildContext context,
    WidgetRef ref,
    ConnectedUser person,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.usDisconnectDialogTitle),
        content: Text(
          l10n.usDisconnectDialogContent(
            person.user.displayName ?? l10n.usUnknownUser,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.usDisconnectConfirm,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(disconnectConnectionUseCaseProvider)
            .execute(person.user.uid);
        // 목록 갱신 -> Stream이므로 자동 갱신되지만 connectedProfilesProvider는 FutureProvider라 invalidate 필요
        // 사실 ConnectRepository가 변경되면 Stream은 반응하지만, connectedProfiles는 FutureProvider라서...
        // Repository에서 status 변경을 감지하고 invalidate 해줘야 함?
        // 아니면 여기서 수동으로 invalidate.
        ref.invalidate(connectedProfilesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.usDisconnectSuccess)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.usDisconnectError(e.toString()))),
          );
        }
      }
    }
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
class _PersonCard extends StatelessWidget {
  final ConnectedUser person; // ConnectedUser 사용
  final AppLocalizations l10n;
  final VoidCallback onDisconnect;

  const _PersonCard({
    required this.person,
    required this.l10n,
    required this.onDisconnect,
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
          onTap: () {
            // TODO: 상세 관계 화면 이동?
          },
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
                      (person.user.displayName?.isNotEmpty ?? false)
                          ? person.user.displayName![0]
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
                        person.user.displayName ?? l10n.usNoName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
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

class _EditProfileDialogContent extends ConsumerStatefulWidget {
  final String name;
  final String? status;
  final String? imageUrl;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _EditProfileDialogContent({
    required this.name,
    this.status,
    this.imageUrl,
    required this.l10n,
    required this.ref,
  });

  @override
  ConsumerState<_EditProfileDialogContent> createState() =>
      _EditProfileDialogContentState();
}

class _EditProfileDialogContentState
    extends ConsumerState<_EditProfileDialogContent> {
  late TextEditingController _nameController;
  late TextEditingController _statusController;
  File? _tempProfileImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _statusController = TextEditingController(text: widget.status);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // 2. 이미지 선택
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,

          maxWidth: 512,
          maxHeight: 512,

          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: widget.l10n.usCropImageTitle,
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: widget.l10n.usCropImageTitle,
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _tempProfileImage = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      debugPrint('이미지 선택 에러: $e');
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updateUseCase = ref.read(updateProfileUseCaseProvider);
      await updateUseCase.execute(
        name: _nameController.text,
        statusMessage: _statusController.text.isEmpty
            ? null
            : _statusController.text,
        imagePath: _tempProfileImage?.path,
      );

      // Provider 새로고침 (Stream으로 자동 갱신되므로 불필요)
      // ref.invalidate(myProfileProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.l10n.usProfileSaveFailed(e.toString()))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: AppColors.surface,
      title: Text(widget.l10n.usEditProfile, style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 프로필 사진 편집
          Semantics(
            label: widget.l10n.usProfileEditImageLabel,
            button: true,
            child: GestureDetector(
              onTap: _isSaving ? null : _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  if (_tempProfileImage != null)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: FileImage(_tempProfileImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else if (widget.imageUrl != null &&
                      widget.imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      imageBuilder: (context, imageProvider) => Container(
                        width: 80,
                        height: 80,
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
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
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
                    )
                  else
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
          ),
          const SizedBox(height: 24),
          // 이름 입력
          TextField(
            controller: _nameController,
            enabled: !_isSaving,
            decoration: InputDecoration(
              labelText: widget.l10n.usNameLabel,
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
            controller: _statusController,
            enabled: !_isSaving,
            decoration: InputDecoration(
              labelText: widget.l10n.usStatusLabel,
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(
            widget.l10n.usCancel,
            style: TextStyle(
              color: _isSaving
                  ? AppColors.textDisabled
                  : AppColors.textSecondary,
            ),
          ),
        ),
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          TextButton(
            onPressed: _save,
            child: Text(widget.l10n.usSave, style: TextStyle(color: AppColors.primary)),
          ),
      ],
    );
  }
}

class _ActivePlanListSection extends ConsumerWidget {
  final String userId;
  final String title;
  final bool isMe;

  const _ActivePlanListSection({
    required this.userId,
    required this.title,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(activePlansProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      context.pushNamed('all-plans', extra: userId),
                  child: Text(
                    l10n.usSeeAll,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List
        plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? l10n.usEmptyMine : l10n.usEmptyPartner,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => context.push(AppRoutes.planCreate),
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ).copyWith(
                                overlayColor:
                                    WidgetStateProperty.resolveWith<Color?>((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.pressed,
                                      )) {
                                        return AppColors.primaryPressed;
                                      }
                                      return null;
                                    }),
                              ),
                          child: Text(
                            l10n.usCreatePlanShort,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }
            return Column(
              children: [
                ...plans.map(
                  (plan) => PlanCard(
                    plan: plan,
                    isOwner: isMe,
                    onTap: () {
                      context.pushNamed('plan-detail', extra: plan);
                    },
                    onEdit: isMe
                        ? () {
                            context.pushNamed('plan-create', extra: plan);
                          }
                        : null,
                    onDelete: isMe
                        ? () => _showDeletePlanDialog(context, ref, plan)
                        : null,
                  ),
                ),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.planCreate),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.5),
                          ),
                          color: AppColors.surface.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.usCreatePlan,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, stack) => Text('Error: $err'),
        ),
      ],
    );
  }

  void _showDeletePlanDialog(BuildContext context, WidgetRef ref, Plan plan) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.usDeletePlanTitle),
          content: Text(l10n.usDeletePlanBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.usCancel, style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close Dialog
                try {
                  if (plan.id != null) {
                    // 1. Cancel related alarms
                    await ref.read(settingAlarmUseCaseProvider).cancel(plan);

                    // 2. Delete plan from repository
                    await ref.read(recordRepositoryProvider).deletePlan(plan.id!);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.usPlanDeleted)),
                      );
                      // Refresh plans by invalidating the provider
                      ref.invalidate(activePlansProvider(userId));
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.usDeleteFailed(e.toString()))));
                  }
                }
              },
              child: Text(l10n.usDelete, style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }
}
