/// 둘운완 (spec §4.7): a day on which the couple both kept their promises.
///
/// Computed on the client from both people's plans — there is no stored
/// field. The rules, per person and per calendar day:
///
/// - A day is *scheduled* when one of the person's running plans (active or
///   completed, the day inside its period) has an item on that weekday. On a
///   scheduled day every such plan has to be covered by `completedDates`,
///   `restedDates` (휴식권) or `rescuedDates`; otherwise the day is a miss —
///   or, for today, still in progress ([DuoDayStatus.pending]), which never
///   breaks anything.
/// - An unscheduled day is neutral ([DuoDayStatus.off]). A workout recorded
///   on it anyway still counts as done.
/// - A **duo day** is a day with no miss for either person and at least one
///   of them done. The partner's 인정 is not a condition, only a bonus
///   ([DuoDay.verified]); a done record still waiting for it shows as
///   [DuoVerification.waiting].
/// - The streak counts duo days backwards from today. Today only adds to it
///   (never breaks it); a day that is neutral for both, or covered only by
///   rest passes, is skipped; the first day with a miss ends it.
/// - Only days since the couple linked count ([computeDuoStats]
///   `linkedSince`): a day before the link is never a duo day, so solo
///   workouts from before the partner joined (or with a previous partner)
///   don't carry into the streak.
///
/// Stopped, draft, pending-approval and rejected plans never make a day
/// scheduled (a stopped plan keeps its end date, so its days after the stop
/// are unknown); their done records still count.
library;

import '../../../models/plan_model.dart';

/// One person's day.
enum DuoDayStatus {
  /// Nothing scheduled and nothing done. Neither counts nor breaks.
  off,

  /// A future day with something scheduled.
  upcoming,

  /// Today, scheduled, not fully recorded yet. In progress — never a miss.
  pending,

  /// Every scheduled promise covered, at least one of them done (or a
  /// workout recorded on an unscheduled day).
  done,

  /// Every scheduled promise covered, but only by rest passes / rescues.
  rested,

  /// A past scheduled day with a promise left unrecorded (or skipped).
  missed,
}

/// The partner's 인정 on a done day — a bonus, never a condition.
enum DuoVerification {
  /// Not done, or done on a plan nobody else can acknowledge (solo).
  none,

  /// Done, and the 인정 hasn't come yet.
  waiting,

  /// Done and acknowledged (❤️).
  verified,
}

class DuoPersonDay {
  const DuoPersonDay({
    required this.status,
    this.verification = DuoVerification.none,
    this.doneWorkoutTypes = const [],
  });

  static const off = DuoPersonDay(status: DuoDayStatus.off);

  final DuoDayStatus status;
  final DuoVerification verification;

  /// `Plan.workoutType` of every plan done that day, in plan order; null for
  /// a plan from before the pivot (no type).
  final List<String?> doneWorkoutTypes;

  bool get isDone => status == DuoDayStatus.done;

  /// No miss and nothing still open: done, rested or off.
  bool get isSettledOk =>
      status == DuoDayStatus.done ||
      status == DuoDayStatus.rested ||
      status == DuoDayStatus.off;

  bool get isMissed => status == DuoDayStatus.missed;

  @override
  bool operator ==(Object other) =>
      other is DuoPersonDay &&
      other.status == status &&
      other.verification == verification &&
      _listEquals(other.doneWorkoutTypes, doneWorkoutTypes);

  @override
  int get hashCode =>
      Object.hash(status, verification, Object.hashAll(doneWorkoutTypes));

  @override
  String toString() => 'DuoPersonDay($status, $verification)';
}

class DuoDay {
  const DuoDay({
    required this.date,
    required this.me,
    required this.partner,
    required this.isToday,
    this.beforeLink = false,
  });

  /// Midnight of the day (local).
  final DateTime date;
  final DuoPersonDay me;
  final DuoPersonDay partner;
  final bool isToday;

  /// A day before the couple linked: never a duo day, whatever was recorded.
  final bool beforeLink;

  bool get isFuture =>
      me.status == DuoDayStatus.upcoming ||
      partner.status == DuoDayStatus.upcoming;

  /// 둘운완: no miss for both and at least one done, since the couple linked.
  bool get isDuoDay =>
      !beforeLink &&
      me.isSettledOk &&
      partner.isSettledOk &&
      (me.isDone || partner.isDone);

