import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/repository_provider.dart';
import '../../../utils/analytics.dart';
import '../presentation/duo_share_card.dart';
import 'duo_stats_provider.dart';
import 'review_prompt.dart';

/// Streak lengths that offer the share card once per run of the streak.
const List<int> kDuoShareMilestones = [3, 7, 14, 21, 30, 50, 100];

/// SharedPreferences keys.
abstract final class DuoMomentPrefKeys {
  /// 'yyyy-mm-dd' of the last day the share card was offered (null: never —
  /// the first duo day is still to come).
  static const shareOfferedDay = 'duo.share_offered_day_v1';

  /// String list of '{milestone}@{streak start yyyy-mm-dd}' already offered.
  static const milestonesOffered = 'duo.share_milestones_v1';

  /// 'yyyy-mm-dd' of the last day `duo_done_day` was logged.
  static const doneDayLogged = 'duo.done_day_logged_v1';
}

String duoDayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// The share-card offer that is due, if any.
class DuoShareOffer {
  const DuoShareOffer(this.trigger, {this.milestoneKey});

  final DuoShareTrigger trigger;

  /// Set for a milestone offer: the key to remember it by.
  final String? milestoneKey;
}

/// Whether to offer the share card by itself now (spec §4.8). Only on
/// moments worth sharing, at most once a day:
/// - the couple's first duo day ever (nothing was offered before), and
/// - a streak milestone ([kDuoShareMilestones]) not yet offered for this run
///   of the streak.
/// Any other duo day offers nothing — the Us tab's share button is always
/// there.
DuoShareOffer? decideDuoShareOffer({
  required DuoStats stats,
  required String? offeredDay,
  required Set<String> offeredMilestones,
}) {
  if (!stats.hasPartner || !stats.todayIsDuoDone) return null;
  final today = duoDayKey(stats.today.date);
  if (offeredDay == today) return null;
  final start = stats.streakStart;
  if (start != null && kDuoShareMilestones.contains(stats.streak)) {
    final key = '${stats.streak}@${duoDayKey(start)}';
    if (!offeredMilestones.contains(key)) {
      return DuoShareOffer(DuoShareTrigger.milestone, milestoneKey: key);
    }
  }
  if (offeredDay == null) return const DuoShareOffer(DuoShareTrigger.today);
  return null;
}

/// Device flags for the duo moments.
class DuoMomentsStore {
  DuoMomentsStore(this._prefs);

  final SharedPreferences _prefs;

  String? get shareOfferedDay =>
      _prefs.getString(DuoMomentPrefKeys.shareOfferedDay);

  Set<String> get milestonesOffered =>
      (_prefs.getStringList(DuoMomentPrefKeys.milestonesOffered) ?? const [])
          .toSet();

  Future<void> markOffered(String day, {String? milestoneKey}) async {
    await _prefs.setString(DuoMomentPrefKeys.shareOfferedDay, day);
    if (milestoneKey != null) {
      // Keep the list short: only the latest few runs matter.
      final keys = [...milestonesOffered, milestoneKey];
      await _prefs.setStringList(
        DuoMomentPrefKeys.milestonesOffered,
        keys.length > 20 ? keys.sublist(keys.length - 20) : keys,
      );
    }
  }

  String? get doneDayLogged =>
      _prefs.getString(DuoMomentPrefKeys.doneDayLogged);

  Future<void> markDoneDayLogged(String day) =>
      _prefs.setString(DuoMomentPrefKeys.doneDayLogged, day);
}

/// Logs `duo_done_day {streak}` once per day when today is a duo day.
/// Returns whether it logged.
Future<bool> logDuoDoneDayOnce(DuoStats stats, DuoMomentsStore store) async {
  if (!stats.hasPartner || !stats.todayIsDuoDone) return false;
  final today = duoDayKey(stats.today.date);
  if (store.doneDayLogged == today) return false;
  await store.markDoneDayLogged(today);
  AnalyticsService.log(AnalyticsEvent.duoDoneDay, {'streak': stats.streak});
  return true;
}

/// The duo step of the home prompts: logs the duo day, offers the share card
/// (once a day / once per milestone), then — never blocking — asks for a
/// store review after the first duo day or the 3rd 인정. Returns whether a
/// sheet was shown.
Future<bool> runDuoMomentPrompts(BuildContext context, WidgetRef ref) async {
  final SharedPreferences prefs;
  try {
    prefs = ref.read(sharedPreferencesProvider);
  } catch (_) {
    return false; // no SharedPreferences (tests)
  }
  final stats = ref.read(duoStatsProvider);
  if (stats == null) return false;
  final store = DuoMomentsStore(prefs);

  await logDuoDoneDayOnce(stats, store);

  var shown = false;
  final offer = decideDuoShareOffer(
    stats: stats,
    offeredDay: store.shareOfferedDay,
    offeredMilestones: store.milestonesOffered,
  );
  if (offer != null && context.mounted) {
    await store.markOffered(
      duoDayKey(stats.today.date),
      milestoneKey: offer.milestoneKey,
    );
    if (!context.mounted) return false;
    await showDuoShareCardSheet(context, ref, trigger: offer.trigger);
    shown = true;
  }

  // After the share sheet is gone, so the OS dialog never covers it.
  await maybeRequestReview(
    store: ReviewPromptStore(prefs),
    requester: ref.read(reviewRequesterProvider),
    hadDuoDay: stats.hasPartner && (stats.todayIsDuoDone || stats.streak > 0),
    propsReceived: countVerificationsReceived(
      ref.read(myDuoPlansProvider) ?? const [],
    ),
  );
  return shown;
}
