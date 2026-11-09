/// Opening the app from a link: Universal Links (iOS), App Links (Android) and
/// the `onmybehalf://` scheme, all through app_links.
///
/// Flutter's built-in deep linking is turned off (`FlutterDeepLinkingEnabled`
/// in Info.plist, `flutter_deeplinking_enabled` in AndroidManifest.xml) so a
/// link is handled once, here.
///
/// An invite link (`https://nod-try.web.app/i/{CODE}`):
/// 1. keeps the code on the device ([OnboardingStore.setPendingCodeEntry],
///    source `link`) so it survives the tutorial, sign-in and onboarding;
/// 2. opens `/i/{CODE}` in the router, whose redirect goes straight to code
///    entry when signed in, or to the splash (sign-in) otherwise. After sign-in
///    the pending code opens code entry, and the connect screen's lookup logs
///    `invite_code_detected {source: link}`.
///
/// On a cold start the launch link is also kept before the first frame
/// ([stashLaunchInviteLink]), so the splash skips the tutorial (spec §4.1).
library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_router.dart';
import '../../onboarding/domain/onboarding_gate.dart';
import '../domain/invite_code.dart';
import '../domain/invite_link.dart';

/// Where links come from. Overridden in tests.
abstract class IncomingLinkSource {
  /// Every link the app is opened with, the launch link included (app_links
  /// replays links received before the first listen).
  Stream<Uri> get links;

  /// The link that launched the app, if any.
  Future<Uri?> initialLink();
}

class AppLinksIncomingLinkSource implements IncomingLinkSource {
  const AppLinksIncomingLinkSource();

  @override
  Stream<Uri> get links => AppLinks().uriLinkStream;

  @override
  Future<Uri?> initialLink() => AppLinks().getInitialLink();
}

final incomingLinkSourceProvider = Provider<IncomingLinkSource>(
  (ref) => const AppLinksIncomingLinkSource(),
);

/// Keeps the code of an invite link for after sign-in. Returns the code, or
/// null when [uri] is not an invite link.
Future<String?> stashInviteLink(OnboardingStore store, Uri uri) async {
  final link = classifyIncomingLink(uri);
  if (link is! InviteIncomingLink) return null;
  await store.setPendingCodeEntry(
    code: link.code,
    source: InviteCodeSource.link.id,
  );
  return link.code;
}

/// Before `runApp`: keeps the code of the link that launched the app, so the
/// splash already knows about it when it decides on the tutorial. Navigation
/// still happens once, when the link arrives on [IncomingLinkSource.links].
Future<String?> stashLaunchInviteLink(
  OnboardingStore store,
  IncomingLinkSource source, {
  Duration timeout = const Duration(milliseconds: 500),
}) async {
  try {
    final uri = await source.initialLink().timeout(
      timeout,
      onTimeout: () => null,
    );
    if (uri == null) return null;
    return await stashInviteLink(store, uri);
  } catch (e) {
    debugPrint('launch link check failed (ignored): $e');
    return null;
  }
}

/// The last invite code opened from a link in this app run. The splash
/// listens to leave the tutorial when a link arrives while it is showing.
class OpenedInviteLinkNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void record(String code) => state = code;
}

final openedInviteLinkProvider =
    NotifierProvider<OpenedInviteLinkNotifier, String?>(
      OpenedInviteLinkNotifier.new,
    );

/// Turns an incoming link into a stash + a router location.
class IncomingLinkHandler {
  IncomingLinkHandler({
    required this.readStore,
    required this.navigate,
    this.onInvite,
    DateTime Function()? clock,
    this.repeatWindow = const Duration(seconds: 2),
  }) : _clock = clock ?? DateTime.now;

  /// The device store; may throw (no SharedPreferences in some tests), in
  /// which case the code is simply not kept.
  final OnboardingStore Function() readStore;
  final void Function(String location) navigate;
  final void Function(String code)? onInvite;
  final DateTime Function() _clock;

  /// The same link again within this window is one tap delivered twice.
  final Duration repeatWindow;

  Uri? _lastUri;
  DateTime? _lastAt;

  Future<void> handle(Uri uri) async {
    final now = _clock();
    final lastAt = _lastAt;
    if (_lastUri == uri &&
        lastAt != null &&
        now.difference(lastAt) < repeatWindow) {
      return;
    }
    _lastUri = uri;
    _lastAt = now;

    switch (classifyIncomingLink(uri)) {
      case InviteIncomingLink(:final code):
        try {
          await stashInviteLink(readStore(), uri);
        } catch (e) {
          debugPrint('invite link stash failed (ignored): $e');
        }
        onInvite?.call(code);
        navigate(inviteLinkLocation(code));
      case RouteIncomingLink(:final location):
        navigate(location);
      case IgnoredIncomingLink():
        break;
    }
  }
}

/// Listens for links for the whole app run. Watched once in `OnMyBehalfApp`.
final incomingLinkBinderProvider = Provider<void>((ref) {
  final handler = IncomingLinkHandler(
    readStore: () => ref.read(onboardingStoreProvider),
    navigate: (location) => ref.read(routerProvider).go(location),
    onInvite: (code) =>
        ref.read(openedInviteLinkProvider.notifier).record(code),
  );
  StreamSubscription<Uri>? subscription;
  try {
    subscription = ref
        .read(incomingLinkSourceProvider)
        .links
        .listen(
          (uri) => unawaited(handler.handle(uri)),
          onError: (Object e) => debugPrint('app link error (ignored): $e'),
        );
  } catch (e) {
    debugPrint('app links unavailable (ignored): $e');
  }
  ref.onDispose(() => subscription?.cancel());
});
