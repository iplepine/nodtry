import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/proof_photo.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/korean_particle.dart';
import '../../../utils/error_reporter.dart';
import '../../connect/application/partner_label_provider.dart';
import '../application/together_providers.dart';

/// "🤝 {애칭}랑 같이 했어" in the 했어 flow (photo preview / 사진 없이 했어),
/// default off. Shown only when the partner has a workout due today that
/// they haven't recorded ([togetherTargetProvider]); it tells [choice] what
/// it offers. Turning it on never records anything for the partner — they
/// are asked and decide themselves.
class TogetherToggle extends ConsumerWidget {
  const TogetherToggle({super.key, required this.planId, required this.choice});

  /// My plan being recorded.
  final String planId;
  final TogetherChoice choice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(togetherTargetProvider(planId));
    choice.offered = target;
    if (target == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final name = ref.watch(partnerLabelProvider).resolve(l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ValueListenableBuilder<bool>(
        valueListenable: choice,
        builder: (context, on, _) => Material(
          color: on ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: SwitchListTile.adaptive(
            key: const ValueKey('together-toggle'),
            value: on,
            onChanged: (value) => choice.value = value,
            activeTrackColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            title: Text(
              l10n.togetherToggleTitle(name, withJosa(name, '이랑/랑')),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              l10n.togetherToggleHint(name),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Now tab's "🤝 {애칭}가 같이 했대요 · [나도 했어]" cards: the partner's
/// "같이 했어" records waiting for me today ([togetherClaimsProvider]).
/// Nothing is logged until I tap 나도 했어.
class TogetherClaimCards extends ConsumerWidget {
  const TogetherClaimCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims = ref.watch(togetherClaimsProvider);
    if (claims.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final claim in claims)
          TogetherClaimCard(
            key: ValueKey('together-claim-${claim.sourceActionId}'),
            claim: claim,
          ),
      ],
    );
  }
}

class TogetherClaimCard extends ConsumerStatefulWidget {
  const TogetherClaimCard({super.key, required this.claim});

  final TogetherClaim claim;

  @override
  ConsumerState<TogetherClaimCard> createState() => _TogetherClaimCardState();
}

class _TogetherClaimCardState extends ConsumerState<TogetherClaimCard> {
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await confirmTogetherWithFeedback(
        context,
        ref,
        planId: widget.claim.myPlan.id!,
        sourceActionId: widget.claim.sourceActionId,
        surface: TogetherConfirmSurface.card,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = ref.watch(partnerLabelProvider).resolve(l10n);
    // The partner's photo of that record (it gets shared with mine).
    final hasPhoto =
        todayProofPhotoPathOf(
          widget.claim.sourcePlan,
          now: ref.watch(togetherClockProvider)(),
        ) !=
        null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.togetherClaimTitle(name, withJosa(name, '이/가')),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhoto
                      ? l10n.togetherClaimBodyWithPhoto
                      : l10n.togetherClaimBody,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const ValueKey('together-claim-confirm'),
            onPressed: _saving ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.togetherClaimConfirm,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          IconButton(
            key: const ValueKey('together-claim-dismiss'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: _saving
                ? null
                : () => ref
                      .read(togetherDismissedProvider.notifier)
                      .dismiss(widget.claim.sourceActionId),
          ),
        ],
      ),
    );
  }
}

/// 나도 했어 with a snackbar for the outcome (the card and the push's
/// button). Returns the outcome, or null when it failed.
Future<TogetherConfirmOutcome?> confirmTogetherWithFeedback(
  BuildContext context,
  WidgetRef ref, {
  required String planId,
  required String sourceActionId,
  required TogetherConfirmSurface surface,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final result = await confirmTogetherLog(
      ref,
      planId: planId,
      sourceActionId: sourceActionId,
      surface: surface,
    );
    final message = switch (result.outcome) {
      TogetherConfirmOutcome.logged =>
        result.queued ? l10n.nowRecordQueued : l10n.togetherConfirmedSnack,
      TogetherConfirmOutcome.alreadyLogged => l10n.togetherAlreadyLoggedSnack,
      TogetherConfirmOutcome.unavailable => l10n.togetherUnavailableSnack,
    };
    messenger?.showSnackBar(SnackBar(content: Text(message)));
    return result.outcome;
  } catch (e, s) {
    ErrorReporter.record(e, s, reason: 'togetherConfirmUi');
    messenger?.showSnackBar(SnackBar(content: Text(l10n.nowActionFailed)));
    return null;
  }
}
