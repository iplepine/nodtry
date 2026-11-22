import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart' as kakao;

import '../../../l10n/app_localizations.dart';
import '../../../utils/error_reporter.dart';
import '../domain/invite_code.dart';

// ---------------------------------------------------------------------------
// The card
// ---------------------------------------------------------------------------

/// Picture on the invite card: the landing page's Open Graph image, so the
/// card and a pasted link look the same (hosting/public/og.png, 1200×630).
const String kKakaoInviteImageUrl = 'https://nod-try.web.app/og.png';
const int kKakaoInviteImageWidth = 1200;
const int kKakaoInviteImageHeight = 630;

/// `.env` key of the Kakao native app key. Empty or missing = the KakaoTalk
/// card is off and invites go through the system share sheet as before.
const String kKakaoNativeAppKeyEnv = 'KAKAO_NATIVE_APP_KEY';

/// What the KakaoTalk invite card says, already localized.
@immutable
class KakaoInviteCard {
  const KakaoInviteCard({
    required this.title,
    required this.description,
    required this.buttonTitle,
    required this.imageUrl,
    required this.link,
  });

  final String title;

  /// Carries the code ("ABCD 2345") so it can be typed in when the link
  /// doesn't open.
  final String description;

  /// The card's one button.
  final String buttonTitle;
  final String imageUrl;

  /// The invite link ([inviteLinkFor]): where the picture, the text and the
  /// button all lead.
  final String link;

  @override
  bool operator ==(Object other) =>
      other is KakaoInviteCard &&
      other.title == title &&
      other.description == description &&
      other.buttonTitle == buttonTitle &&
      other.imageUrl == imageUrl &&
      other.link == link;

  @override
  int get hashCode =>
      Object.hash(title, description, buttonTitle, imageUrl, link);
}

/// The card for my invite: the same couple tone as [inviteShareMessage] —
/// from me, so it never names me — with the code grouped for reading aloud.
KakaoInviteCard kakaoInviteCard(
  AppLocalizations l10n, {
  required String code,
  required bool hasPromise,
}) {
  return KakaoInviteCard(
    title: hasPromise
        ? l10n.inviteKakaoCardTitle
        : l10n.inviteKakaoCardTitleNoPromise,
    description: l10n.inviteKakaoCardDescription(groupedInviteCode(code)),
    buttonTitle: l10n.inviteKakaoCardButton,
    imageUrl: kKakaoInviteImageUrl,
    link: inviteLinkFor(code),
  );
}

/// [card] as a Kakao Share feed template with one button.
///
/// Every link is the plain https invite link (web + mobile web). There are no
/// app-execution params and no `kakao{KEY}://kakaolink` URL scheme on purpose:
/// `https://nod-try.web.app/i/{CODE}` is a Universal Link / App Link, so it
/// already opens the app when installed and the landing page (with the code
/// and the store buttons) when not — one path for both, and nothing to
/// register natively. (How KakaoTalk's own browser hands that link over is
/// a device check: docs/operations/KAKAO_SHARE_SETUP.md.)
kakao.FeedTemplate kakaoInviteFeedTemplate(KakaoInviteCard card) {
  final target = Uri.parse(card.link);
  final link = kakao.Link(webUrl: target, mobileWebUrl: target);
  return kakao.FeedTemplate(
    content: kakao.Content(
      title: card.title,
      description: card.description,
      imageUrl: Uri.parse(card.imageUrl),
      imageWidth: kKakaoInviteImageWidth,
      imageHeight: kKakaoInviteImageHeight,
      link: link,
    ),
    buttons: [kakao.Button(title: card.buttonTitle, link: link)],
  );
}

// ---------------------------------------------------------------------------
// SDK start-up
// ---------------------------------------------------------------------------

/// The Kakao native app key from `.env`, or null when there is none (or
/// `.env` was never loaded, as in tests).
String? kakaoNativeAppKey() {
  if (!dotenv.isInitialized) return null;
  final key = dotenv.env[kKakaoNativeAppKeyEnv]?.trim();
  return key == null || key.isEmpty ? null : key;
}

bool get _isMobileApp =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<bool>? _kakaoSdkReady;

