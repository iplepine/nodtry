/// 월간 리캡: one calendar month of workouts, for the couple or — without a
/// partner — for me alone. Computed on the client from both people's plans
/// with the same day rules as the 둘운완 stats (`duo_stats.dart`); nothing is
/// stored.
///
/// - The headline is the month's 둘운완 days for a couple, my workout days
///   for a solo user ([DuoRecap.headlineDays]).
/// - [DuoRecap.bestStreak] is the longest run of headline days inside the
///   month: a miss ends a run, a day that is off / rest-only is skipped, and
///   today (still in progress) never ends one. A run does not carry in from
///   the month before.
/// - The top workout is the type done on the most days; a tie goes to the
///   one done first.
library;

import '../../../models/plan_model.dart';
import 'duo_stats.dart';

/// How many months back the recap can go (this month included).
const int kDuoRecapMonthsBack = 12;

/// The fewest headline days that make last month's recap worth offering by
/// itself at the start of a month.
const int kDuoRecapOfferMinDays = 3;

/// The recap is offered by itself only on the first days of a month.
const int kDuoRecapOfferLastDay = 7;

class DuoRecap {
  const DuoRecap({
    required this.month,
    required this.days,
    required this.hasPartner,
    required this.isCurrentMonth,
    required this.duoDays,
    required this.myDoneDays,
    required this.partnerDoneDays,
    required this.bestStreak,
    this.myTopWorkout,
    this.partnerTopWorkout,
  });

  /// The first day of the month (local midnight).
  final DateTime month;

  /// Every day of the month, in order.
  final List<DuoDay> days;

  /// False for a solo user: the partner side is all off.
  final bool hasPartner;

  /// The month is still running: the counts are "so far".
  final bool isCurrentMonth;

  /// Days both kept their promises (always 0 without a partner).
  final int duoDays;
  final int myDoneDays;
  final int partnerDoneDays;

  /// The longest run of [headlineDays]-days inside the month.
  final int bestStreak;

  /// `Plan.workoutType` done on the most days, or null when nothing typed
  /// was done.
  final String? myTopWorkout;
  final String? partnerTopWorkout;

  /// What the card counts big: 둘운완 days, or my workout days when solo.
  int get headlineDays => hasPartner ? duoDays : myDoneDays;

  /// Nobody worked out this month: there is nothing to show.
  bool get isEmpty => myDoneDays == 0 && partnerDoneDays == 0;

  /// Whether [day] counts toward [headlineDays].
  bool isHeadlineDay(DuoDay day) => hasPartner ? day.isDuoDay : day.me.isDone;
}

/// The first day of the month [monthsAgo] months before [today]'s.
DateTime recapMonthOf(DateTime today, {int monthsAgo = 0}) =>
    DateTime(today.year, today.month - monthsAgo);

/// 'yyyy-mm' of [month], the key a month's offer is remembered by.
String recapMonthKey(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-'
    '${month.month.toString().padLeft(2, '0')}';

/// The recap of [month] (any day in it) as of [today]. See the library
/// comment for the rules.
DuoRecap computeDuoRecap({
  required List<Plan> myPlans,
  required List<Plan> partnerPlans,
  required DateTime month,
  required DateTime today,
  bool hasPartner = true,
  DateTime? linkedSince,
}) {
  final first = DateTime(month.year, month.month);
  final last = DateTime(month.year, month.month + 1, 0);
  final day0 = DateTime(today.year, today.month, today.day);
  final days = computeDuoDays(
    myPlans: myPlans,
    partnerPlans: hasPartner ? partnerPlans : const [],
    from: first,
    to: last,
    today: today,
    hasPartner: hasPartner,
    linkedSince: linkedSince,
  );

  bool isHeadline(DuoDay day) => hasPartner ? day.isDuoDay : day.me.isDone;
  bool breaksRun(DuoDay day) =>
      hasPartner ? day.hasMiss || day.beforeLink : day.me.isMissed;

  var duoDays = 0;
  var myDone = 0;
  var partnerDone = 0;
  var run = 0;
  var best = 0;
  final myTypes = <String, int>{};
  final partnerTypes = <String, int>{};

  for (final day in days) {
    if (day.date.isAfter(day0)) break;
    if (hasPartner && day.isDuoDay) duoDays++;
    if (day.me.isDone) {
      myDone++;
      _countTypes(myTypes, day.me.doneWorkoutTypes);
    }
    if (hasPartner && !day.beforeLink && day.partner.isDone) {
      partnerDone++;
      _countTypes(partnerTypes, day.partner.doneWorkoutTypes);
    }
    if (isHeadline(day)) {
      run++;
      if (run > best) best = run;
    } else if (!day.isToday && breaksRun(day)) {
      run = 0;
    }
  }

  return DuoRecap(
    month: first,
    days: days,
    hasPartner: hasPartner,
    isCurrentMonth: first.year == day0.year && first.month == day0.month,
    duoDays: duoDays,
    myDoneDays: myDone,
    partnerDoneDays: partnerDone,
    bestStreak: best,
    myTopWorkout: _topType(myTypes),
    partnerTopWorkout: _topType(partnerTypes),
  );
}

/// One day's workout types, each counted once.
void _countTypes(Map<String, int> counts, List<String?> types) {
  for (final type in types.whereType<String>().toSet()) {
    counts[type] = (counts[type] ?? 0) + 1;
  }
}

/// The type with the most days; insertion order (first done) breaks a tie.
String? _topType(Map<String, int> counts) {
  String? top;
  var most = 0;
  counts.forEach((type, count) {
    if (count > most) {
      top = type;
      most = count;
    }
  });
  return top;
}

/// The months the recap sheet can show, newest first: this month back to the
/// month my first plan began (or my first record, when earlier), at most
/// [kDuoRecapMonthsBack]. Always holds this month.
List<DateTime> recapMonthsOf(List<Plan> myPlans, {required DateTime today}) {
  final current = recapMonthOf(today);
  DateTime? earliest;
  for (final plan in myPlans) {
    for (final date in [plan.startDate, ...plan.completedDates]) {
      if (earliest == null || date.isBefore(earliest)) earliest = date;
    }
  }
  final firstMonth = earliest == null || earliest.isAfter(today)
      ? current
      : DateTime(earliest.year, earliest.month);
  final months = <DateTime>[];
  for (var i = 0; i < kDuoRecapMonthsBack; i++) {
    final month = recapMonthOf(today, monthsAgo: i);
    if (month.isBefore(firstMonth)) break;
    months.add(month);
  }
  return months;
}

/// Whether to offer last month's recap by itself now: on the first
/// [kDuoRecapOfferLastDay] days of a month, once per month
/// ([offeredMonthKey] is the [recapMonthKey] last offered), and only when
/// last month has at least [kDuoRecapOfferMinDays] headline days.
bool shouldOfferRecap({
  required DuoRecap lastMonth,
  required DateTime today,
  required String? offeredMonthKey,
}) {
  if (today.day > kDuoRecapOfferLastDay) return false;
  final previous = recapMonthOf(today, monthsAgo: 1);
  if (lastMonth.month != previous) return false;
  if (offeredMonthKey == recapMonthKey(previous)) return false;
  return lastMonth.headlineDays >= kDuoRecapOfferMinDays;
}