  /// The ❤️ bonus: a duo day on which everyone who worked out got 인정.
  bool get verified {
    if (!isDuoDay) return false;
    final done = [me, partner].where((p) => p.isDone);
    return done.every((p) => p.verification == DuoVerification.verified);
  }

  /// Nothing happened for either of them: the streak skips the day.
  bool get isOffForBoth =>
      me.status == DuoDayStatus.off && partner.status == DuoDayStatus.off;

  bool get hasMiss => me.isMissed || partner.isMissed;

  @override
  String toString() =>
      'DuoDay(${date.year}-${date.month}-${date.day}, me: $me, partner: $partner)';
}

class DuoStats {
  const DuoStats({
    required this.streak,
    required this.streakStart,
    required this.today,
    required this.week,
    required this.hasPartner,
  });

  /// Consecutive duo days up to today (today counts once it is one).
  final int streak;

  /// The first day of the current streak, or null when [streak] is 0. Keys
  /// "once per milestone" offers to one run of the streak.
  final DateTime? streakStart;

  final DuoDay today;

  /// Monday to Sunday of the week containing today.
  final List<DuoDay> week;

  /// False for a solo user: the partner side is all [DuoDayStatus.off].
  final bool hasPartner;

  bool get todayIsDuoDone => today.isDuoDay;

  /// Duo days so far this week.
  int get weekDuoDays => week.where((d) => d.isDuoDay).length;
}

/// The furthest back the streak looks (two years).
const int kDuoStreakLookbackDays = 730;

/// Computes the 둘운완 stats for [today] from both people's plans (any
/// state). See the library comment for the rules.
///
/// [linkedSince] is when the couple's current link was made (null: unknown,
/// no bound). Days before it are never duo days and end the streak — without
/// this, a partner with no plans (off every day) would turn every solo done
/// day from before the link into a 둘운완 day.
DuoStats computeDuoStats({
  required List<Plan> myPlans,
  required List<Plan> partnerPlans,
  required DateTime today,
  bool hasPartner = true,
  DateTime? linkedSince,
  int lookbackDays = kDuoStreakLookbackDays,
}) {
  final day0 = _dateOnly(today);
  final mine = myPlans.map(_PlanDays.new).toList();
  final theirs = hasPartner
      ? partnerPlans.map(_PlanDays.new).toList()
      : const <_PlanDays>[];
  // Without a partner the duo surfaces are hidden; keep the old behaviour.
  var linkDay = hasPartner && linkedSince != null
      ? _dateOnly(linkedSince)
      : null;
  if (linkDay != null && linkDay.isAfter(day0)) linkDay = day0; // clock skew

  bool isBeforeLink(DateTime date) =>
      linkDay != null && date.isBefore(linkDay);

  DuoDay dayAt(DateTime date) => DuoDay(
    date: date,
    me: _personDay(mine, date, day0),
    partner: _personDay(theirs, date, day0),
    isToday: date == day0,
    beforeLink: isBeforeLink(date),
  );

  // This week, Monday first.
  final monday = DateTime(day0.year, day0.month, day0.day - (day0.weekday - 1));
  final week = [
    for (var i = 0; i < 7; i++)
      dayAt(DateTime(monday.year, monday.month, monday.day + i)),
  ];
  final todayDay = week[day0.weekday - 1];

  // Streak: walk back from today until a miss (or before any plan began, or
  // before the couple linked).
  var earliest = _earliestDay([...mine, ...theirs]);
  if (earliest != null && linkDay != null && linkDay.isAfter(earliest)) {
    earliest = linkDay;
  }
  var streak = 0;
  DateTime? streakStart;
  if (earliest != null) {
    for (var i = 0; i <= lookbackDays; i++) {
      final date = DateTime(day0.year, day0.month, day0.day - i);
      if (date.isBefore(earliest)) break;
      final day = i == 0 ? todayDay : dayAt(date);
      if (day.isDuoDay) {
        streak++;
        streakStart = date;
        continue;
      }
      if (day.isToday) continue; // in progress never breaks the streak
      if (day.hasMiss) break;
      // Off for both, or rest passes only: skipped.
    }
  }

  return DuoStats(
    streak: streak,
    streakStart: streakStart,
    today: todayDay,
    week: week,
    hasPartner: hasPartner,
  );
}

