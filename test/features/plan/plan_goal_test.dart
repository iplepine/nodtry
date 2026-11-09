import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/plan_goal.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';

Plan _plan({String? goalTitle, DateTime? goalDate, String? id = 'p1'}) {
  return Plan(
    id: id,
    userId: 'me',
    managerId: 'partner',
    startDate: DateTime(2026, 11, 1),
    endDate: DateTime(2026, 11, 28, 23, 59, 59),
    state: PlanState.active,
    createdAt: DateTime(2026, 11, 1),
    items: [
      PlanItem(title: '헬스 가기', days: const [1, 3, 5], count: 3),
    ],
    workoutType: 'gym',
    goalTitle: goalTitle,
    goalDate: goalDate,
  );
}

void main() {
  group('planGoalCountdown', () {
    final now = DateTime(2026, 11, 9, 14, 30);

    test('no goal, no countdown', () {
      expect(planGoalCountdown(null, now), isNull);
    });

    test('counts whole calendar days before the goal', () {
      expect(
        planGoalCountdown(DateTime(2026, 12, 2), now),
        const PlanGoalCountdown(PlanGoalPhase.before, 23),
      );
      expect(
        planGoalCountdown(DateTime(2026, 11, 10), now),
        const PlanGoalCountdown(PlanGoalPhase.before, 1),
      );
    });

    test('the time of day of either value never matters', () {
      // 23:59 the night before is still D-1, 00:00 on the day is D-day.
      expect(
        planGoalCountdown(
          DateTime(2026, 11, 10, 3),
          DateTime(2026, 11, 9, 23, 59, 59),
        ),
        const PlanGoalCountdown(PlanGoalPhase.before, 1),
      );
      expect(
        planGoalCountdown(DateTime(2026, 11, 10), DateTime(2026, 11, 10)),
        const PlanGoalCountdown(PlanGoalPhase.today, 0),
      );
      expect(
        planGoalCountdown(
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 10, 23, 59, 59),
        ),
        const PlanGoalCountdown(PlanGoalPhase.today, 0),
      );
    });

    test('a daylight-saving switch in between does not lose a day', () {
      // Local DateTimes around the March / November DST changes elsewhere:
      // plain local difference would be 23h / 25h, but dates are compared.
      expect(
        planGoalCountdown(DateTime(2026, 3, 9), DateTime(2026, 3, 7, 12)),
        const PlanGoalCountdown(PlanGoalPhase.before, 2),
      );
      expect(
        planGoalCountdown(DateTime(2026, 11, 2), DateTime(2026, 10, 31, 1)),
        const PlanGoalCountdown(PlanGoalPhase.before, 2),
      );
    });

    test('shows D+N for a week after, then nothing', () {
      expect(
        planGoalCountdown(DateTime(2026, 11, 8), now),
        const PlanGoalCountdown(PlanGoalPhase.after, 1),
      );
      expect(
        planGoalCountdown(DateTime(2026, 11, 2), now),
        const PlanGoalCountdown(PlanGoalPhase.after, 7),
      );
      expect(planGoalCountdown(DateTime(2026, 11, 1), now), isNull);
    });

    test('works across a year boundary and a leap day', () {
      expect(
        planGoalCountdown(DateTime(2027, 1, 1), DateTime(2026, 12, 31, 23)),
        const PlanGoalCountdown(PlanGoalPhase.before, 1),
      );
      expect(
        planGoalCountdown(DateTime(2028, 3, 1), DateTime(2028, 2, 28)),
        const PlanGoalCountdown(PlanGoalPhase.before, 2),
      );
    });
  });

  group('planGoalLabel', () {
    late AppLocalizations ko;
    late AppLocalizations en;
    final now = DateTime(2026, 11, 9, 8);

    setUpAll(() async {
      ko = await AppLocalizations.delegate.load(const Locale('ko'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

    String? label(AppLocalizations l10n, String? title, DateTime? date) =>
        planGoalLabel(l10n, title: title, goalDate: date, now: now);

    test('Korean: D-23 · 제주 여행, D-day, D+3', () {
      expect(label(ko, '제주 여행', DateTime(2026, 12, 2)), 'D-23 · 제주 여행');
      expect(label(ko, '결혼식', DateTime(2026, 11, 9)), 'D-day · 결혼식');
      expect(label(ko, '바디프로필', DateTime(2026, 11, 6)), 'D+3 · 바디프로필');
      expect(label(ko, null, DateTime(2026, 12, 2)), 'D-23');
      expect(label(ko, '  ', DateTime(2026, 11, 9)), '오늘이 D-day예요');
    });

    test('English: "23 days to Jeju trip"', () {
      expect(label(en, 'Jeju trip', DateTime(2026, 12, 2)), '23 days to Jeju trip');
      expect(label(en, 'Jeju trip', DateTime(2026, 11, 10)), '1 day to Jeju trip');
      expect(label(en, 'Wedding', DateTime(2026, 11, 9)), 'Wedding is today!');
      expect(label(en, 'Wedding', DateTime(2026, 11, 8)), '1 day since Wedding');
      expect(label(en, null, DateTime(2026, 11, 19)), '10 days to go');
    });

    test('nothing without a date or after the D+7 window', () {
      expect(label(ko, '제주 여행', null), isNull);
      expect(label(ko, '제주 여행', DateTime(2026, 11, 1)), isNull);
    });

    test('Korean copy never uses 님 or 애인', () {
      final texts = [
        ko.planGoalToggle,
        ko.planGoalHint,
        ko.planGoalNeedsDate,
        ko.planGoalDetailAdd,
        ko.planGoalSaved,
        ko.planGoalRemoved,
        ko.planGoalSaveError,
      ];
      for (final text in texts) {
        expect(text, isNot(contains('님')));
        expect(text, isNot(contains('애인')));
      }
    });
  });

  group('normalizePlanGoalTitle', () {
    test('trims, and empty means no title', () {
      expect(normalizePlanGoalTitle(null), isNull);
      expect(normalizePlanGoalTitle('   '), isNull);
      expect(normalizePlanGoalTitle('  제주 여행 '), '제주 여행');
    });

    test('keeps at most 20 characters', () {
      expect(normalizePlanGoalTitle('가' * 25), '가' * 20);
      expect(normalizePlanGoalTitle('💪' * 20), '💪' * 20);
    });

    test('never splits an emoji and stays within the rules cap', () {
      const family = '👨‍👩‍👧'; // one character, 8 UTF-16 units
      final title = normalizePlanGoalTitle(family * 10)!;
      expect(title.length, lessThanOrEqualTo(kPlanGoalTitleMaxUnits));
      expect(title, family * 5);
    });
  });

  group('Plan goal fields', () {
    test('round-trip through toMap / fromMap', () {
      final plan = _plan(goalTitle: '제주 여행', goalDate: DateTime(2026, 12, 2));
      final map = plan.toMap();

      expect(map['goalTitle'], '제주 여행');
      final stored = map['goalDate'] as Timestamp;
      expect(stored.toDate().toUtc(), DateTime.utc(2026, 12, 2));

      final back = Plan.fromMap(map, 'p1');
      expect(back.goalTitle, '제주 여행');
      expect(back.goalDate, DateTime(2026, 12, 2));
    });

    test('a plan without a goal writes no goal fields (older builds)', () {
      final map = _plan().toMap();
      expect(map.containsKey('goalTitle'), isFalse);
      expect(map.containsKey('goalDate'), isFalse);

      final back = Plan.fromMap(map, 'p1');
      expect(back.goalTitle, isNull);
      expect(back.goalDate, isNull);
    });

    test('a title without a date is not written', () {
      final map = _plan(goalTitle: '제주 여행').toMap();
      expect(map.containsKey('goalTitle'), isFalse);
    });

    test('a date stored as local midnight in Seoul reads as that day', () {
      // 2026-12-02 00:00 KST = 2026-12-01 15:00 UTC.
      final kstMidnight = Timestamp.fromDate(DateTime.utc(2026, 12, 1, 15));
      expect(Plan.goalDateFromStored(kstMidnight), DateTime(2026, 12, 2));
      // ...and in New York (UTC-5).
      final nyMidnight = Timestamp.fromDate(DateTime.utc(2026, 12, 2, 5));
      expect(Plan.goalDateFromStored(nyMidnight), DateTime(2026, 12, 2));
    });

    test('malformed stored values are ignored', () {
      final map = _plan().toMap()
        ..['goalTitle'] = ''
        ..['goalDate'] = '2026-12-02';
      final back = Plan.fromMap(map, 'p1');
      expect(back.goalTitle, isNull);
      expect(back.goalDate, isNull);
    });

    test('copyWith keeps the goal unless it is cleared', () {
      final plan = _plan(goalTitle: '결혼식', goalDate: DateTime(2027, 5, 1));
      final kept = plan.copyWith(lastUpdatedBy: 'me');
      expect(kept.goalTitle, '결혼식');
      expect(kept.goalDate, DateTime(2027, 5, 1));

      final cleared = plan.copyWith(clearGoal: true);
      expect(cleared.goalTitle, isNull);
      expect(cleared.goalDate, isNull);

      final changed = plan.copyWith(goalDate: DateTime(2027, 6, 1));
      expect(changed.goalTitle, '결혼식');
      expect(changed.goalDate, DateTime(2027, 6, 1));
    });

    test('a restart template carries the goal', () {
      final plan = _plan(goalTitle: '결혼식', goalDate: DateTime(2027, 5, 1));
      final template = plan.asRestartTemplate();
      expect(template.id, isNull);
      expect(template.goalTitle, '결혼식');
      expect(template.goalDate, DateTime(2027, 5, 1));
    });
  });
}
