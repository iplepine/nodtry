import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/terms_notice.dart';
import '../../../../core/services/notification_service.dart';
import '../../application/invite_services.dart';
import '../../application/kakao_invite_sharer.dart';
import '../../domain/invite_code.dart';
import 'kakao_invite_button.dart';

export '../../domain/invite_code.dart' show groupedInviteCode;

/// The global rect of the widget behind [context], for the iPad share
/// popover anchor.
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Sends my invite and shows the outcome as a snackbar: through the share
/// sheet, or with [viaKakao] as a KakaoTalk card (which itself falls back to
/// the share sheet when KakaoTalk can't take it). Returns true when the
/// invite went out.
Future<bool> shareInviteWithFeedback(
  BuildContext context,
  WidgetRef ref, {
  required String surface,
  bool viaKakao = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final origin = shareOriginOf(context);
  final result = viaKakao
      ? await shareMyInviteViaKakao(
          ref,
          l10n: l10n,
          surface: surface,
          origin: origin,
        )
      : await shareMyInvite(ref, l10n: l10n, surface: surface, origin: origin);
  if (result.shared) {
    final viaCard = result.channel == kInviteChannelKakaoCard;
    if (!viaCard) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.connectInviteSent)));
    }
    // Sending the invite agreed to the terms (shown under the button).
    try {
      await ref.read(userRepositoryProvider).markTermsAccepted();
    } catch (_) {}
    if (viaCard) {
      // KakaoTalk is in front: the snackbar and the permission prompt below
      // wait until the user is back here.
      try {
        await ref.read(kakaoInviteSharerProvider).backInApp();
      } catch (_) {}
      messenger?.showSnackBar(SnackBar(content: Text(l10n.connectInviteSent)));
    }
    // My partner's 연결됐어요 and their pushes need a token on this device.
    try {
      await ref
          .read(notificationServiceProvider)
          .requestPermissionAndRegister();
    } catch (_) {}
    return true;
  }
  if (identical(result, InviteShareResult.failed)) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.connectShareFailed)));
  }
  return false;
}

/// Copies my code and confirms with a snackbar.
Future<void> copyInviteWithFeedback(
  BuildContext context,
  WidgetRef ref, {
  required String surface,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (await copyMyInviteCode(ref, surface: surface)) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.codeCopied)));
  }
}

/// My code, big, with "카톡으로 초대 보내기" (system share sheet) and "코드 복사".
///
/// While KakaoTalk can take an invite card ([kakaoInviteAvailableProvider])
/// the main button is "카카오톡으로 초대 보내기" instead, and the share sheet
/// moves to a smaller "다른 앱으로 보내기" under it.
class InviteSharePanel extends ConsumerStatefulWidget {
  const InviteSharePanel({super.key, required this.surface, this.onShared});

  /// `invite_shared {surface}`: where this panel is.
  final String surface;

  /// Called after the invite went out (share sheet target picked).
  final VoidCallback? onShared;

  @override
  ConsumerState<InviteSharePanel> createState() => _InviteSharePanelState();
}

class _InviteSharePanelState extends ConsumerState<InviteSharePanel> {
  bool _sharing = false;
  bool _sharingViaKakao = false;

  Future<void> _share(
    BuildContext buttonContext, {
    bool viaKakao = false,
  }) async {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _sharingViaKakao = viaKakao;
    });
    try {
      final shared = await shareInviteWithFeedback(
        buttonContext,
        ref,
        surface: widget.surface,
        viaKakao: viaKakao,
      );
      if (shared) widget.onShared?.call();
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
          _sharingViaKakao = false;
        });
      }
    }
  }

  /// "다른 앱으로 보내기": the share sheet, one step down from the KakaoTalk
  /// button. Keeps the share button's key — it opens the same sheet.
  Widget _otherAppsButton(AppLocalizations l10n, String? code) {
    return Builder(
      builder: (buttonContext) => SizedBox(
        height: 44,
        child: OutlinedButton.icon(
          key: const ValueKey('invite-share-button'),
          onPressed: code == null || _sharing
              ? null
              : () => _share(buttonContext),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: _sharing && !_sharingViaKakao
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                )
              : const Icon(Icons.ios_share_rounded, size: 16),
          label: Text(l10n.inviteShareOtherApps),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final code = ref.watch(myProfileProvider).value?.inviteCode;
    final kakao = ref.watch(kakaoInviteAvailableProvider).value ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.usMyInviteCode,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: code,
            excludeSemantics: true,
            child: Text(
              code == null ? '—' : groupedInviteCode(code),
              key: const ValueKey('invite-my-code'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (kakao) ...[
            Builder(
              builder: (buttonContext) => KakaoInviteButton(
                key: const ValueKey('invite-kakao-button'),
                label: l10n.inviteKakaoButton,
                busy: _sharing && _sharingViaKakao,
                onPressed: code == null || _sharing
                    ? null
                    : () => _share(buttonContext, viaKakao: true),
              ),
            ),
            const SizedBox(height: 8),
            _otherAppsButton(l10n, code),
          ] else
            Builder(
              builder: (buttonContext) => SizedBox(
                height: 52,
                child: FilledButton.icon(
                  key: const ValueKey('invite-share-button'),
                  onPressed: code == null || _sharing
                      ? null
                      : () => _share(buttonContext),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: Text(l10n.connectShareInvite),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: TextButton.icon(
              key: const ValueKey('invite-copy-button'),
              onPressed: code == null
                  ? null
                  : () => copyInviteWithFeedback(
                      context,
                      ref,
                      surface: widget.surface,
                    ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(l10n.connectCopyCode),
            ),
          ),
          TermsNotice(text: l10n.termsNoticeInvite),
        ],
      ),
    );
  }
}
