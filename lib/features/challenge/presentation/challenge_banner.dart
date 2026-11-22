import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/plan_model.dart';
import '../../../providers/repository_provider.dart';
import '../../../routes/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/analytics.dart';
import '../../duo/presentation/duo_share_card.dart';
import '../application/challenge_providers.dart';
import 'challenge_labels.dart';

export 'challenge_labels.dart';

enum _JoinChoice { existing, newPlan }

/// The Now tab's banner for the current seasonal challenge.
///
/// - Announced: what it is and D-n to the first day.
/// - Running, not entered: [참여하기] — a new promise that runs to the last
///   day, or the running promise as it is.
/// - Running, entered: which day it is and the 둘운완 days so far.
/// - Over (entered only): the result, for a few days.
///
/// Everything except the entered, running banner can be closed.
class ChallengeBanner extends ConsumerStatefulWidget {
  const ChallengeBanner({super.key});

  @override
  ConsumerState<ChallengeBanner> createState() => _ChallengeBannerState();
}

class _ChallengeBannerState extends ConsumerState<ChallengeBanner> {
  static const double _artSize = 40;

  bool _busy = false;

  void _openCreate(DuoChallenge challenge) {
    context.push(AppRoutes.planCreate, extra: challenge);
  }

  Future<void> _join(ChallengeStatus status) async {
    if (_busy) return;
    final plan = status.enterablePlan;
    if (plan == null) {
      _openCreate(status.challenge);
      return;
    }
    final choice = await showModalBottomSheet<_JoinChoice>(
      context: context,
      useRootNavigator: true,
      // Content height, not the default 9/16 cap: the art plus two options
      // must fit on short screens and with large text.
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinSheet(status: status, plan: plan),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _JoinChoice.newPlan:
        _openCreate(status.challenge);
      case _JoinChoice.existing:
        await _enter(status, plan);
    }
  }

