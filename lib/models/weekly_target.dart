/// 주 N회 자유 요일 — a workout promise kept N times a week on any days
/// (`plans.weeklyTarget`, an int 1–6; missing = the classic fixed weekdays).
///
/// The rules, shared by every client surface (plan math, 둘운완 stats, Now
/// cards, reminders) and mirrored in `functions/src/weekly.ts` — both sides
/// run the same vectors (`test/fixtures/weekly_target_vectors.json`):
///
/// - A week is Monday–Sunday in the owner's time zone. Only its days inside
///   the plan period count; a week the period only partly covers asks for a
///   prorated target ([weeklyTargetForAvailableDays]).
/// - A day *credits* the week when it has a done record, a partner rescue
///   (실천 인정) or a rest pass (휴식권, still one a week). A skip does not.
/// - An unlogged day is neutral while the week can still be completed. A day
///   is a **must-do** day when the days left in the week, that day included,
///   are no more than the credits still needed ([weeklyIsMustDo]); a must-do
///   day without a credit is a miss once it is over. When the week can no
///   longer be completed every remaining day is must-do (each unlogged one is
///   another miss), which is also the classic plans' "every scheduled day".
/// - Must-do is decided from the credits *before* the day, so a day's own
///   record never changes whether it was must-do, and later records never
///   rewrite an earlier day. With no further records the must-do days of a
///   week are always its last days — what the reminders predict.
library;

/// Smallest and largest weekly target. 7 a week is the classic "매일".
const int kWeeklyTargetMin = 1;
const int kWeeklyTargetMax = 6;

/// The weekly target stored in [value], or null when it is missing or not an
/// int in [kWeeklyTargetMin]..[kWeeklyTargetMax] (the plan is then a classic
/// fixed-weekday one — the safe reading for anything malformed).
int? parseWeeklyTarget(Object? value) {
  final int? n;
  if (value is int) {
    n = value;
  } else if (value is double && value == value.truncateToDouble()) {
    n = value.toInt();
  } else {
    n = null;
  }
  if (n == null || n < kWeeklyTargetMin || n > kWeeklyTargetMax) return null;
  return n;
}

/// The target of a week of which only [availableDays] lie inside the plan
/// period: the full [target] for a whole week, otherwise prorated and
/// rounded up (a Saturday start asks for 1 of 주 3회 that first weekend),
/// never more than the days available.
int weeklyTargetForAvailableDays(int target, int availableDays) {
  if (availableDays <= 0 || target <= 0) return 0;
  if (availableDays >= 7) return target;
  final prorated = (target * availableDays + 6) ~/ 7;
  var result = prorated < target ? prorated : target;
  if (result > availableDays) result = availableDays;
  return result;
}

/// Whether a day is must-do: [needed] credits are still missing this week
/// and only [remaining] days (that day included) are left to get them.
bool weeklyIsMustDo({required int needed, required int remaining}) =>
    needed > 0 && remaining <= needed;

/// One Monday–Sunday week of a weekly plan, evaluated.
class WeeklyWeek {
  const WeeklyWeek({
    required this.target,
    required this.credited,
    required this.inPeriod,
    required this.creditedDays,
    required this.mustDo,
  });

  /// This week's target (prorated for a partial week; 0 outside the period).
  final int target;

  /// Credited days inside the period (done, rescued, rested).
  final int credited;

  /// Per weekday (index 0 = Monday): inside the plan period.
  final List<bool> inPeriod;

  /// Per weekday: has a credit (inside the period).
  final List<bool> creditedDays;

  /// Per weekday: must-do, from the credits before that day.
  final List<bool> mustDo;

  /// Credits still missing (0 once the week is met).
  int get needed => credited >= target ? 0 : target - credited;

  /// The week's target is reached.
  bool get isMet => target > 0 && credited >= target;
}

/// Evaluates one week from per-weekday flags (index 0 = Monday): which days
/// lie in the plan period and which have a credit. Pure; the vectors in
/// `test/fixtures/weekly_target_vectors.json` pin it to the server's copy.
WeeklyWeek evaluateWeeklyWeek({
  required int weeklyTarget,
  required List<bool> inPeriod,
  required List<bool> credited,
}) {
  assert(inPeriod.length == 7 && credited.length == 7);
  final available = inPeriod.where((d) => d).length;
  final target = weeklyTargetForAvailableDays(weeklyTarget, available);
  final creditedDays = [for (var i = 0; i < 7; i++) inPeriod[i] && credited[i]];
  final mustDo = List<bool>.filled(7, false);
  var before = 0;
  var remaining = available;
  for (var i = 0; i < 7; i++) {
    if (!inPeriod[i]) continue;
    mustDo[i] = weeklyIsMustDo(needed: target - before, remaining: remaining);
    if (creditedDays[i]) before++;
    remaining--;
  }
  return WeeklyWeek(
    target: target,
    credited: before,
    inPeriod: List.unmodifiable(inPeriod),
    creditedDays: List.unmodifiable(creditedDays),
    mustDo: List.unmodifiable(mustDo),
  );
}

/// Local midnight of the Monday of [day]'s week.
DateTime weeklyWeekStartOf(DateTime day) {
  final local = day.toLocal();
  return DateTime(local.year, local.month, local.day - (local.weekday - 1));
}

/// A calendar-day key (yyyymmdd) of [d] in local time.
int weeklyDayKey(DateTime d) {
  final local = d.toLocal();
  return local.year * 10000 + local.month * 100 + local.day;
}

/// Day keys of [dates] (local), for O(1) credit lookups.
Set<int> weeklyDayKeys(Iterable<DateTime> dates) => {
  for (final d in dates) weeklyDayKey(d),
};

/// The week of [day] for a plan with [weeklyTarget] running from
/// [periodStart] to [periodEnd] (inclusive calendar days), where
/// [isCredited] says whether a day key has a credit.
WeeklyWeek evaluateWeeklyWeekAt({
  required int weeklyTarget,
  required DateTime day,
  required DateTime periodStart,
  required DateTime periodEnd,
  required bool Function(int dayKey) isCredited,
}) {
  final monday = weeklyWeekStartOf(day);
  final startKey = weeklyDayKey(periodStart);
  final endKey = weeklyDayKey(periodEnd);
  final inPeriod = <bool>[];
  final credited = <bool>[];
  for (var i = 0; i < 7; i++) {
    final key = weeklyDayKey(
      DateTime(monday.year, monday.month, monday.day + i),
    );
    inPeriod.add(key >= startKey && key <= endKey);
    credited.add(isCredited(key));
  }
  return evaluateWeeklyWeek(
    weeklyTarget: weeklyTarget,
    inPeriod: inPeriod,
    credited: credited,
  );
}
