import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../models/plan_action_records.dart';
import '../models/plan_model.dart';
import '../utils/error_reporter.dart';

/// Reads the `actions` behind streamed plans and merges them in
/// ([mergePlanActionRecords]): the actions-first read path of the plans →
/// actions normalization (docs/work/REMAINING_IMPROVEMENTS.md §3).
///
/// Reads stay bounded: one listener per plan owner (me, my partner), each
/// over the actions since [windowStartFor] —
///   mine:        `actions where userId == me && date >= W orderBy date desc`
///   my partner's: `actions where userId == partner && managerId == me &&
///                 date >= W orderBy date desc`
/// served by the existing (userId, date desc) and (userId, managerId, date
/// desc) indexes and allowed by firestore.rules and firestore.rules.next. W
/// is the same for every caller all week, so the home stream, the stats and
/// the plan detail share one Firestore listener per owner. Days before W
/// (and records not shared with me) come from the plan arrays alone.
///
/// The plans are emitted at once with their arrays only, then again with
/// their actions merged in: never later and never with fewer days than
/// before. A failing actions query is reported and leaves the arrays.
class PlanActionRecordsSource {
  PlanActionRecordsSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    DateTime Function()? clock,
  }) : _firestore = firestore,
       _auth = auth,
       _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final DateTime Function() _clock;

  /// How far back the actions are read: at least this many days, rounded
  /// back to a Monday. A running plan's period (28 days) always fits; so does
  /// the last week or two of a plan that just ended.
  static const int windowDays = 35;

  /// Local midnight of the Monday on or before [now] − [windowDays].
  @visibleForTesting
  static DateTime windowStartFor(DateTime now) {
    final day = DateTime(now.year, now.month, now.day - windowDays);
    return DateTime(day.year, day.month, day.day - (day.weekday - 1));
  }

  /// [plans] with each plan's actions merged in.
  Stream<List<Plan>> attach(Stream<List<Plan>> plans) {
    final me = _auth.currentUser?.uid;
    if (me == null) return plans;
    final shared = plans.shareReplay(maxSize: 1);
    final records = shared
        .map((list) => _Window.of(list, me, windowStartFor(_clock())))
        .distinct()
        .switchMap((window) => _recordsIn(window, me))
        .startWith(const <PlanActionRecord>[]);
    return Rx.combineLatest2(shared, records, mergePlanActionRecords);
  }

  Stream<List<PlanActionRecord>> _recordsIn(_Window window, String me) {
    if (window.owners.isEmpty) return Stream.value(const []);
    final perOwner = [
      for (final owner in window.owners) _recordsOf(owner, me, window.start),
    ];
    if (perOwner.length == 1) return perOwner.single;
    return Rx.combineLatestList(
      perOwner,
    ).map((lists) => [for (final list in lists) ...list]);
  }

  Stream<List<PlanActionRecord>> _recordsOf(
    String owner,
    String me,
    DateTime start,
  ) {
    var query = _firestore
        .collection('actions')
        .where('userId', isEqualTo: owner);
    if (owner != me) query = query.where('managerId', isEqualTo: me);
    return query
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              ?PlanActionRecord.fromMap(doc.data(), doc.id),
          ],
        )
        .onErrorReturnWith((Object e, StackTrace s) {
          // e.g. an index still building: the arrays alone, as before.
          ErrorReporter.record(e, s, reason: 'planActionRecords');
          return const <PlanActionRecord>[];
        });
  }
}

/// Whose actions to read, and since when.
@immutable
class _Window {
  const _Window(this.owners, this.start);

  /// The owners of the plans that can have records on or after [start] and
  /// whose actions I may list: mine, and those of plans I manage.
  factory _Window.of(List<Plan> plans, String me, DateTime start) {
    final owners = <String>{};
    for (final plan in plans) {
      if (plan.id == null || plan.endDate.isBefore(start)) continue;
      if (plan.userId == me || plan.managerId == me) owners.add(plan.userId);
    }
    return _Window(owners.toList()..sort(), start);
  }

  final List<String> owners;
  final DateTime start;

  @override
  bool operator ==(Object other) =>
      other is _Window &&
      other.start == start &&
      listEquals(other.owners, owners);

  @override
  int get hashCode => Object.hash(start, Object.hashAll(owners));
}
