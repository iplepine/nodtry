import '../../../models/plan_model.dart';
import '../../../models/together_log.dart';

export '../../../models/together_log.dart';

/// First app build that can answer "같이 했어" (the card and the 나도 했어
/// button; functions `TOGETHER_BUILD`). A partner on an older build is never
/// offered: they could not confirm.
const int kTogetherBuild = 88;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// A workout promise (a workout tile; not diet, not a legacy plan without
/// `workoutType`) — "같이 했어" is about working out together.
bool isTogetherWorkoutPlan(Plan plan) {
  final type = plan.workoutType;
  return type != null && type != 'diet';
}

/// Whether [plan] has any record (done / skipped / rested / rescued) on
/// [day].
bool hasRecordOn(Plan plan, DateTime day) => [
  ...plan.completedDates,
  ...plan.skippedDates,
  ...plan.restedDates,
  ...plan.rescuedDates,
].any((d) => _sameDay(d, day));

/// Whether [plan] asks for a workout on [now]'s day: it is running and
/// today is in its period, and — fixed weekdays — today is one of them, or —
/// 주 N회 — this week's target isn't met yet.
bool isTogetherDueToday(Plan plan, DateTime now) {
  if (plan.state != PlanState.active) return false;
  final today = _dateOnly(now);
  if (today.isBefore(_dateOnly(plan.startDate)) ||
      today.isAfter(_dateOnly(plan.endDate))) {
    return false;
  }
  if (plan.isWeekly) return !plan.isWeeklyGoalMet(asOf: now);
  final weekdays = plan.items.expand((item) => item.days).toSet();
  return weekdays.isEmpty || weekdays.contains(today.weekday);
}

/// The partner's plan a "같이 했어" on [myPlan] can cover, or null when the
/// toggle shouldn't show.
///
/// Offered only when:
/// - [myPlan] is my running workout promise and my partner manages it (they
///   read my record — and my photo — as its manager);
/// - the partner's build can confirm ([partnerClientBuild] ≥ [kTogetherBuild]);
/// - one of [partnerPlans] is their running workout promise, due today
///   ([isTogetherDueToday]) and not recorded today ([hasRecordOn]).
///
/// With several, the one with the same workout wins, then the oldest.
TogetherTag? togetherTargetFor({
  required Plan myPlan,
  required String myUid,
  required String partnerUid,
  required int? partnerClientBuild,
  required Iterable<Plan> partnerPlans,
  required DateTime now,
}) {
  if (partnerUid.isEmpty || partnerUid == myUid) return null;
  if ((partnerClientBuild ?? 0) < kTogetherBuild) return null;
  if (myPlan.userId != myUid || myPlan.managerId != partnerUid) return null;
  if (myPlan.state != PlanState.active || !isTogetherWorkoutPlan(myPlan)) {
    return null;
  }
  final candidates =
      partnerPlans
          .where(
            (plan) =>
                plan.id != null &&
                plan.userId == partnerUid &&
                isTogetherWorkoutPlan(plan) &&
                isTogetherDueToday(plan, now) &&
                !hasRecordOn(plan, now),
          )
          .toList()
        ..sort((a, b) {
          final aSame = a.workoutType == myPlan.workoutType ? 0 : 1;
          final bSame = b.workoutType == myPlan.workoutType ? 0 : 1;
          if (aSame != bSame) return aSame - bSame;
          return a.createdAt.compareTo(b.createdAt);
        });
  if (candidates.isEmpty) return null;
  return TogetherTag(
    partnerUid: partnerUid,
    partnerPlanId: candidates.first.id!,
  );
}

/// The partner's "같이 했어" waiting for my 나도 했어.
class TogetherClaim {
  const TogetherClaim({required this.sourcePlan, required this.myPlan});

  /// The partner's plan whose latest record says we did it together.
  final Plan sourcePlan;

  /// My plan it is for.
  final Plan myPlan;

  /// The partner's record ([TogetherMark.actionId]).
  String get sourceActionId => sourcePlan.lastTogether!.actionId;
}

/// The partner's "같이 했어" records of [now]'s day that still wait for me:
/// their plan's latest `done` ([Plan.lastActionId]) is the together one,
/// it names me and one of my running plans, I haven't recorded that plan
/// today, and I haven't put the card away ([dismissedActionIds]).
List<TogetherClaim> pendingTogetherClaims({
  required Iterable<Plan> partnerPlans,
  required Iterable<Plan> myPlans,
  required String myUid,
  required DateTime now,
  Set<String> dismissedActionIds = const {},
}) {
  final claims = <TogetherClaim>[];
  final claimedPlans = <String>{};
  for (final source in partnerPlans) {
    final mark = source.lastTogether;
    if (mark == null || source.userId == myUid) continue;
    if (mark.withUid != myUid || mark.actionId != source.lastActionId) continue;
    if (!_sameDay(mark.at, now) || dismissedActionIds.contains(mark.actionId)) {
      continue;
    }
    Plan? mine;
    for (final plan in myPlans) {
      if (plan.id == mark.planId && plan.userId == myUid) mine = plan;
    }
    if (mine == null || mine.state != PlanState.active) continue;
    if (hasRecordOn(mine, now) || !claimedPlans.add(mine.id!)) continue;
    claims.add(TogetherClaim(sourcePlan: source, myPlan: mine));
  }
  return claims;
}
