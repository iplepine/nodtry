import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/plan_model.dart';

void main() {
  test('Plan.fromMap restores separate cheer and poke fields', () {
    final pokeAt = DateTime(2026, 5, 1, 9);
    final cheerAt = DateTime(2026, 5, 1, 10);

    final plan = Plan.fromMap({
      'userId': 'executor',
      'managerId': 'manager',
      'startDate': Timestamp.fromDate(DateTime(2026, 5, 1)),
      'endDate': Timestamp.fromDate(DateTime(2026, 5, 14)),
      'state': 'active',
      'items': [
        {
          'title': '물 마시기',
          'days': [1, 2, 3, 4, 5, 6, 7],
          'count': 7,
        },
      ],
      'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
      'lastCheerType': '👍',
      'lastCheerMessage': '좋았어',
      'lastCheerAt': Timestamp.fromDate(cheerAt),
      'lastPokeMessage': '똑똑',
      'lastPokeAt': Timestamp.fromDate(pokeAt),
    }, 'plan-1');

    expect(plan.lastCheerType, '👍');
    expect(plan.lastCheerMessage, '좋았어');
    expect(plan.lastCheerAt, cheerAt);
    expect(plan.lastPokeMessage, '똑똑');
    expect(plan.lastPokeAt, pokeAt);
  });

  test('Plan.fromMap migrates legacy poke values away from cheer fields', () {
    final pokeAt = DateTime(2026, 5, 1, 9);

    final plan = Plan.fromMap({
      'userId': 'executor',
      'startDate': Timestamp.fromDate(DateTime(2026, 5, 1)),
      'endDate': Timestamp.fromDate(DateTime(2026, 5, 14)),
      'state': 'active',
      'items': [
        {
          'title': '물 마시기',
          'days': [1],
          'count': 1,
        },
      ],
      'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
      'lastCheerType': 'poke',
      'lastCheerMessage': '잊지 마',
      'lastCheerAt': Timestamp.fromDate(pokeAt),
    }, 'plan-2');

    expect(plan.lastCheerType, isNull);
    expect(plan.lastCheerMessage, isNull);
    expect(plan.lastPokeMessage, '잊지 마');
    expect(plan.lastPokeAt, pokeAt);
  });

  test('HistoryItem.fromMap keeps manager comment out of executor note', () {
    final item = HistoryItem.fromMap({
      'planId': 'plan-1',
      'date': Timestamp.fromDate(DateTime(2026, 5, 1)),
      'title': '물 마시기',
      'type': 'done',
      'userId': 'executor',
      'comment': '잘했어',
      'verifiedBy': 'manager',
    }, 'history-1');

    expect(item.note, isNull);
    expect(item.comment, '잘했어');
    expect(item.isVerifiedByPartner, isTrue);
  });
}
