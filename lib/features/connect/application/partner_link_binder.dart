import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/repository_provider.dart';
import '../../../repositories/connect_repository.dart';
import '../../../utils/analytics.dart';
import '../../onboarding/domain/onboarding_gate.dart';

/// A live change of the couple link, as seen by this device.
enum PartnerLinkEvent { linked, unlinked }

/// [before] → [after] as a link event. Only changes between two known
/// statuses count: the first status after app start or a sign-in (`before`
/// null) is not a change, so restarting the app never logs a connection.
PartnerLinkEvent? partnerLinkEventFor(
  ConnectionStatus? before,
  ConnectionStatus? after,
) {
  if (before == null || after == null || before == after) return null;
  if (after == ConnectionStatus.active) return PartnerLinkEvent.linked;
  if (before == ConnectionStatus.active && after == ConnectionStatus.none) {
    return PartnerLinkEvent.unlinked;
  }
  return null;
}

/// Set right before this device submits an invite code, so the link that
/// follows is logged with `role: invitee`. Any other live link is the
/// inviter's (their partner entered the code).
class InviteeLinkPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;
  void clear() => state = false;
}

final inviteeLinkPendingProvider =
    NotifierProvider<InviteeLinkPendingNotifier, bool>(
      InviteeLinkPendingNotifier.new,
    );

/// When this device last saw a live link (for "연결됐어요" on the nickname
/// sheet the inviter gets).
class LastLiveLinkNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void record(DateTime at) => state = at;
}

final lastLiveLinkProvider = NotifierProvider<LastLiveLinkNotifier, DateTime?>(
  LastLiveLinkNotifier.new,
);

/// Watches the couple link for the whole app run (main.dart keeps it alive):
///
/// * logs `partner_connected {role: inviter|invitee}` once per live link —
///   the inviter's side too, which used to be counted only while the connect
///   screen's view model happened to be alive;
/// * when the partner disconnects, drops the nickname I had for them so it
///   can't carry over to a next partner (the server does the same in
///   onRelationDeleted; this makes it immediate), and forgets that the
///   nickname sheet was shown, so a re-link asks again.
///
/// Reminders follow the link through `reminderLinkRefreshBinderProvider`.
final partnerLinkBinderProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<ConnectionStatus>>(connectionStatusStreamProvider, (
    previous,
    next,
  ) {
    final before = previous is AsyncData<ConnectionStatus>
        ? previous.value
        : null;
    final after = next is AsyncData<ConnectionStatus> ? next.value : null;
    switch (partnerLinkEventFor(before, after)) {
      case PartnerLinkEvent.linked:
        final invitee = ref.read(inviteeLinkPendingProvider);
        ref.read(inviteeLinkPendingProvider.notifier).clear();
        ref.read(lastLiveLinkProvider.notifier).record(DateTime.now());
        AnalyticsService.log(AnalyticsEvent.partnerConnected, {
          'role': invitee ? 'invitee' : 'inviter',
        });
      case PartnerLinkEvent.unlinked:
        unawaited(_dropNickname(ref));
        unawaited(_forgetNicknamePrompt(ref));
      case null:
        break;
    }
  });
});

Future<void> _dropNickname(Ref ref) async {
  final nickname = ref.read(myProfileProvider).value?.partnerNickname;
  if (nickname == null) return;
  try {
    await ref.read(userRepositoryProvider).updatePartnerNickname(null);
  } catch (e) {
    debugPrint('[partnerLinkBinder] nickname clear skipped: $e');
  }
}

Future<void> _forgetNicknamePrompt(Ref ref) async {
  try {
    await ref.read(onboardingStoreProvider).clearNicknamePrompted();
  } catch (e) {
    debugPrint('[partnerLinkBinder] nickname prompt reset skipped: $e');
  }
}
