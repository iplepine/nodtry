import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../routes/app_router.dart';
import '../../../../theme/app_colors.dart';
import '../../application/invite_services.dart';
import '../../domain/invite_code.dart';
import 'invite_share_panel.dart';

/// The Now tab's invite card, shown only while there is no partner.
///
/// Before any invite went out it asks to send one; after that it says the
/// partner hasn't joined yet and offers "초대 다시 보내기". Either way there is
/// a link to enter a code received from the partner.
class NowInviteCard extends ConsumerStatefulWidget {
  const NowInviteCard({super.key});

  @override
  ConsumerState<NowInviteCard> createState() => _NowInviteCardState();
}

class _NowInviteCardState extends ConsumerState<NowInviteCard> {
  bool _sharing = false;

  Future<void> _share(BuildContext buttonContext) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await shareInviteWithFeedback(buttonContext, ref, surface: 'now_card');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partners = ref.watch(connectedProfilesProvider);
    // Only once we know there is no partner — never flash it for a couple
    // whose list is still loading or failed to load.
    if (!partners.hasValue || partners.hasError) return const SizedBox.shrink();
    if (partners.value!.isNotEmpty) return const SizedBox.shrink();
    final code = ref.watch(myProfileProvider).value?.inviteCode;
    if (code == null || code.isEmpty) return const SizedBox.shrink();

    DateTime? sharedAt;
    try {
      sharedAt = ref.watch(inviteSharedAtProvider);
    } catch (_) {
      sharedAt = null; // no SharedPreferences (tests)
    }
    final waiting = sharedAt != null;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      key: const ValueKey('now-invite-card'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(waiting ? '⏳' : '🤙', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      waiting
                          ? l10n.nowInviteCardWaitingTitle
                          : l10n.nowInviteCardTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      waiting
                          ? l10n.nowInviteCardWaitingBody
                          : l10n.nowInviteCardBody,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (buttonContext) => SizedBox(
              height: 46,
              child: FilledButton.icon(
                key: const ValueKey('now-invite-share'),
                onPressed: _sharing ? null : () => _share(buttonContext),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: Icon(
                  waiting ? Icons.refresh_rounded : Icons.chat_bubble_rounded,
                  size: 18,
                ),
                label: Text(
                  waiting ? l10n.nowInviteCardResend : l10n.connectShareInvite,
                ),
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('now-invite-enter-code'),
            onPressed: () => context.push(
              AppRoutes.connectEntry(source: InviteCodeSource.manual),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(l10n.enterInviteCode),
          ),
        ],
      ),
    );
  }
}