/// Starts the Kakao SDK once, and only when `.env` has a native app key and
/// this is the Android or iOS app. Completes with whether the SDK is usable;
/// it never throws, so start-up can call it without waiting.
Future<bool> ensureKakaoShareSdk() => _kakaoSdkReady ??= _initKakaoSdk();

Future<bool> _initKakaoSdk() async {
  final key = kakaoNativeAppKey();
  if (key == null || !_isMobileApp) return false;
  try {
    await kakao.KakaoSdk.init(nativeAppKey: key);
    return true;
  } catch (error, stack) {
    ErrorReporter.record(error, stack, reason: 'kakao_sdk_init');
    return false;
  }
}

// ---------------------------------------------------------------------------
// Sharer
// ---------------------------------------------------------------------------

/// Sends the invite as a KakaoTalk card. Overridden in tests.
abstract class KakaoInviteSharer {
  /// Whether the card can be sent from this device: a native app key is set,
  /// this is Android or iOS, and KakaoTalk is installed. Never throws —
  /// anything unexpected is "no".
  Future<bool> isAvailable();

  /// Opens KakaoTalk's chat picker with [card]. True once KakaoTalk has taken
  /// over; false when it could not (the caller falls back to the share
  /// sheet). Kakao reports nothing back about whether the user then picked a
  /// chat, so true is counted as sent — like a share sheet that can't tell.
  Future<bool> share(KakaoInviteCard card);

  /// Completes when the user is back in this app after [share] returned true.
  /// KakaoTalk is in front until then, so follow-ups that need the screen
  /// (the "초대를 보냈어요" snackbar, the notification permission prompt)
  /// wait for this.
  Future<void> backInApp();
}

class KakaoSdkInviteSharer implements KakaoInviteSharer {
  const KakaoSdkInviteSharer();

  /// The template is checked by Kakao's server before KakaoTalk opens; past
  /// this the share sheet is the better answer than a spinner.
  static const _shareTimeout = Duration(seconds: 10);

  /// How long [backInApp] waits to see KakaoTalk come to the front.
  static const _leaveTimeout = Duration(seconds: 3);

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await ensureKakaoShareSdk()) return false;
      return await kakao.ShareClient.instance.isKakaoTalkSharingAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> share(KakaoInviteCard card) async {
    try {
      if (!await ensureKakaoShareSdk()) return false;
      // SDK v2: shareDefault validates the template and opens KakaoTalk
      // itself (v1 returned a Uri to launch).
      await kakao.ShareClient.instance
          .shareDefault(template: kakaoInviteFeedTemplate(card))
          .timeout(_shareTimeout);
      return true;
    } catch (error, stack) {
      // Wrong key hash / bundle id / web domain in Kakao Developers ends up
      // here; the user still gets the share sheet.
      ErrorReporter.record(error, stack, reason: 'kakao_invite_share');
      return false;
    }
  }

  @override
  Future<void> backInApp() async {
    final binding = WidgetsBinding.instance;
    final done = Completer<void>();
    var left = binding.lifecycleState != AppLifecycleState.resumed;
    final observer = _LifecycleObserver((state) {
      if (state != AppLifecycleState.resumed) {
        left = true;
      } else if (left && !done.isCompleted) {
        done.complete();
      }
    });
    binding.addObserver(observer);
    // KakaoTalk never came to the front: nothing to wait for.
    final guard = Timer(_leaveTimeout, () {
      if (!left && !done.isCompleted) done.complete();
    });
    try {
      await done.future;
    } finally {
      guard.cancel();
      binding.removeObserver(observer);
    }
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this.onState);

  final void Function(AppLifecycleState state) onState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => onState(state);
}

final kakaoInviteSharerProvider = Provider<KakaoInviteSharer>(
  (ref) => const KakaoSdkInviteSharer(),
);

/// Whether to offer "카카오톡으로 초대 보내기". False until known, so the
/// buttons are today's until KakaoTalk is confirmed.
final kakaoInviteAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    return await ref.watch(kakaoInviteSharerProvider).isAvailable();
  } catch (_) {
    return false;
  }
});
