/// What the app calls the partner (spec §3): the nickname I picked
/// (`users/{me}.partnerNickname`), else the partner's display name, else 짝꿍.
///
/// Push copy on the server follows the same order (functions/src/copy.ts
/// `partnerLabel`), so a nickname shows up the same way on screen and in
/// notifications.
library;

import '../../../l10n/app_localizations.dart';

/// `users/{uid}.partnerNickname` is at most this many characters (Unicode
/// code points, the way the server's `clip()` counts them).
const int kPartnerNicknameMaxLength = 10;

/// A nickname ready to store: whitespace collapsed and trimmed, cut to
/// [kPartnerNicknameMaxLength] code points. Null when nothing is left, which
/// means "no nickname".
String? normalizePartnerNickname(String? raw) {
  if (raw == null) return null;
  final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (collapsed.isEmpty) return null;
  final runes = collapsed.runes.toList();
  if (runes.length <= kPartnerNicknameMaxLength) return collapsed;
  final cut = String.fromCharCodes(runes.take(kPartnerNicknameMaxLength));
  final trimmed = cut.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// The placeholder older builds saved as `displayName` for accounts without
/// a name (guests, most Apple sign-ins): '나' / 'Me'. As the *partner's* name
/// it reads as "me" ("나하고 연결됐어요", "못 하면 나한테 알려져요"), so it
/// never counts as a name — the generic 짝꿍 is used instead.
bool isPlaceholderDisplayName(String? value) {
  final trimmed = value?.trim();
  return trimmed == '나' || trimmed == 'Me';
}

/// A display name fit to show for another person: trimmed, or null when
/// blank or the '나' / 'Me' placeholder.
String? partnerDisplayNameOrNull(String? value) => _nonBlank(value);

String? _nonBlank(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (isPlaceholderDisplayName(trimmed)) return null;
  return trimmed;
}

/// nickname ?? displayName ?? [fallback], ignoring blank values.
String resolvePartnerLabel({
  String? nickname,
  String? displayName,
  required String fallback,
}) {
  return normalizePartnerNickname(nickname) ??
      _nonBlank(displayName) ??
      fallback;
}

/// The pieces the label is built from, for the connected partner.
///
/// [nickname] is only set while a partner is connected: a nickname left over
/// from an earlier partner must never be shown for nobody.
class PartnerLabel {
  const PartnerLabel({this.partnerUid, this.nickname, this.displayName});

  /// No partner connected.
  static const none = PartnerLabel();

  final String? partnerUid;
  final String? nickname;
  final String? displayName;

  bool get hasPartner => partnerUid != null;
  bool get hasNickname => nickname != null;

  /// nickname ?? displayName, or null when the caller should use its own
  /// localized fallback (view models without a BuildContext).
  String? get preferred =>
      normalizePartnerNickname(nickname) ?? _nonBlank(displayName);

  /// The label to show: nickname ?? displayName ?? 짝꿍 / "your partner".
  String resolve(AppLocalizations l10n) => resolvePartnerLabel(
    nickname: nickname,
    displayName: displayName,
    fallback: l10n.partnerFallbackLabel,
  );

  /// The label for [uid]: the nickname applies only to the connected partner.
  String? preferredFor(String? uid, {String? displayName}) {
    if (uid != null && uid == partnerUid) {
      return normalizePartnerNickname(nickname) ??
          _nonBlank(displayName) ??
          _nonBlank(this.displayName);
    }
    return _nonBlank(displayName);
  }

  @override
  bool operator ==(Object other) =>
      other is PartnerLabel &&
      other.partnerUid == partnerUid &&
      other.nickname == nickname &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(partnerUid, nickname, displayName);
}
