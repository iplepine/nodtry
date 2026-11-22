/// Seasonal challenges ("새해 둘운완 21일 챌린지"): a fixed period during
/// which the couple's 둘운완 days are counted and shown on the Now tab.
///
/// - A challenge is announced from [DuoChallenge.teaserFrom], runs from
///   [DuoChallenge.start] to [DuoChallenge.end] (both inclusive, calendar
///   days in the user's own time zone) and keeps showing its result for
///   [DuoChallenge.resultDays] more days.
/// - Entering marks a promise with the challenge id (`plans.challengeId`):
///   either a new promise that runs from today to the challenge's last day
///   ([DuoChallenge.planPeriodFrom]) instead of the usual 28 days, or an
///   existing running promise as it is.
/// - Progress is the couple's 둘운완 days (my workout days when solo) from
///   the first day of the challenge, whichever promise they were logged on.
///
/// The list is in the app ([kDuoChallenges]): a new challenge ships with a
/// release.
library;

import '../../../models/plan_model.dart';

/// Where a challenge stands on a given day.
enum ChallengePhase {
  /// Not announced yet, or over and its result no longer shown.
  none,

  /// Announced, not started.
  teaser,

  /// Running: [DuoChallenge.start] to [DuoChallenge.end].
  running,

  /// Over, result still shown.
  result,
}

class DuoChallenge {
  const DuoChallenge({
    required this.id,
    required this.start,
    required this.end,
    required this.teaserFrom,
    this.resultDays = 7,
  });

  /// Stored on entered promises (`plans.challengeId`) and sent with
  /// analytics. Never shown; the title comes from the ARB.
  final String id;

  /// The first and the last day (local midnight).
  final DateTime start;
  final DateTime end;

  /// The first day the challenge is announced.
  final DateTime teaserFrom;

  /// How many days after [end] the result stays up.
  final int resultDays;

  /// Days from [start] to [end], both included.
  int get totalDays => _daysBetween(start, end) + 1;

  ChallengePhase phaseOn(DateTime today) {
    final day = _dateOnly(today);
    if (day.isBefore(teaserFrom)) return ChallengePhase.none;
    if (day.isBefore(start)) return ChallengePhase.teaser;
    if (!day.isAfter(end)) return ChallengePhase.running;
    if (_daysBetween(end, day) <= resultDays) return ChallengePhase.result;
    return ChallengePhase.none;
  }

  /// Days left until [start] (0 on the first day and after).
  int daysUntilStart(DateTime today) {
    final days = _daysBetween(_dateOnly(today), start);
    return days < 0 ? 0 : days;
  }

  /// Which day of the challenge [today] is: 1 on [start], [totalDays] on
  /// [end] and after, 0 before it starts.
  int dayNumberOn(DateTime today) {
    final day = _dateOnly(today);
    if (day.isBefore(start)) return 0;
    final number = _daysBetween(start, day) + 1;
    return number > totalDays ? totalDays : number;
  }

  /// Days from [today] to [end], both included (0 once it is over).
  int daysLeftFrom(DateTime today) {
    final days = _daysBetween(_dateOnly(today), end) + 1;
    return days < 0 ? 0 : days;
  }

  /// The period of a promise made for this challenge on [today]: from 00:00
  /// of that day (the first day of the challenge when it hasn't started) to
  /// 23:59:59 of the last day.
  ({DateTime start, DateTime end}) planPeriodFrom(DateTime today) {
    final day = _dateOnly(today);
    final first = day.isBefore(start) ? start : day;
    return (
      start: first,
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  @override
  String toString() => 'DuoChallenge($id)';
}

/// 새해 둘운완 21일 챌린지: 2027-01-01 to 01-21, announced from 12-18 (the
/// App Store in-app event `newyear2027_duo21`).
final DuoChallenge kNewYear2027Challenge = DuoChallenge(
  id: 'newyear2027_duo21',
  start: DateTime(2027, 1, 1),
  end: DateTime(2027, 1, 21),
  teaserFrom: DateTime(2026, 12, 18),
);

/// Every challenge the app knows, oldest first. Their windows (teaser to the
/// end of the result) must not overlap.
final List<DuoChallenge> kDuoChallenges = [kNewYear2027Challenge];

/// The challenge announced, running or showing its result on [today], or
/// null.
DuoChallenge? activeChallengeOn(
  DateTime today, {
  List<DuoChallenge>? challenges,
}) {
  for (final challenge in challenges ?? kDuoChallenges) {
    if (challenge.phaseOn(today) != ChallengePhase.none) return challenge;
  }
  return null;
}

/// Whether one of [myPlans] was entered into [challenge]. A stopped promise
/// still counts: the days are counted across promises, so stopping one does
/// not leave the challenge.
bool hasEnteredChallenge(Iterable<Plan> myPlans, DuoChallenge challenge) =>
    myPlans.any((plan) => plan.challengeId == challenge.id);

/// My running promise that can be entered as it is: the newest active one
/// that still has days inside the challenge and is in no challenge yet. Null
/// when there is none (a new promise is made instead).
Plan? enterablePlanOf(
  Iterable<Plan> myPlans,
  DuoChallenge challenge, {
  required DateTime today,
}) {
  final day = _dateOnly(today);
  Plan? newest;
  for (final plan in myPlans) {
    if (plan.id == null || plan.state != PlanState.active) continue;
    if (plan.challengeId != null || plan.items.isEmpty) continue;
    if (_dateOnly(plan.endDate).isBefore(day)) continue;
    if (newest == null || plan.createdAt.isAfter(newest.createdAt)) {
      newest = plan;
    }
  }
  return newest;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar days from [from] to [to] (negative when [to] is earlier), free
/// of daylight-saving hours.
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