  /// Enters my running promise as it is.
  Future<void> _enter(ChallengeStatus status, Plan plan) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(recordRepositoryProvider)
          .setPlanChallenge(plan.id!, status.challenge.id);
      AnalyticsService.log(AnalyticsEvent.challengeJoined, {
        'challenge': status.challenge.id,
        'method': 'existing_plan',
        'day': status.dayNumber,
        'has_partner': status.hasPartner,
      });
      messenger?.showSnackBar(SnackBar(content: Text(l10n.challengeJoined)));
    } catch (e) {
      debugPrint('[ChallengeBanner] join failed: $e');
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.challengeJoinFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _dismiss(ChallengeStatus status) {
    AnalyticsService.log(AnalyticsEvent.challengeBannerDismissed, {
      'challenge': status.challenge.id,
      'phase': status.phase.name,
    });
    ref
        .read(challengeDismissalsProvider.notifier)
        .dismiss(status.challenge, status.phase);
  }

  @override
  Widget build(BuildContext context) {
    final ChallengeStatus? status;
    final Set<String> dismissed;
    try {
      status = ref.watch(challengeStatusProvider);
      dismissed = ref.watch(challengeDismissalsProvider);
    } catch (_) {
      // A banner is never worth breaking the Now tab for.
      return const SizedBox.shrink();
    }
    if (status == null) return const SizedBox.shrink();
    final phase = status.phase;
    if (phase == ChallengePhase.result && !status.joined) {
      return const SizedBox.shrink();
    }
    final enteredRunning = phase == ChallengePhase.running && status.joined;
    if (!enteredRunning &&
        dismissed.contains(
          ChallengeDismissalsNotifier.keyOf(status.challenge, phase),
        )) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final challenge = status.challenge;
    final headline = status.hasPartner
        ? l10n.recapHeadlineDuo(status.headlineDays)
        : l10n.recapHeadlineSolo(status.headlineDays);

    final String body;
    switch (phase) {
      case ChallengePhase.teaser:
        final from = challengeDateLabel(l10n, challenge.start);
        body = status.hasPartner
            ? l10n.challengeTeaserBody(from, challenge.totalDays)
            : l10n.challengeTeaserBodySolo(from, challenge.totalDays);
      case ChallengePhase.running:
        body = status.joined
            ? l10n.challengeProgress(status.dayNumber, challenge.totalDays)
            : l10n.challengeJoinBody(
                challengeDateLabel(l10n, challenge.end),
                status.daysLeft,
              );
      case ChallengePhase.result:
        body = l10n.challengeResultTitle;
      case ChallengePhase.none:
        return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('challenge-banner'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ChallengeArt(challenge: challenge, size: _artSize),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  challengeTitle(l10n, challenge),
                  key: const ValueKey('challenge-banner-title'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (phase == ChallengePhase.teaser)
                Container(
                  key: const ValueKey('challenge-banner-dday'),
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.challengeTeaserDday(status.daysUntilStart),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryPressed,
                    ),
                  ),
                ),
              if (enteredRunning)
                const SizedBox(width: 8, height: 36)
              else
                IconButton(
                  key: const ValueKey('challenge-banner-dismiss'),
                  tooltip: l10n.challengeDismiss,
                  onPressed: () => _dismiss(status!),
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  color: AppColors.textSecondary,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          // Under the title, the full width of the card.
          Padding(
            padding: const EdgeInsets.fromLTRB(_artSize + 10, 0, 8, 0),
            child: Text(
              body,
              key: const ValueKey('challenge-banner-body'),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (phase == ChallengePhase.running && !status.joined)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 8, 0),
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  key: const ValueKey('challenge-banner-join'),
                  onPressed: _busy ? null : () => _join(status!),
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
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.challengeJoinCta),
                ),
              ),
            ),
          if (status.joined && phase != ChallengePhase.teaser) ...[
            if (phase == ChallengePhase.running)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 8, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    key: const ValueKey('challenge-banner-progress'),
                    value: status.dayNumber / challenge.totalDays,
                    minHeight: 6,
                    backgroundColor: AppColors.primarySoft,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      headline,
                      key: const ValueKey('challenge-banner-headline'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  // The share card is the couple's; it needs a partner.
                  if (status.hasPartner) const DuoShareButton(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The challenge's key visual as a rounded square; the trophy icon when the
/// challenge has no image (or it fails to load).
class ChallengeArt extends StatelessWidget {
  const ChallengeArt({super.key, required this.challenge, required this.size});

  final DuoChallenge challenge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox.square(
      dimension: size,
      child: Icon(
        Icons.emoji_events_rounded,
        color: AppColors.primary,
        size: size * 0.6,
      ),
    );
    final asset = challengeImageAsset(challenge);
    if (asset == null) return fallback;
    final radius = BorderRadius.circular(size * 0.28);
    // A hairline edge: the image has a light background and would otherwise
    // dissolve into the card.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          asset,
          key: const ValueKey('challenge-art'),
          width: size,
          height: size,
          fit: BoxFit.cover,
          // The 256px file is shown at 40–72pt: averaged, not point-sampled.
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => fallback,
        ),
      ),
    );
  }
}

/// Asks how to join when a promise is already running: enter it as it is,
/// or make a new one for the challenge.
class _JoinSheet extends StatelessWidget {
  const _JoinSheet({required this.status, required this.plan});

  final ChallengeStatus status;
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final title = plan.items.firstOrNull?.title ?? '';

    Widget option({
      required Key key,
      required IconData icon,
      required String label,
      required String detail,
      required _JoinChoice choice,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(choice),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, media.viewPadding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: ChallengeArt(challenge: status.challenge, size: 72)),
            const SizedBox(height: 12),
            Text(
              l10n.challengeJoinSheetTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            option(
              key: const ValueKey('challenge-join-existing'),
              icon: Icons.check_circle_outline_rounded,
              label: l10n.challengeJoinExisting,
              detail: l10n.challengeJoinExistingSub(title),
              choice: _JoinChoice.existing,
            ),
            option(
              key: const ValueKey('challenge-join-new'),
              icon: Icons.add_circle_outline_rounded,
              label: l10n.challengeJoinNew,
              detail: l10n.challengeJoinNewSub(
                challengeDateLabel(l10n, status.challenge.end),
              ),
              choice: _JoinChoice.newPlan,
            ),
          ],
        ),
      ),
    );
  }
}
