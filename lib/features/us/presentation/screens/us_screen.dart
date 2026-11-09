import 'package:flutter/material.dart';
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
import '../../../../utils/error_reporter.dart';
import '../../../../widgets/app_underlined_text.dart';
import '../../../../widgets/plan/plan_card.dart';
import '../../../../providers/plan_list_provider.dart';
import '../us_state.dart';
import '../us_viewmodel.dart';
import '../widgets/disconnect_partner_dialog.dart';
import '../../../connect/application/partner_label_provider.dart';
import '../../../duo/application/duo_stats_provider.dart';
import '../../../duo/presentation/duo_share_card.dart';
import '../../../duo/presentation/duo_widgets.dart';
import '../../../connect/presentation/widgets/invite_share_panel.dart';
import '../../../connect/presentation/widgets/partner_nickname_sheet.dart';
import '../../../../core/legal_links.dart';
import '../../../proof/domain/proof_labels.dart' show kSupportEmail;
import '../../../../utils/ui_error_codes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

part 'us_parts/us_me_section.dart';
part 'us_parts/us_you_section.dart';
part 'us_parts/us_edit_profile_dialog.dart';
part 'us_parts/us_active_plan_list.dart';
part 'us_parts/us_hero_card.dart';

/// Maps a locale-independent account-link error code to a localized message.
String _accountLinkErrorText(AppLocalizations l10n, String code) {
  switch (code) {
    case AccountLinkErrorCode.alreadyInUse:
      return l10n.accountLinkErrorAlreadyInUse;
    case AccountLinkErrorCode.invalidCredential:
      return l10n.accountLinkErrorInvalidCredential;
    case AccountLinkErrorCode.notAllowed:
      return l10n.accountLinkErrorNotAllowed;
    case AccountLinkErrorCode.generic:
    default:
      return l10n.accountLinkErrorGeneric;
  }
}

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
              content: Text(
                _accountLinkErrorText(dl10n, next.value!.errorNotification!),
              ),
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
              // 0. Us Hero (파트너 연결됨일 때만) — 공동 정체성 시각화
              usStateAsync.maybeWhen(
                data: (state) {
                  final partner = state.connectedProfiles.isNotEmpty
                      ? state.connectedProfiles.first.user
                      : null;
                  final me = state.myProfile;
                  if (partner == null || me == null) {
                    return const SizedBox.shrink();
                  }
                  return _UsHeroCard(
                    myName: (me.displayName?.isNotEmpty ?? false)
                        ? me.displayName!
                        : l10n.usDefaultNameMe,
                    myImageUrl: me.profileImageUrl,
                    partnerName: ref.watch(partnerLabelProvider).resolve(l10n),
                    partnerImageUrl: partner.profileImageUrl,
                    stats: ref.watch(duoStatsProvider),
                    l10n: l10n,
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

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
                            color: AppColors.noticeBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.noticeBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warningBorder,
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
                                            color: AppColors.noticeText,
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
                                          Flexible(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color:
                                                        AppColors.warningStrong,
                                                    width: 1.0,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                l10n.usGuestWarningAction,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .warningStrong,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 12,
                                            color: AppColors.warningStrong,
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
                        onCopyInviteCode: () =>
                            copyInviteWithFeedback(context, ref, surface: 'us'),
                        hasConnectedPartner: state.connectedProfiles.isNotEmpty,
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
                          onCopyInviteCode: () => copyInviteWithFeedback(
                            context,
                            ref,
                            surface: 'us',
                          ),
                          // 에러 fallback 경로 — 가능하면 마지막으로 알려진 connectedProfiles 사용.
                          hasConnectedPartner:
                              ref
                                  .read(usViewModelProvider)
                                  .value
                                  ?.connectedProfiles
                                  .isNotEmpty ??
                              false,
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
    final messenger = ScaffoldMessenger.of(context);
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              // Close before awaiting: a failure makes the view model publish an
              // errorNotification, and the screen's listener stacks an error
              // dialog on top of this one — popping afterwards would close that.
              Navigator.pop(dialogContext);
              final notifier = ref.read(usViewModelProvider.notifier);
              // An error dialog dismissed by tapping the barrier leaves the old
              // notification set; drop it so the check below sees this attempt.
              notifier.clearError();
              await notifier.dispatch(
                UsIntent.linkEmail(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                ),
              );
              // dispatch reports link failures as state, never by throwing, so
              // the outcome has to be read back before claiming success.
              final failed =
                  ref.read(usViewModelProvider).value?.errorNotification !=
                  null;
              if (!failed) {
                messenger.showSnackBar(
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
