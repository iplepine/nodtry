import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/plan_model.dart';

Plan _finishedPlan() {
  final start = DateTime(2026, 9, 1);
  return Plan(
    id: 'finished-plan',
    userId: 'owner',
    managerId: 'partner',
    startDate: start,
    endDate: DateTime(2026, 9, 28, 23, 59, 59),
    state: PlanState.completed,
    createdAt: start,
    items: [
      PlanItem(title: '30분 달리기', days: const [2, 4, 6], count: 3),
    ],
    completedDates: [DateTime(2026, 9, 2), DateTime(2026, 9, 4)],
    verifiedDates: [DateTime(2026, 9, 2)],
    restedDates: [DateTime(2026, 9, 6)],
    lastActionNote: '숨 찼다',
    lastComment: '멋져',
    lastActionId: 'action-9',
  );
}

void main() {
  group('Plan.lastActionId', () {
    test('round-trips through toMap/fromMap and copyWith', () {
      final plan = _finishedPlan();
      final map = plan.toMap();
      expect(map['lastActionId'], 'action-9');

      final parsed = Plan.fromMap(map, 'finished-plan');
      expect(parsed.lastActionId, 'action-9');
      expect(
        parsed.copyWith(lastActionId: 'action-10').lastActionId,
        'action-10',
      );
      expect(parsed.copyWith(lastComment: 'x').lastActionId, 'action-9');
    });

    test('is optional for documents written by older app versions', () {
      final map = _finishedPlan().toMap()..remove('lastActionId');
      final parsed = Plan.fromMap(map, 'legacy');
      expect(parsed.lastActionId, isNull);
      expect(parsed.toMap().containsKey('lastActionId'), isFalse);
    });

    test('a null value is not written (keeps the server field on update)', () {
      final plan = Plan(
        userId: 'owner',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 28),
        state: PlanState.active,
        createdAt: DateTime(2026, 10, 1),
        items: [
          PlanItem(title: '걷기', days: const [1], count: 1),
        ],
      );
      expect(plan.toMap().containsKey('lastActionId'), isFalse);
    });
  });

  group('Plan.asRestartTemplate', () {
    test('drops the document id so saving creates a new plan', () {
      final plan = _finishedPlan();
      // The bug: copyWith(id: null) keeps the id (`id ?? this.id`).
      expect(plan.copyWith(id: null).id, 'finished-plan');

      final template = plan.asRestartTemplate();
      expect(template.id, isNull);
    });

    test('keeps the content and drops the history', () {
      final template = _finishedPlan().asRestartTemplate();
      expect(template.userId, 'owner');
      expect(template.managerId, 'partner');
      expect(template.items.single.title, '30분 달리기');
      expect(template.items.single.days, [2, 4, 6]);
      expect(template.completedDates, isEmpty);
      expect(template.verifiedDates, isEmpty);
      expect(template.restedDates, isEmpty);
      expect(template.lastActionNote, isNull);
      expect(template.lastComment, isNull);
      expect(template.lastActionId, isNull);
      expect(template.promise, isNull);
    });
  });

  group('Plan.periodStartingOn', () {
    test('runs from 00:00 to 23:59:59 of the 28th day', () {
      final period = Plan.periodStartingOn(DateTime(2026, 10, 2, 21, 30));
      expect(period.start, DateTime(2026, 10, 2));
      expect(period.end, DateTime(2026, 10, 29, 23, 59, 59));
    });

    test('crosses month and year boundaries', () {
      final period = Plan.periodStartingOn(DateTime(2026, 12, 20, 8));
      expect(period.start, DateTime(2026, 12, 20));
      expect(period.end, DateTime(2027, 1, 16, 23, 59, 59));
    });

    test('is what Firestore stores as Timestamps', () {
      final period = Plan.periodStartingOn(DateTime(2026, 10, 2));
      expect(Timestamp.fromDate(period.start).toDate(), period.start);
    });
  });
}
