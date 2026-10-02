import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/repository_provider.dart';
import '../../connect/application/partner_label_provider.dart';
import '../../connect/application/partner_link_binder.dart';
import '../../connect/presentation/widgets/partner_nickname_sheet.dart';
import '../../duo/application/duo_moments.dart';
import '../domain/onboarding_gate.dart';
import 'pivot_notice_sheet.dart';
import 'post_login_clipboard.dart';

/// A live link this recent gets "{name}하고 연결됐어요 🎉" on the nickname
/// sheet.
const Duration kRecentLinkWindow = Duration(minutes: 30);

/// The one-off prompts the home screen may show, at most one per call, in
/// this order:
///
/// 1. the rename notice, once, for people who used the app before;
/// 2. the post-first-login clipboard look for an invite code (new users with
///    no partner, once per device);
/// 3. the nickname sheet, once per partner, while no nickname is set — this
///    is how the inviter (whose partner entered the code elsewhere) and
///    existing couples get it;
/// 4. the 둘운완 moments: the share card when today became a duo day (once a
///    day, once per 3/7/30 milestone), then the store review request.
///
/// Returns whether something was shown. Callers only run it while the home
/// route is on top.
Future<bool> runHomePrompts(BuildContext context, WidgetRef ref) async {
  final OnboardingStore store;
  try {
    store = ref.read(onboardingStoreProvider);
  } catch (_) {
    return false; // no SharedPreferences (tests)
  }
  final profile = ref.read(myProfileProvider).value;
  if (profile == null) return false;

  final legacy = store.legacyUser(accountCreatedAt: profile.createdAt);
  if (shouldShowPivotNotice(
    legacyUser: legacy,
    seenOnDevice: store.pivotNoticeSeen,
    seenOnAccount: profile.pivotNoticeSeen,
  )) {
    await store.markPivotNoticeSeen();
    unawaited(ref.read(userRepositoryProvider).markPivotNoticeSeen());
    if (!context.mounted) return false;
    await showPivotNoticeSheet(context);
    return true;
  }

  if (!context.mounted) return false;
  if (await runPostLoginClipboardCheck(context, ref)) return true;

  final label = ref.read(partnerLabelProvider);
  final partnerUid = label.partnerUid;
  if (partnerUid != null &&
      shouldPromptNickname(
        partnerUid: partnerUid,
        nickname: label.nickname,
        promptedFor: store.nicknamePromptedFor,
      )) {
    await store.markNicknamePrompted(partnerUid);
    if (!context.mounted) return false;
    final lastLink = ref.read(lastLiveLinkProvider);
    final recent =
        lastLink != null &&
        DateTime.now().difference(lastLink) < kRecentLinkWindow;
    final l10n = AppLocalizations.of(context)!;
    await showPartnerNicknameSheet(
      context,
      celebrateName: recent ? label.resolve(l10n) : null,
    );
    return true;
  }

  if (!context.mounted) return false;
  return runDuoMomentPrompts(context, ref);
}
