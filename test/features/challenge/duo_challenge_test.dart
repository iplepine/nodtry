import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/challenge/domain/duo_challenge.dart';
import 'package:nod_try/models/plan_model.dart';

Plan _plan({
  String? id = 'p',
  PlanState state = PlanState.active,
  String? challengeId,
  DateTime? createdAt,
  DateTime? end,
}) => Plan(
  id: id,
  userId: 'me',
  startDate: DateTime(2026, 12, 20),
  endDate: end ?? DateTime(2027, 1, 16, 23, 59, 59),
  state: state,
  items: [
    PlanItem(title: '러닝', days: const [1, 3, 5], count: 3),
  ],
  createdAt: createdAt ?? DateTime(2026, 12, 20),
  challengeId: challengeId,
);

void main() {
  final c = kNewYear2027Challenge;

  test('the New Year challenge is 21 days, Jan 1 to Jan 21', () {
    expect(c.id, 'newyear2027_duo21');
    expect(c.totalDays, 21);
    expect(c.start, DateTime(2027, 1, 1));
    expect(c.end, DateTime(2027, 1, 21));
  });

  test('phases: announced, running, result, gone', () {
    expect(c.phaseOn(DateTime(2026, 12, 17, 23, 59)), ChallengePhase.none);
    expect(c.phaseOn(DateTime(2026, 12, 18)), ChallengePhase.teaser);
    expect(c.phaseOn(DateTime(2026, 12, 31, 23, 59)), ChallengePhase.teaser);
    expect(c.phaseOn(DateTime(2027, 1, 1)), ChallengePhase.running);
    expect(c.phaseOn(DateTime(2027, 1, 21, 23, 59)), ChallengePhase.running);
    expect(c.phaseOn(DateTime(2027, 1, 22)), ChallengePhase.result);
    expect(c.phaseOn(DateTime(2027, 1, 28, 12)), ChallengePhase.result);
    expect(c.phaseOn(DateTime(2027, 1, 29)), ChallengePhase.none);
  });

  test('day numbers and countdowns', () {
    expect(c.daysUntilStart(DateTime(2026, 12, 27)), 5);
    expect(c.daysUntilStart(DateTime(2027, 1, 1)), 0);
    expect(c.daysUntilStart(DateTime(2027, 1, 5)), 0);
    expect(c.dayNumberOn(DateTime(2026, 12, 31)), 0);
    expect(c.dayNumberOn(DateTime(2027, 1, 1, 8)), 1);
    expect(c.dayNumberOn(DateTime(2027, 1, 7, 22)), 7);
    expect(c.dayNumberOn(DateTime(2027, 1, 21)), 21);
    expect(c.dayNumberOn(DateTime(2027, 1, 25)), 21);
    expect(c.daysLeftFrom(DateTime(2027, 1, 1)), 21);
    expect(c.daysLeftFrom(DateTime(2027, 1, 21)), 1);
    expect(c.daysLeftFrom(DateTime(2027, 1, 22)), 0);
  });

  test('a promise made for it runs from today to the last day', () {
    final late = c.planPeriodFrom(DateTime(2027, 1, 5, 21, 30));
    expect(late.start, DateTime(2027, 1, 5));
    expect(late.end, DateTime(2027, 1, 21, 23, 59, 59));
    // Made early, it starts on the first day.
    final early = c.planPeriodFrom(DateTime(2026, 12, 30));
    expect(early.start, DateTime(2027, 1, 1));
    expect(early.end, DateTime(2027, 1, 21, 23, 59, 59));
  });

  test('activeChallengeOn finds the one in its window', () {
    expect(activeChallengeOn(DateTime(2026, 11, 21)), isNull);
    expect(activeChallengeOn(DateTime(2026, 12, 25)), same(c));
    expect(activeChallengeOn(DateTime(2027, 1, 10)), same(c));
    expect(activeChallengeOn(DateTime(2027, 2, 1)), isNull);
    expect(
      activeChallengeOn(DateTime(2027, 1, 10), challenges: const []),
      isNull,
    );
  });

  test('entered: any promise carrying the id, stopped ones too', () {
    expect(hasEnteredChallenge([_plan()], c), isFalse);
    expect(hasEnteredChallenge([_plan(challengeId: 'other')], c), isFalse);
    expect(hasEnteredChallenge([_plan(challengeId: c.id)], c), isTrue);
    expect(
      hasEnteredChallenge([
        _plan(challengeId: c.id, state: PlanState.stopped),
      ], c),
      isTrue,
    );
  });

  test(
    'the enterable promise is the newest running one, not in a challenge',
    () {
      final today = DateTime(2027, 1, 3);
      final old = _plan(id: 'old', createdAt: DateTime(2026, 12, 1));
      final newer = _plan(id: 'newer', createdAt: DateTime(2026, 12, 20));
      expect(enterablePlanOf([old, newer], c, today: today)?.id, 'newer');
      expect(
        enterablePlanOf(
          [
            _plan(id: 'stopped', state: PlanState.stopped),
            _plan(id: 'entered', challengeId: 'x'),
            _plan(id: 'over', end: DateTime(2027, 1, 2, 23, 59, 59)),
            _plan(id: null),
          ],
          c,
          today: today,
        ),
        isNull,
      );
    },
  );

  test('challengeId round-trips through the plan document', () {
    final map = _plan(challengeId: c.id).toMap();
    expect(map['challengeId'], c.id);
    expect(Plan.fromMap(map, 'p').challengeId, c.id);
    // Absent when not entered, so older builds and the server see no change.
    expect(_plan().toMap().containsKey('challengeId'), isFalse);
    expect(Plan.fromMap(_plan().toMap(), 'p').challengeId, isNull);
    expect(
      _plan(challengeId: c.id).copyWith(state: PlanState.stopped).challengeId,
      c.id,
    );
    // Starting a promise over does not enter the new one.
    expect(_plan(challengeId: c.id).asRestartTemplate().challengeId, isNull);
  });
}
