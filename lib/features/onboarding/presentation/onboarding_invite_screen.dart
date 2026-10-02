import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/repository_provider.dart';
import '../../../routes/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_underlined_text.dart';
import '../../connect/domain/invite_code.dart';
import '../../connect/presentation/widgets/invite_share_panel.dart';
import '../domain/onboarding_gate.dart';
import 'post_login_clipboard.dart';

/// The invite step right after a new user signs in without a partner
/// (spec §4.1): send the invite now, enter a code you got, or
/// "나중에 초대할게요". Any of them — or the partner turning up — ends the
/// step for good.
class OnboardingInviteScreen extends ConsumerStatefulWidget {
  const OnboardingInviteScreen({super.key});

  @override
  ConsumerState<OnboardingInviteScreen> createState() =>
      _OnboardingInviteScreenState();
}

class _OnboardingInviteScreenState
    extends ConsumerState<OnboardingInviteScreen> {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // An invitee who skipped the tutorial link but copied the message.
      runPostLoginClipboardCheck(context, ref);
    });
  }

  Future<void> _finish() async {
    if (_leaving) return;
    _leaving = true;
    await ref.read(onboardingStoreProvider).markInviteStepDone();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Already linked (the partner entered my code meanwhile, or I entered
    // theirs on the code screen pushed above this one): the step is done.
    // Leave only while this route is on top, so the connect screen's success
    // state isn't yanked away.
    final hasPartner =
        ref.watch(connectedProfilesProvider).value?.isNotEmpty ?? false;
    if (hasPartner) {
      final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (isCurrent) {
          _finish();
        } else {
          ref.read(onboardingStoreProvider).markInviteStepDone();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🤙', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.connectHeadline,
                key: const ValueKey('onboarding-invite-title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.connectSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              InviteSharePanel(surface: 'onboarding', onShared: _finish),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  key: const ValueKey('onboarding-have-code'),
                  onPressed: () => context.push(
                    AppRoutes.connectEntry(source: InviteCodeSource.manual),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text(
                    l10n.inviteHaveCodeLink,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  key: const ValueKey('onboarding-invite-later'),
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: AppUnderlinedText(
                    l10n.onboardingInviteLater,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
