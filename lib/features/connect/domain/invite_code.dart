/// Invite codes: how they are made, cleaned up and found.
///
/// A code is 8 upper-case letters and digits, stored as `users/{uid}.inviteCode`.
///
/// * **New codes** come from [kInviteCodeAlphabet], which leaves out the
///   look-alikes 0/O and 1/I/L, and use [Random.secure]. The server
///   (functions/src/inviteCode.ts) rotates codes with the same alphabet.
/// * **Old codes** were drawn from A-Z and 0-9, so they can still contain those
///   characters. Everything that *reads* a code therefore accepts the full
///   `[A-Z0-9]{8}` shape; old app builds validate the same shape.
library;

import 'dart:math';

/// Characters new codes are drawn from: A-Z and 2-9 without 0, O, 1, I or L.
const String kInviteCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Every invite code, old or new, is this long.
const int kInviteCodeLength = 8;

/// Landing page for a shared invite (Firebase Hosting, `/i/{CODE}`).
const String kInviteLinkBase = 'https://nod-try.web.app/i/';

/// The link that goes into a shared invite message.
String inviteLinkFor(String code) => '$kInviteLinkBase$code';

/// A fresh code from [kInviteCodeAlphabet]. [random] defaults to
/// [Random.secure]; tests pass a seeded one.
String generateInviteCode([Random? random]) {
  final rnd = random ?? Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < kInviteCodeLength; i++) {
    buffer.write(kInviteCodeAlphabet[rnd.nextInt(kInviteCodeAlphabet.length)]);
  }
  return buffer.toString();
}

/// Whitespace and the dash family people type or paste between groups
/// (`ABCD-2345`, `ABCD 2345`, `ABCD–2345`).
final RegExp _separators = RegExp(r'[\s\-‐‑‒–—―−_]');

/// What the user typed or pasted, as a code to look up: trimmed, upper-cased,
/// with spaces and hyphens removed. Nothing else is rewritten — old codes may
/// legitimately contain 0/O/1/I/L, so mapping look-alikes would break them.
String normalizeInviteCode(String input) =>
    input.replaceAll(_separators, '').toUpperCase();

/// True for the 8-character `[A-Z0-9]` shape every code has.
bool isValidInviteCode(String code) => _exactCode.hasMatch(code);

final RegExp _exactCode = RegExp(r'^[A-Z0-9]{8}$');

/// `…/i/CODE` in a shared link. Case-insensitive because some chat apps
/// lower-case URLs.
final RegExp _linkCode = RegExp(
  r'/i/([A-Za-z0-9]{8})(?![A-Za-z0-9])',
  caseSensitive: false,
);

/// A standalone 8-character upper-case token: not glued to other letters or
/// digits, so `코드 ABCD2345 넣으면` and `(ABCD2345)` match while the middle of
/// a longer word does not.
final RegExp _bareCode = RegExp(
  r'(?<![A-Za-z0-9])([A-Z0-9]{8})(?![A-Za-z0-9])',
);

/// Finds an invite code anywhere in [text] — a whole share message, a link,
/// or just the code — and returns it normalized, or null.
///
/// A code inside an invite link wins over any other token. All-digit tokens
/// are skipped: dates such as 20261003 are far likelier than a code with no
/// letters (about 3 in 100,000 old codes, effectively none of the new ones).
String? findInviteCodeInText(String? text) {
  if (text == null || text.isEmpty) return null;
  final link = _linkCode.firstMatch(text);
  if (link != null) return link.group(1)!.toUpperCase();
  for (final match in _bareCode.allMatches(text)) {
    final candidate = match.group(1)!;
    if (_allDigits.hasMatch(candidate)) continue;
    return candidate;
  }
  return null;
}

final RegExp _allDigits = RegExp(r'^[0-9]+$');

/// Words of the app's own invite message (ko/en), which mark copied text as
/// an invite even when the link was cut off.
const List<String> kInviteMessageMarkers = ['둘운완', 'DuoDone'];

/// The stricter clipboard version of [findInviteCodeInText]: a code is taken
/// from copied text only when it comes from an invite link, the text is just
/// the code, or the text is the app's own invite message. Any other 8-letter
/// token (an OTP, a recovery code, a password) is left alone — it is never
/// looked up on the server.
String? findInviteCodeInClipboardText(String? text) {
  if (text == null || text.isEmpty) return null;
  final link = _linkCode.firstMatch(text);
  if (link != null) return link.group(1)!.toUpperCase();
  final whole = text.trim();
  if (_exactCode.hasMatch(whole) && !_allDigits.hasMatch(whole)) return whole;
  if (kInviteMessageMarkers.any(text.contains)) {
    return findInviteCodeInText(text);
  }
  return null;
}

/// Where a code came from, for `invite_code_detected {source}`.
enum InviteCodeSource {
  clipboard('clipboard'),
  manual('manual'),
  link('link');

  const InviteCodeSource(this.id);
  final String id;

  static InviteCodeSource fromId(String? id) => InviteCodeSource.values
      .firstWhere((s) => s.id == id, orElse: () => InviteCodeSource.manual);
}
