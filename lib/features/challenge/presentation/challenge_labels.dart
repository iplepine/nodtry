import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../application/challenge_providers.dart';

/// The challenge's title: "새해 둘운완 21일 챌린지".
String challengeTitle(AppLocalizations l10n, DuoChallenge challenge) {
  if (challenge.id == kNewYear2027Challenge.id) {
    return l10n.challengeNewYear2027Title;
  }
  return l10n.appTitle;
}

/// The challenge's key visual (a bundled square image), or null when it has
/// none and the trophy icon stands in.
String? challengeImageAsset(DuoChallenge challenge) {
  if (challenge.id == kNewYear2027Challenge.id) {
    return 'assets/images/challenge_newyear2027.png';
  }
  return null;
}

/// The challenge's hashtag on the share card: "#새해둘운완".
String challengeHashtag(AppLocalizations l10n, DuoChallenge challenge) {
  if (challenge.id == kNewYear2027Challenge.id) {
    return l10n.challengeNewYear2027Hashtag;
  }
  return l10n.shareCardNoStreak;
}

/// The share card's challenge chip for [status], or null when the card
/// carries none: "#새해둘운완 7일째" while an entered challenge runs,
/// "#새해둘운완 완주" while its result is up.
String? challengeShareLabel(AppLocalizations l10n, ChallengeStatus? status) {
  if (status == null || !status.joined) return null;
  final hashtag = challengeHashtag(l10n, status.challenge);
  switch (status.phase) {
    case ChallengePhase.running:
      return l10n.shareCardChallengeDay(hashtag, status.dayNumber);
    case ChallengePhase.result:
      return l10n.shareCardChallengeDone(hashtag);
    case ChallengePhase.none:
    case ChallengePhase.teaser:
      return null;
  }
}

/// "1월 21일" / "Jan 21".
String challengeDateLabel(AppLocalizations l10n, DateTime date) =>
    DateFormat.MMMd(l10n.localeName).format(date);
