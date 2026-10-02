import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/plan_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/repository_provider.dart';
import '../../../utils/analytics.dart';
import '../../onboarding/domain/onboarding_gate.dart';
import '../domain/invite_code.dart';

// ---------------------------------------------------------------------------
// Share sheet
// ---------------------------------------------------------------------------

/// What happened to a share sheet.
class InviteShareResult {
  const InviteShareResult({required this.shared, required this.channel});

  /// The sheet could not be opened at all.
  static const failed = InviteShareResult(shared: false, channel: 'failed');

  /// The user picked a target (or the platform can't tell us, which we count
  /// as sent — Android before 5.1 and some launchers report nothing).
  final bool shared;

  /// `kakao`, `copy`, `other` or `unknown` (see [inviteChannelFromShareRaw]).
  final String channel;
}

/// The `channel` param of `invite_shared` from share_plus' raw result: the
/// Android package or iOS activity type of the app the user picked.
String inviteChannelFromShareRaw(String raw) {
  final value = raw.toLowerCase();
  if (value.isEmpty || value.contains('share/unavailable')) return 'unknown';
  if (value.contains('kakao')) return 'kakao';
  if (value.contains('copytopasteboard') || value.contains('clipboard')) {
    return 'copy';
  }
  return 'other';
}

/// Opens the system share sheet. Overridden in tests.
abstract class InviteSharer {
  Future<InviteShareResult> share({
    required String text,
    String? subject,
    Rect? origin,
  });
}

class SharePlusInviteSharer implements InviteSharer {
  const SharePlusInviteSharer();

  @override
  Future<InviteShareResult> share({
    required String text,
    String? subject,
    Rect? origin,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
    );
    switch (result.status) {
      case ShareResultStatus.dismissed:
        return const InviteShareResult(shared: false, channel: 'dismissed');
      case ShareResultStatus.success:
        return InviteShareResult(
          shared: true,
          channel: inviteChannelFromShareRaw(result.raw),
        );
      case ShareResultStatus.unavailable:
        return const InviteShareResult(shared: true, channel: 'unknown');
    }
  }
}

final inviteSharerProvider = Provider<InviteSharer>(
  (ref) => const SharePlusInviteSharer(),
);

// ---------------------------------------------------------------------------
// Clipboard
// ---------------------------------------------------------------------------

/// Clipboard access behind a seam so tests (and the iOS paste prompt) stay
/// under control. Overridden in tests.
abstract class InviteClipboard {
  /// Cheap check that never triggers the iOS "Allow Paste" prompt.
  Future<bool> hasStrings();
  Future<String?> readText();
  Future<void> writeText(String text);
}

class SystemInviteClipboard implements InviteClipboard {
  const SystemInviteClipboard();

  @override
  Future<bool> hasStrings() => Clipboard.hasStrings();

  @override
  Future<String?> readText() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  @override
  Future<void> writeText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}

final inviteClipboardProvider = Provider<InviteClipboard>(
  (ref) => const SystemInviteClipboard(),
);

// ---------------------------------------------------------------------------
// Finding a code
// ---------------------------------------------------------------------------

/// A code that resolved to a real person, ready for the confirm sheet.
class InviteCandidate {
  const InviteCandidate({
    required this.code,
    required this.owner,
    required this.source,
  });

  final String code;
  final UserModel owner;
  final InviteCodeSource source;
}

/// Logs `invite_code_detected` once a code has been looked up.
void logInviteCodeDetected(InviteCodeSource source, {required bool matched}) {
  AnalyticsService.log(AnalyticsEvent.inviteCodeDetected, {
    'source': source.id,
    'matched': matched,
  });
}

/// Looks for an invite code on the clipboard and resolves its owner.
class InviteCodeDetector {
  InviteCodeDetector({required this.clipboard, required this.lookup});

  final InviteClipboard clipboard;
  final Future<UserModel?> Function(String code) lookup;

  /// [InviteClipboard.hasStrings] first, so the iOS paste prompt only appears
  /// when there is text; then a code from an invite link, the app's invite
  /// message, or text that is just the code ([findInviteCodeInClipboardText]
  /// — any other token is never sent to the server). My own code and codes
  /// nobody holds are ignored. [onRead] is told when the clipboard text was
  /// actually read.
  Future<InviteCandidate?> fromClipboard({
    String? myCode,
    String? myUid,
    void Function()? onRead,
  }) async {
    try {
      if (!await clipboard.hasStrings()) return null;
      final text = await clipboard.readText();
      onRead?.call();
      final code = findInviteCodeInClipboardText(text);
      if (code == null || code == myCode) return null;
      final owner = await lookup(code);
      final matched = owner != null && owner.uid != myUid;
      logInviteCodeDetected(InviteCodeSource.clipboard, matched: matched);
      if (!matched) return null;
      return InviteCandidate(
        code: code,
        owner: owner,
        source: InviteCodeSource.clipboard,
      );
    } catch (_) {
      // A clipboard or lookup failure just means "nothing found".
      return null;
    }
  }
}

