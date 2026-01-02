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
import '../../../../widgets/plan/plan_card.dart';
import '../../../../providers/plan_list_provider.dart';
import '../us_state.dart';
import '../us_viewmodel.dart';

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
                                      onTap: () => ref
                                          .read(usViewModelProvider.notifier)
                                          .dispatch(
                                            const UsIntent.linkGoogle(),
                                          ),
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
                        ),
                        inviteCode: user?.inviteCode,
                      ),

                      if (user != null) ...[
                        const SizedBox(height: 24),
                        _ActivePlanListSection(
                          userId: user.uid,
                          title: "나의 약속", // TODO: L10n
                          isMe: true,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('${l10n.usLoadError}: $err'),
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

  void _showEditProfileDialog(
    BuildContext context,
    String currentName,
    String? currentStatus,
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
    ImageProvider? imageProvider;
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(profileImageUrl!);
    }

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
                color: Colors.black.withOpacity(0.03),
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
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      image: imageProvider != null
                          ? DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageProvider == null
                        ? Icon(Icons.person, size: 32, color: AppColors.primary)
                        : null,
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
                    title:
                        "${person.user.displayName ?? '전우'}님의 약속", // TODO: L10n
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
                                color: AppColors.primary.withOpacity(0.15),
                                textColor: AppColors.primary,
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.link_off, color: Colors.redAccent),
                  onPressed: onDisconnect,
                  tooltip: l10n.usDisconnectTooltip,
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
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _EditProfileDialogContent({
    required this.name,
    this.status,
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
        ).showSnackBar(SnackBar(content: Text('프로필 저장 실패: $e')));
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
      title: Text("프로필 편집", style: TextStyle(color: AppColors.textPrimary)),
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      image: _tempProfileImage != null
                          ? DecorationImage(
                              image: FileImage(_tempProfileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _tempProfileImage == null
                        ? Icon(Icons.person, size: 48, color: AppColors.primary)
                        : null,
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
              labelText: "이름",
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
              labelText: "상태 메시지",
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
            "취소",
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
            child: Text("저장", style: TextStyle(color: AppColors.primary)),
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
    final plansAsync = ref.watch(activePlansProvider(userId));
    // final l10n = AppLocalizations.of(context)!;

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
            if (isMe)
              InkWell(
                onTap: () => context.push(AppRoutes.planCreate),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.add_circle,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
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
                  color: AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Text(
                      isMe ? "아직 등록된 약속이 없어요" : "파트너가 진행 중인 약속이 없어요",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.planCreate),
                        child: Text("새 약속 만들기"),
                      ),
                    ],
                  ],
                ),
              );
            }
            return Column(
              children: plans
                  .map(
                    (plan) => PlanCard(
                      plan: plan,
                      onTap: () {
                        // TODO: Plan Detail
                      },
                    ),
                  )
                  .toList(),
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
}
