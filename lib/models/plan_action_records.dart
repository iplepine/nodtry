// plans 기록 배열 → actions 정규화, 1단계 (docs/work/REMAINING_IMPROVEMENTS.md
// §3): the app reads a plan's record days from its `actions` documents first
// and falls back to the plan's arrays for days that have no action (records
// from before every record had one, a write that only half landed, a
// partner's record not shared with me yet). The two are merged day by day —
// a union — so no day that either source has ever disappears.
//
// The arrays are still written (dual write): builds ≤ 1.1.2+87 and the Cloud
// Functions read only them. A merged [Plan] keeps the arrays as stored
// ([Plan.storedRecordDates]) so writing it back never copies action days
// into them.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'plan_model.dart';

/// The `actions.type` values a plan record array mirrors (never changed,
/// spec §9). `done` ↔ `completedDates`, `skipped` ↔ `skippedDates`, `rested`
/// ↔ `restedDates`, `rescued` ↔ `rescuedDates`. `verifiedDates` is not a
/// type: it mirrors `actions.verifiedBy` on any record.
enum ActionRecordType {
  done('done'),
  skipped('skipped'),
  rested('rested'),
  rescued('rescued');

  const ActionRecordType(this.id);

  /// The stored `actions.type`.
  final String id;

  /// The type stored as [value], or null for anything else.
  static ActionRecordType? fromId(Object? value) {
    for (final type in values) {
      if (type.id == value) return type;
    }
    return null;
  }
}

/// The part of one `actions` document that a plan's record arrays mirror.
class PlanActionRecord {
  const PlanActionRecord({
    required this.id,
    required this.planId,
    required this.userId,
    required this.type,
    required this.date,
    this.verified = false,
  });

  /// The `actions` document id.
  final String id;
  final String planId;

  /// The record's owner (`actions.userId`) — the plan owner's for every type,
  /// a 실천 인정 (`rescued`) included.
  final String userId;
  final ActionRecordType type;

  /// `actions.date`: the record's moment (for `rescued`, the rescued day).
  final DateTime date;

  /// The partner gave this record 인정 (`actions.verifiedBy` set).
  final bool verified;

  /// The record [map] stands for, or null when it can't stand for a plan
  /// record: no plan or owner, no date, or an unknown type.
  static PlanActionRecord? fromMap(Map<String, dynamic> map, String id) {
    final planId = map['planId'];
    final userId = map['userId'];
    final date = map['date'];
    final type = ActionRecordType.fromId(map['type']);
    if (planId is! String || planId.isEmpty) return null;
    if (userId is! String || userId.isEmpty) return null;
    if (date is! Timestamp || type == null) return null;
    final verifiedBy = map['verifiedBy'];
    return PlanActionRecord(
      id: id,
      planId: planId,
      userId: userId,
      type: type,
      date: date.toDate(),
      verified: verifiedBy is String && verifiedBy.isNotEmpty,
    );
  }
}

/// A plan's five record arrays, as stored on the plan document.
class PlanRecordDates {
  const PlanRecordDates({
    this.completed = const [],
    this.skipped = const [],
    this.verified = const [],
    this.rescued = const [],
    this.rested = const [],
  });

  final List<DateTime> completed;
  final List<DateTime> skipped;
  final List<DateTime> verified;
  final List<DateTime> rescued;
  final List<DateTime> rested;

  /// The record days [records] alone stand for — what the plan would show
  /// once the arrays are gone (each record day once).
  factory PlanRecordDates.fromActions(Iterable<PlanActionRecord> records) {
    List<DateTime> of(bool Function(PlanActionRecord) test) =>
        unionRecordDays(const [], [
          for (final r in records)
            if (test(r)) r.date,
        ]);
    return PlanRecordDates(
      completed: of((r) => r.type == ActionRecordType.done),
      skipped: of((r) => r.type == ActionRecordType.skipped),
      verified: of((r) => r.verified),
      rescued: of((r) => r.type == ActionRecordType.rescued),
      rested: of((r) => r.type == ActionRecordType.rested),
    );
  }
}

int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// [stored] plus one moment for each local day of [fromActions] that
/// [stored] doesn't have (the latest one of that day), oldest first.
///
/// Returns [stored] itself when the actions add no day, so a plan whose
/// arrays and actions agree keeps exactly what it had (same moments, same
/// order, same duplicates — e.g. two 인정 on one day).
List<DateTime> unionRecordDays(
  List<DateTime> stored,
  Iterable<DateTime> fromActions,
) {
  final known = {for (final d in stored) _dayKey(d)};
  final added = <int, DateTime>{};
  for (final d in fromActions) {
    final key = _dayKey(d);
    if (known.contains(key)) continue;
    final previous = added[key];
    if (previous == null || d.isAfter(previous)) added[key] = d;
  }
  if (added.isEmpty) return stored;
  return [...stored, ...added.values]..sort();
}

extension PlanActionRecordMerge on Plan {
  /// This plan with its record days read from [records] first: each array
  /// gains the days its records have and it lacks (see [unionRecordDays]).
  /// Only records of this plan by its owner count — never a partner's
  /// "같이 했어" record, which names this plan but belongs to theirs.
  ///
  /// The result keeps the stored arrays in [Plan.storedRecordDates], which
  /// [Plan.toMap] writes. Returns this plan itself when nothing is added.
  Plan withActionRecords(Iterable<PlanActionRecord> records) {
    final planId = id;
    if (planId == null) return this;
    final own = [
      for (final r in records)
        if (r.planId == planId && r.userId == userId) r,
    ];
    if (own.isEmpty) return this;
    Iterable<DateTime> datesOf(bool Function(PlanActionRecord) test) => [
      for (final r in own)
        if (test(r)) r.date,
    ];
    final completed = unionRecordDays(
      completedDates,
      datesOf((r) => r.type == ActionRecordType.done),
    );
    final skipped = unionRecordDays(
      skippedDates,
      datesOf((r) => r.type == ActionRecordType.skipped),
    );
    final verified = unionRecordDays(verifiedDates, datesOf((r) => r.verified));
    final rescued = unionRecordDays(
      rescuedDates,
      datesOf((r) => r.type == ActionRecordType.rescued),
    );
    final rested = unionRecordDays(
      restedDates,
      datesOf((r) => r.type == ActionRecordType.rested),
    );
    if (identical(completed, completedDates) &&
        identical(skipped, skippedDates) &&
        identical(verified, verifiedDates) &&
        identical(rescued, rescuedDates) &&
        identical(rested, restedDates)) {
      return this;
    }
    return copyWith(
      completedDates: completed,
      skippedDates: skipped,
      verifiedDates: verified,
      rescuedDates: rescued,
      restedDates: rested,
      storedRecordDates: persistedRecordDates,
    );
  }
}

/// Every plan of [plans] merged with its own [records]
/// ([PlanActionRecordMerge.withActionRecords]).
List<Plan> mergePlanActionRecords(
  List<Plan> plans,
  Iterable<PlanActionRecord> records,
) {
  final byPlan = <String, List<PlanActionRecord>>{};
  for (final r in records) {
    byPlan.putIfAbsent(r.planId, () => []).add(r);
  }
  if (byPlan.isEmpty) return plans;
  return [
    for (final plan in plans)
      plan.withActionRecords(byPlan[plan.id] ?? const []),
  ];
}
