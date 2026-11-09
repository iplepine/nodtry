import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/plan_model.dart';
import '../../../providers/repository_provider.dart';
import '../../../utils/analytics.dart';
import '../../../utils/error_reporter.dart';
import '../../connect/application/partner_label_provider.dart';
import '../../duo/application/duo_stats_provider.dart';
import '../domain/together_rules.dart';

export '../domain/together_rules.dart';

/// "Now" for the together rules. Overridden in tests.
final togetherClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The partner's plan a "같이 했어" on my plan [myPlanId] can cover, or null
/// (no partner, an old partner build, nothing of theirs due today …; see
/// [togetherTargetFor]).
final togetherTargetProvider = Provider.autoDispose
    .family<TogetherTag?, String>((ref, myPlanId) {
      final myUid = ref.watch(myProfileProvider.select((p) => p.value?.uid));
      final partner = ref.watch(
        connectedProfilesProvider.select((p) => p.value?.firstOrNull?.user),
      );
      if (myUid == null || partner == null) return null;
      Plan? myPlan;
      for (final plan in ref.watch(myDuoPlansProvider) ?? const <Plan>[]) {
        if (plan.id == myPlanId) myPlan = plan;
      }
      if (myPlan == null) return null;
      final partnerPlans = ref.watch(duoPlansProvider(partner.uid)).value;
      if (partnerPlans == null) return null;
      return togetherTargetFor(
        myPlan: myPlan,
        myUid: myUid,
        partnerUid: partner.uid,
        partnerClientBuild: partner.clientBuild,
        partnerPlans: partnerPlans,
        now: ref.watch(togetherClockProvider)(),
      );
    });

/// "같이 했대요" cards put away this run (by the partner's action id). Not
/// persisted: the card only lives for the day anyway.
class TogetherDismissedNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void dismiss(String actionId) => state = {...state, actionId};
}

final togetherDismissedProvider =
    NotifierProvider<TogetherDismissedNotifier, Set<String>>(
      TogetherDismissedNotifier.new,
    );

/// The partner's "같이 했어" records waiting for my 나도 했어 today.
final togetherClaimsProvider = Provider.autoDispose<List<TogetherClaim>>((ref) {
  final myUid = ref.watch(myProfileProvider.select((p) => p.value?.uid));
  final partnerUid = ref.watch(
    partnerLabelProvider.select((label) => label.partnerUid),
  );
  if (myUid == null || partnerUid == null) return const [];
  final myPlans = ref.watch(myDuoPlansProvider);
  final partnerPlans = ref.watch(duoPlansProvider(partnerUid)).value;
  if (myPlans == null || partnerPlans == null) return const [];
  return pendingTogetherClaims(
    partnerPlans: partnerPlans,
    myPlans: myPlans,
    myUid: myUid,
    now: ref.watch(togetherClockProvider)(),
    dismissedActionIds: ref.watch(togetherDismissedProvider),
  );
});

/// The toggle state of one 했어 flow (photo preview or 사진 없이 했어): what
/// the toggle offers ([offered], set by the toggle once it knows) and
/// whether it is on ([value], default off).
class TogetherChoice extends ValueNotifier<bool> {
  TogetherChoice() : super(false);

  /// The partner's plan the toggle offers, or null while it isn't shown.
  TogetherTag? offered;

  /// What to save with the record: the offered plan when the toggle is on.
  TogetherTag? get selection => value ? offered : null;
}

/// Where a 나도 했어 came from (`together_confirmed.surface`).
enum TogetherConfirmSurface { card, notification }

/// 나도 했어: logs my plan for today answering the partner's record
/// [sourceActionId] — only ever from my own tap (the card or the push's
/// button). Skips today's reminder of the plan once logged.
Future<TogetherConfirmResult> confirmTogetherLog(
  WidgetRef ref, {
  required String planId,
  required String sourceActionId,
  required TogetherConfirmSurface surface,
}) async {
  final result = await ref
      .read(recordRepositoryProvider)
      .confirmTogether(planId, sourceActionId: sourceActionId);
  AnalyticsService.log(AnalyticsEvent.togetherConfirmed, {
    'surface': surface.name,
    'outcome': result.outcome.name,
    'has_photo': result.photoPath != null,
  });
  if (result.logged) {
    ref.read(togetherDismissedProvider.notifier).dismiss(sourceActionId);
    await _skipTodaysReminder(ref, planId);
  }
  return result;
}

Future<void> _skipTodaysReminder(WidgetRef ref, String planId) async {
  try {
    Plan? plan;
    for (final p in ref.read(myDuoPlansProvider) ?? const <Plan>[]) {
      if (p.id == planId) plan = p;
    }
    final alarms = ref.read(settingAlarmUseCaseProvider);
    if (plan != null) {
      await alarms.execute(plan, skipToday: true, creditedToday: true);
    } else {
      await alarms.cancelById(planId);
    }
  } catch (e, s) {
    // A reminder that still rings must not undo the record.
    ErrorReporter.record(e, s, reason: 'togetherSkipReminder');
  }
}