/// One person's [DuoPersonDay] on [date] from their [plans], given [today].
/// Exposed for tests and for callers that need a single day.
DuoPersonDay duoPersonDayOf(
  List<Plan> plans,
  DateTime date, {
  required DateTime today,
}) {
  return _personDay(
    plans.map(_PlanDays.new).toList(),
    _dateOnly(date),
    _dateOnly(today),
  );
}

DuoPersonDay _personDay(List<_PlanDays> plans, DateTime date, DateTime today) {
  final key = _dayKey(date);
  var scheduled = 0;
  var uncovered = 0;
  var verified = false;
  var canBeVerified = false;
  final doneTypes = <String?>[];

  for (final p in plans) {
    final done = p.completed.contains(key);
    if (done) {
      doneTypes.add(p.plan.workoutType);
      if (p.verified.contains(key)) {
        verified = true;
      } else if (p.plan.managerId != null) {
        canBeVerified = true;
      }
    }
    if (!p.isScheduledOn(date)) continue;
    scheduled++;
    final covered = done || p.rested.contains(key) || p.rescued.contains(key);
    if (!covered) uncovered++;
  }

  if (date.isAfter(today)) {
    return scheduled > 0
        ? const DuoPersonDay(status: DuoDayStatus.upcoming)
        : DuoPersonDay.off;
  }
  if (uncovered > 0) {
    return DuoPersonDay(
      status: date == today ? DuoDayStatus.pending : DuoDayStatus.missed,
      doneWorkoutTypes: List.unmodifiable(doneTypes),
    );
  }
  if (doneTypes.isNotEmpty) {
    return DuoPersonDay(
      status: DuoDayStatus.done,
      verification: verified
          ? DuoVerification.verified
          : canBeVerified
          ? DuoVerification.waiting
          : DuoVerification.none,
      doneWorkoutTypes: List.unmodifiable(doneTypes),
    );
  }
  if (scheduled > 0) return const DuoPersonDay(status: DuoDayStatus.rested);
  return DuoPersonDay.off;
}

/// A plan with its record dates as day keys, for O(1) lookups.
class _PlanDays {
  _PlanDays(this.plan)
    : completed = _keys(plan.completedDates),
      rested = _keys(plan.restedDates),
      rescued = _keys(plan.rescuedDates),
      verified = _keys(plan.verifiedDates),
      _start = _dateOnly(plan.startDate),
      _end = _dateOnly(plan.endDate),
      _weekdays = plan.items.expand((item) => item.days).toSet();

  final Plan plan;
  final Set<int> completed;
  final Set<int> rested;
  final Set<int> rescued;
  final Set<int> verified;
  final DateTime _start;
  final DateTime _end;
  final Set<int> _weekdays;

  /// Whether this plan asks for a record on [date].
  bool isScheduledOn(DateTime date) {
    if (plan.state != PlanState.active && plan.state != PlanState.completed) {
      return false;
    }
    if (plan.items.isEmpty) return false;
    if (date.isBefore(_start) || date.isAfter(_end)) return false;
    // Old plans saved without days meant "every day".
    return _weekdays.isEmpty || _weekdays.contains(date.weekday);
  }

  /// The first day this plan can matter: its start, or an earlier record.
  DateTime get earliestDay {
    var earliest = _start;
    for (final d in plan.completedDates) {
      final day = _dateOnly(d);
      if (day.isBefore(earliest)) earliest = day;
    }
    return earliest;
  }
}

DateTime? _earliestDay(List<_PlanDays> plans) {
  DateTime? earliest;
  for (final p in plans) {
    final day = p.earliestDay;
    if (earliest == null || day.isBefore(earliest)) earliest = day;
  }
  return earliest;
}

Set<int> _keys(List<DateTime> dates) => {for (final d in dates) _dayKey(d)};

int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _listEquals(List<String?> a, List<String?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Total 인정 the owner of [myPlans] has received: one per acknowledged day
/// per plan. Drives the "3rd 인정" review prompt.
int countVerificationsReceived(Iterable<Plan> myPlans) {
  var count = 0;
  for (final plan in myPlans) {
    count += _keys(plan.verifiedDates).length;
  }
  return count;
}