/// What the connect screen remembers for the rest of the app run.
class ConnectSessionMemory {
  /// The clipboard was read once already: later visits don't read it again
  /// (and don't bring up the iOS paste prompt every time).
  bool clipboardRead = false;

  /// Codes whose link the server undid (e.g. their owner already has a
  /// partner). They are not tried again automatically from the clipboard or
  /// a link.
  final Set<String> failedCodes = {};
}

final connectSessionMemoryProvider = Provider<ConnectSessionMemory>(
  (ref) => ConnectSessionMemory(),
);

final inviteCodeDetectorProvider = Provider<InviteCodeDetector>((ref) {
  return InviteCodeDetector(
    clipboard: ref.watch(inviteClipboardProvider),
    lookup: (code) =>
        ref.read(userRepositoryProvider).getUserByInviteCode(code),
  );
});

// ---------------------------------------------------------------------------
// Sending an invite
// ---------------------------------------------------------------------------

/// When this device last shared an invite (drives "초대 다시 보내기").
class InviteSharedAtNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => ref.read(onboardingStoreProvider).inviteLastSharedAt;

  Future<void> record(DateTime at) async {
    state = at;
    await ref.read(onboardingStoreProvider).recordInviteShared(at);
  }
}

final inviteSharedAtProvider =
    NotifierProvider<InviteSharedAtNotifier, DateTime?>(
      InviteSharedAtNotifier.new,
    );

/// The invite message: couple tone ("나 운동 약속 걸었어, 봐줘"), with both the
/// code and the link so it still works when the link doesn't open. It never
/// names the sender — it comes from them.
String inviteShareMessage(
  AppLocalizations l10n, {
  required String code,
  required bool hasPromise,
}) {
  final link = inviteLinkFor(code);
  return hasPromise
      ? l10n.inviteShareMessage(code, link)
      : l10n.inviteShareMessageNoPromise(code, link);
}

/// Whether [uid] has a running workout promise, for the message wording.
/// Anything slow or failing counts as "not yet" — the softer wording.
Future<bool> _hasActivePromise(WidgetRef ref, String uid) async {
  try {
    final plans = await ref
        .read(recordRepositoryProvider)
        .getPlansByUserIdStream(uid)
        .first
        .timeout(const Duration(seconds: 2));
    return plans.any((plan) => plan.state == PlanState.active);
  } catch (_) {
    return false;
  }
}

/// Opens the share sheet with my invite message. [surface] says where the
/// button was (`connect`, `onboarding`, `now_card`, `us`).
Future<InviteShareResult> shareMyInvite(
  WidgetRef ref, {
  required AppLocalizations l10n,
  required String surface,
  Rect? origin,
}) async {
  final profile = ref.read(myProfileProvider).value;
  final code = profile?.inviteCode;
  if (profile == null || code == null || code.isEmpty) {
    return InviteShareResult.failed;
  }
  final hasPromise = await _hasActivePromise(ref, profile.uid);
  final text = inviteShareMessage(l10n, code: code, hasPromise: hasPromise);

  final InviteShareResult result;
  try {
    result = await ref
        .read(inviteSharerProvider)
        .share(text: text, subject: l10n.inviteShareSubject, origin: origin);
  } catch (_) {
    return InviteShareResult.failed;
  }
  if (!result.shared) return result;

  await ref.read(inviteSharedAtProvider.notifier).record(DateTime.now());
  AnalyticsService.log(AnalyticsEvent.inviteShared, {
    'channel': result.channel,
    'surface': surface,
    'has_promise': hasPromise,
  });
  AnalyticsService.log(AnalyticsEvent.inviteCodeShared, {'method': 'share'});
  return result;
}

/// Copies my invite code. Returns false when there is no code yet.
Future<bool> copyMyInviteCode(WidgetRef ref, {required String surface}) async {
  final code = ref.read(myProfileProvider).value?.inviteCode;
  if (code == null || code.isEmpty) return false;
  await ref.read(inviteClipboardProvider).writeText(code);
  await ref.read(inviteSharedAtProvider.notifier).record(DateTime.now());
  AnalyticsService.log(AnalyticsEvent.inviteShared, {
    'channel': 'copy',
    'surface': surface,
  });
  AnalyticsService.log(AnalyticsEvent.inviteCodeShared, {'method': 'copy'});
  return true;
}
