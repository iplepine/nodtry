import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/application/poke_reply_store.dart';
import 'package:nod_try/features/now/presentation/cards/now_card_rules.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 10, 3, 18);

Plan _plan({
  String? managerId = 'partner',
  DateTime? lastPokeAt,
  List<DateTime> completed = const [],
  List<DateTime> rested = const [],
}) => Plan(
  id: 'plan-1',
  userId: 'me',
  managerId: managerId,
  startDate: DateTime(2026, 9, 28),
  endDate: DateTime(2026, 10, 25),
  state: PlanState.active,
  items: [
    PlanItem(title: '러닝', days: const [6], count: 1),
  ],
  createdAt: DateTime(2026, 9, 28),
  lastPokeAt: lastPokeAt,
  completedDates: completed,
  restedDates: rested,
);

void main() {
  group('knockedToday', () {
    test('one knock per promise per day', () {
      expect(knockedToday(_plan(), now: _now), isFalse);
      expect(knockedToday(null, now: _now), isFalse);
      expect(
        knockedToday(_plan(lastPokeAt: DateTime(2026, 10, 3, 9)), now: _now),
        isTrue,
      );
      expect(
        knockedToday(_plan(lastPokeAt: DateTime(2026, 10, 2, 23)), now: _now),
        isFalse,
      );
    });
  });

  group('showsPokeReplies', () {
    final knocked = DateTime(2026, 10, 3, 17);

    test('after a knock today, until something is recorded', () {
      expect(showsPokeReplies(_plan(lastPokeAt: knocked), now: _now), isTrue);
      expect(
        showsPokeReplies(
          _plan(lastPokeAt: knocked, completed: [DateTime(2026, 10, 3, 18)]),
          now: _now,
        ),
        isFalse,
      );
      expect(
        showsPokeReplies(
          _plan(lastPokeAt: knocked, rested: [DateTime(2026, 10, 3, 18)]),
          now: _now,
        ),
        isFalse,
      );
    });

    test('not without a knock today or without a partner', () {
      expect(showsPokeReplies(_plan(), now: _now), isFalse);
      expect(
        showsPokeReplies(
          _plan(lastPokeAt: DateTime(2026, 10, 2, 17)),
          now: _now,
        ),
        isFalse,
      );
      expect(
        showsPokeReplies(
          _plan(lastPokeAt: knocked, managerId: null),
          now: _now,
        ),
        isFalse,
      );
      expect(showsPokeReplies(null, now: _now), isFalse);
    });
  });

  test('leadsWithCheer only for a forwarded miss on the partner card', () {
    expect(
      leadsWithCheer(HomeCardState.partnerPoke, hasMissedNotice: true),
      isTrue,
    );
    expect(
      leadsWithCheer(HomeCardState.partnerPoke, hasMissedNotice: false),
      isFalse,
    );
    expect(
      leadsWithCheer(HomeCardState.partnerAction, hasMissedNotice: true),
      isFalse,
    );
  });

  group('PokeReplyStore', () {
    test('remembers today\'s replies across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await PokeReplyStore(prefs).markReplied('plan-1', _now);

      final again = PokeReplyStore(prefs);
      expect(again.hasReplied('plan-1', _now), isTrue);
      expect(again.hasReplied('plan-2', _now), isFalse);
      expect(again.hasReplied('plan-1', DateTime(2026, 10, 4, 8)), isFalse);
    });

    test('drops other days when recording', () async {
      SharedPreferences.setMockInitialValues({
        PokeReplyStore.prefKey: ['old@2026-10-1'],
      });
      final prefs = await SharedPreferences.getInstance();
      await PokeReplyStore(prefs).markReplied('plan-1', _now);
      expect(prefs.getStringList(PokeReplyStore.prefKey), ['plan-1@2026-10-3']);
    });

    test('works in memory without SharedPreferences', () async {
      final store = PokeReplyStore();
      await store.markReplied('plan-1', _now);
      expect(store.hasReplied('plan-1', _now), isTrue);
    });
  });
}
