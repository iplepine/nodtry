import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/plan_model.dart';
import '../../../providers/repository_provider.dart';
import '../../connect/application/partner_label_provider.dart';
import '../../duo/application/duo_stats_provider.dart';
import '../domain/duo_challenge.dart';

export '../domain/duo_challenge.dart';

/// The challenges the app runs. Overridden in tests.
final duoChallengesProvider = Provider<List<DuoChallenge>>(
  (ref) => kDuoChallenges,
);

/// Where I stand in the challenge that is announced, running or just over.
class ChallengeStatus {
  const ChallengeStatus({
    required this.challenge,
    required this.phase,
    required this.joined,
    required this.hasPartner,
    required this.dayNumber,
    required this.daysUntilStart,
    required this.daysLeft,
    required this.headlineDays,
    this.enterablePlan,
  });

  final DuoChallenge challenge;

  /// Never [ChallengePhase.none].
  final ChallengePhase phase;

  /// One of my promises is entered.
  final bool joined;
  final bool hasPartner;

  /// Which day of the challenge today is (0 before it starts).
  final int dayNumber;
  final int daysUntilStart;

  /// Days from today to the last day, both included.
  final int daysLeft;

  /// 둘운완 days (my workout days when solo) since the challenge began.
  final int headlineDays;

  /// My running promise that can be entered as it is, if any.
  final Plan? enterablePlan;
}

/// The status of the current challenge, or null when there is none — or
/// while the plans it needs are still loading.
final challengeStatusProvider = Provider.autoDispose<ChallengeStatus?>((ref) {
  final today = ref.watch(duoTodayProvider);
  final challenge = activeChallengeOn(
    today,
    challenges: ref.watch(duoChallengesProvider),
  );
  if (challenge == null) return null;

  final myPlans = ref.watch(myDuoPlansProvider);
  if (myPlans == null) return null;
  final partnerUid = ref.watch(
    partnerLabelProvider.select((label) => label.partnerUid),
  );
  var partnerPlans = const <Plan>[];
  if (partnerUid != null) {
    final theirs = ref.watch(duoPlansProvider(partnerUid)).value;
    if (theirs == null) return null;
    partnerPlans = theirs;
  }
  final hasPartner = partnerUid != null;

  final phase = challenge.phaseOn(today);
  var headlineDays = 0;
  if (phase == ChallengePhase.running || phase == ChallengePhase.result) {
    final last = today.isAfter(challenge.end) ? challenge.end : today;
    final days = computeDuoDays(
      myPlans: myPlans,
      partnerPlans: partnerPlans,
      from: challenge.start,
      to: last,
      today: today,
      hasPartner: hasPartner,
      linkedSince: hasPartner ? ref.watch(partnerLinkedSinceProvider) : null,
    );
    headlineDays = days
        .where((day) => hasPartner ? day.isDuoDay : day.me.isDone)
        .length;
  }

  return ChallengeStatus(
    challenge: challenge,
    phase: phase,
    joined: hasEnteredChallenge(myPlans, challenge),
    hasPartner: hasPartner,
    dayNumber: challenge.dayNumberOn(today),
    daysUntilStart: challenge.daysUntilStart(today),
    daysLeft: challenge.daysLeftFrom(today),
    headlineDays: headlineDays,
    enterablePlan: phase == ChallengePhase.running
        ? enterablePlanOf(myPlans, challenge, today: today)
        : null,
  );
});

/// Which challenge banners were closed by hand on this device, per phase
/// (`'{id}@{phase}'`): closing the announcement still shows the banner once
/// the challenge starts.
class ChallengeDismissalsNotifier extends Notifier<Set<String>> {
  static const prefsKey = 'challenge.banner_dismissed_v1';

  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null; // no SharedPreferences (tests)
    }
  }

  @override
  Set<String> build() =>
      (_prefs?.getStringList(prefsKey) ?? const <String>[]).toSet();

  static String keyOf(DuoChallenge challenge, ChallengePhase phase) =>
      '${challenge.id}@${phase.name}';

  Future<void> dismiss(DuoChallenge challenge, ChallengePhase phase) async {
    final next = {...state, keyOf(challenge, phase)};
    state = next;
    await _prefs?.setStringList(prefsKey, next.toList()..sort());
  }
}

final challengeDismissalsProvider =
    NotifierProvider<ChallengeDismissalsNotifier, Set<String>>(
      ChallengeDismissalsNotifier.new,
    );
