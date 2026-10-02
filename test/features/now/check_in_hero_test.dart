import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/presentation/cards/check_in_question.dart';
import 'package:nod_try/features/now/presentation/cards/now_card_rules.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/repositories/real_record_repository.dart';

/// Friday 2026-10-02, 09:00.
final _morning = DateTime(2026, 10, 2, 9);

Plan _plan({
  List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  int hour = 22,
  String? workoutType = 'gym',
  String title = '퇴근하고 헬스',
  List<DateTime> completed = const [],
  List<DateTime> skipped = const [],
  List<DateTime> rested = const [],
}) {
  return Plan(
    id: 'plan-1',
    userId: 'me',
    startDate: DateTime(2026, 9, 28),
    endDate: DateTime(2026, 10, 25, 23, 59, 59),
    state: PlanState.active,
    createdAt: DateTime(2026, 9, 28),
    workoutType: workoutType,
    completedDates: completed,
    skippedDates: skipped,
    restedDates: rested,
    items: [
      PlanItem(
        title: title,
        days: days,
        count: days.length,
        notificationTime: NotificationTime.custom(hour, 0),
      ),
    ],
  );
}

void main() {
  group('showsTodayCheckInHero', () {
    test('a 22:00 promise asks from 09:00, though it is not "due now" yet', () {
      final plan = _plan(hour: 22);

      // The repository still files it as nextAction (isDueNowItem unchanged)…
      expect(
        RealRecordRepository.isDueNowItem(
          hasTime: true,
          timeInMin: 22 * 60,
          nowInMinutes: _morning.hour * 60 + _morning.minute,
        ),
        isFalse,
      );
      // …and the hero shows on that nextAction card all day.
      expect(
        showsTodayCheckInHero(HomeCardState.nextAction, plan, now: _morning),
        isTrue,
      );
    });

    test('due and overdue cards show it too', () {
      final plan = _plan();
      expect(
        showsTodayCheckInHero(HomeCardState.nowAction, plan, now: _morning),
        isTrue,
      );
      expect(
        showsTodayCheckInHero(HomeCardState.overdue, plan, now: _morning),
        isTrue,
      );
    });

    test('not on a day the promise is not scheduled', () {
      // Friday is weekday 5.
      final plan = _plan(days: const [1, 3]);
      expect(
        showsTodayCheckInHero(HomeCardState.nextAction, plan, now: _morning),
        isFalse,
      );
    });

    test('gone once today is recorded — done, skipped or rested', () {
      for (final plan in [
        _plan(completed: [DateTime(2026, 10, 2, 7)]),
        _plan(skipped: [DateTime(2026, 10, 2, 8)]),
        _plan(rested: [DateTime(2026, 10, 2, 8)]),
      ]) {
        expect(
          showsTodayCheckInHero(HomeCardState.nowAction, plan, now: _morning),
          isFalse,
        );
      }
      // Yesterday's record doesn't count.
      expect(
        showsTodayCheckInHero(
          HomeCardState.nowAction,
          _plan(completed: [DateTime(2026, 10, 1, 21)]),
          now: _morning,
        ),
        isTrue,
      );
    });

    test('a knock asks about today even off-schedule', () {
      expect(
        showsTodayCheckInHero(
          HomeCardState.poked,
          _plan(days: const [1]),
          now: _morning,
        ),
        isTrue,
      );
      expect(
        showsTodayCheckInHero(
          HomeCardState.poked,
          _plan(completed: [DateTime(2026, 10, 2, 7)]),
          now: _morning,
        ),
        isFalse,
      );
    });

    test('never on other cards or without a plan', () {
      final plan = _plan();
      for (final state in HomeCardState.values) {
        if (const {
          HomeCardState.nowAction,
          HomeCardState.nextAction,
          HomeCardState.overdue,
          HomeCardState.poked,
        }.contains(state)) {
          continue;
        }
        expect(
          showsTodayCheckInHero(state, plan, now: _morning),
          isFalse,
          reason: '$state',
        );
      }
      expect(
        showsTodayCheckInHero(HomeCardState.nowAction, null, now: _morning),
        isFalse,
      );
    });
  });

  group('todayCheckInQuestion', () {
    for (final locale in const [Locale('ko'), Locale('en')]) {
      test(
        '[${locale.languageCode}] workout, diet and legacy wording',
        () async {
          final l10n = await AppLocalizations.delegate.load(locale);

          expect(
            todayCheckInQuestion(l10n, _plan(workoutType: 'running')),
            l10n.nowHeroQuestion('🏃', l10n.workoutTypeRunningLabel),
          );
          expect(
            todayCheckInQuestion(l10n, _plan(workoutType: 'diet')),
            l10n.nowHeroQuestionDiet('🥗', l10n.workoutTypeDietName),
          );
          expect(
            todayCheckInQuestion(l10n, _plan(workoutType: 'other')),
            l10n.nowHeroQuestion('💪', l10n.workoutTypeOtherName),
          );
          expect(
            todayCheckInQuestion(
              l10n,
              _plan(workoutType: null, title: '책 10쪽 읽기'),
            ),
            l10n.nowHeroQuestionLegacy('책 10쪽 읽기'),
          );
        },
      );
    }

    test('[ko] reads naturally', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(
        todayCheckInQuestion(l10n, _plan(workoutType: 'running')),
        '오늘 🏃 러닝 했어?',
      );
      expect(
        todayCheckInQuestion(l10n, _plan(workoutType: 'diet')),
        '오늘 🥗 식단 지켰어?',
      );
      expect(
        todayCheckInQuestion(l10n, _plan(workoutType: null, title: '산책')),
        "오늘 '산책' 했어?",
      );
    });
  });
}
