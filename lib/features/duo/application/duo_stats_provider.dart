import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/plan_model.dart';
import '../../../providers/repository_provider.dart';
import '../../connect/application/partner_label_provider.dart';
import '../domain/duo_stats.dart';

export '../domain/duo_stats.dart';

/// "Now" for the duo stats. Overridden in tests.
final duoClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today's date (midnight, local) for the duo stats.
///
/// Rolls over by itself at the next local midnight, and [refresh] re-reads
/// the clock (HomeScreen calls it when the app resumes) — the plan streams
/// don't emit on resume when nothing changed, so without this the duo header
/// kept yesterday as "today" after an overnight background.
class DuoTodayNotifier extends Notifier<DateTime> {
  Timer? _midnight;

  @override
  DateTime build() {
    ref.onDispose(() => _midnight?.cancel());
    final now = ref.watch(duoClockProvider)();
    _scheduleRollover(now);
    return _dateOnly(now);
  }

  /// Re-reads the clock; updates only when the date changed.
  void refresh() {
    final now = ref.read(duoClockProvider)();
    final today = _dateOnly(now);
    if (today != state) state = today;
    _scheduleRollover(now);
  }

  void _scheduleRollover(DateTime now) {
    _midnight?.cancel();
    final next = DateTime(now.year, now.month, now.day + 1);
    // A second past midnight so the re-read lands on the new day.
    _midnight = Timer(
      next.difference(now) + const Duration(seconds: 1),
      refresh,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

final duoTodayProvider = NotifierProvider.autoDispose<DuoTodayNotifier, DateTime>(
  DuoTodayNotifier.new,
);

/// When the current couple link was made (date only), or null without a
/// partner or when unknown. Days before it never count as 둘운완.
final partnerLinkedSinceProvider = Provider.autoDispose<DateTime?>((ref) {
  final linkedAt = ref.watch(
    connectedProfilesProvider.select(
      (partners) => partners.value?.firstOrNull?.linkedAt,
    ),
  );
  if (linkedAt == null) return null;
  return DateTime(linkedAt.year, linkedAt.month, linkedAt.day);
});

/// Every plan of [uid], whatever its state (the streak spans finished and
/// restarted plans).
final duoPlansProvider = StreamProvider.autoDispose.family<List<Plan>, String>((
  ref,
  uid,
) {
  return ref.watch(recordRepositoryProvider).getAllPlansByUserIdStream(uid);
});

/// My plans, or null while they load (or when signed out).
final myDuoPlansProvider = Provider.autoDispose<List<Plan>?>((ref) {
  final myUid = ref.watch(myProfileProvider.select((p) => p.value?.uid));
  if (myUid == null) return null;
  return ref.watch(duoPlansProvider(myUid)).value;
});

/// The 둘운완 stats (streak, today, this week) for me and my partner, or null
/// until both people's plans are loaded. Without a partner the stats are
/// mine alone ([DuoStats.hasPartner] false); the duo surfaces hide then.
final duoStatsProvider = Provider.autoDispose<DuoStats?>((ref) {
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

  return computeDuoStats(
    myPlans: myPlans,
    partnerPlans: partnerPlans,
    today: ref.watch(duoTodayProvider),
    hasPartner: partnerUid != null,
    linkedSince: partnerUid == null
        ? null
        : ref.watch(partnerLinkedSinceProvider),
  );
});
