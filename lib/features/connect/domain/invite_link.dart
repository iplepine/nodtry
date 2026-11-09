/// Links that open the app: Universal Links / Android App Links for
/// `https://nod-try.web.app/i/{CODE}` and the app's own `onmybehalf://` scheme.
///
/// The hosts and the `/i/` path must match what the site claims in
/// `hosting/public/.well-known/` and what the app claims in
/// `ios/Runner/Runner.entitlements` and `AndroidManifest.xml`.
library;

import 'invite_code.dart';

/// Hosts whose `/i/{CODE}` links open the app (Firebase Hosting, both domains).
const Set<String> kInviteLinkHosts = {
  'nod-try.web.app',
  'nod-try.firebaseapp.com',
};

/// The app's own URL scheme (`onmybehalf://app/i/{CODE}` from the invite page's
/// "앱에서 열기" button).
const String kAppLinkScheme = 'onmybehalf';

/// The invite code in an `/i/{CODE}` path, normalized, or null.
///
/// Tolerates a trailing slash (`/i/CODE/`) and a lower-cased code (some chat
/// apps lower-case URLs); `/i/?code=CODE` is accepted too, like the landing
/// page. Anything after the code (`/i/CODE/extra`) is not an invite.
String? inviteCodeFromPath(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty || segments.first != 'i') return null;
  final String raw;
  if (segments.length == 2) {
    raw = segments[1];
  } else if (segments.length == 1) {
    raw = uri.queryParameters['code'] ?? '';
  } else {
    return null;
  }
  final code = normalizeInviteCode(raw);
  return isValidInviteCode(code) ? code : null;
}

/// What to do with a link the OS handed to the app.
sealed class IncomingLink {
  const IncomingLink();
}

/// An invite link: apply [code] in the connect flow.
class InviteIncomingLink extends IncomingLink {
  const InviteIncomingLink(this.code);
  final String code;

  @override
  bool operator ==(Object other) =>
      other is InviteIncomingLink && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'InviteIncomingLink($code)';
}

/// Another `onmybehalf://app/<path>` link: open [location] in the router, the
/// way Flutter's built-in deep linking used to.
class RouteIncomingLink extends IncomingLink {
  const RouteIncomingLink(this.location);
  final String location;

  @override
  bool operator ==(Object other) =>
      other is RouteIncomingLink && other.location == location;

  @override
  int get hashCode => location.hashCode;

  @override
  String toString() => 'RouteIncomingLink($location)';
}

/// Not ours (e.g. the Google sign-in callback scheme, another site).
class IgnoredIncomingLink extends IncomingLink {
  const IgnoredIncomingLink();
}

/// Classifies a link from app_links.
IncomingLink classifyIncomingLink(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'https' || scheme == 'http') {
    if (!kInviteLinkHosts.contains(uri.host.toLowerCase())) {
      return const IgnoredIncomingLink();
    }
    final code = inviteCodeFromPath(uri);
    return code == null
        ? const IgnoredIncomingLink()
        : InviteIncomingLink(code);
  }
  if (scheme == kAppLinkScheme) {
    final code = inviteCodeFromPath(uri);
    if (code != null) return InviteIncomingLink(code);
    final path = uri.path.isEmpty ? '/' : uri.path;
    final location = Uri(
      path: path.startsWith('/') ? path : '/$path',
      query: uri.hasQuery ? uri.query : null,
    ).toString();
    return RouteIncomingLink(location);
  }
  return const IgnoredIncomingLink();
}

/// The router location for an opened invite (`/i/{CODE}`, see
/// `AppRoutes.inviteLink`): its redirect keeps the code through sign-in or
/// goes straight to code entry.
String inviteLinkLocation(String code) => '/i/$code';
