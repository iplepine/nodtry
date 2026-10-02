import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/workout_template.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';

void main() {
  late AppLocalizations ko;
  late AppLocalizations en;

  setUpAll(() async {
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('WorkoutType', () {
    test(
      'ids are exactly the plans.workoutType values of the data contract',
      () {
        expect(WorkoutType.values.map((type) => type.id).toList(), [
          'gym',
          'running',
          'home_training',
          'walking',
          'pilates',
          'yoga',
          'stretching',
          'swimming',
          'climbing',
          'cycling',
          'hiking',
          'strength',
          'diet',
          'other',
        ]);
      },
    );

    test('fromId: legacy plans have none, unknown values fall back', () {
      expect(WorkoutType.fromId(null), isNull);
      expect(WorkoutType.fromId(''), isNull);
      expect(WorkoutType.fromId('kickboxing'), WorkoutType.other);
      for (final type in WorkoutType.values) {
        expect(WorkoutType.fromId(type.id), type);
      }
    });

    test('only diet is not a workout', () {
      expect(WorkoutType.values.where((type) => !type.isWorkout), [
        WorkoutType.diet,
      ]);
    });

    test('the custom tile shows a pencil but reads as a workout', () {
      expect(WorkoutType.other.tileEmoji, '✏️');
      expect(WorkoutType.other.emoji, '💪');
      expect(WorkoutType.gym.tileEmoji, WorkoutType.gym.emoji);
    });
  });

  group('workoutDisplayFor', () {
    test('is null for plans without a workout type', () {
      expect(workoutDisplayFor(ko, null), isNull);
      expect(workoutDisplayFor(ko, ''), isNull);
    });

    test('gives a label and emoji for "오늘 {운동} 했어?"', () {
      final gym = workoutDisplayFor(ko, 'gym')!;
      expect(gym.name, '헬스');
      expect(gym.emoji, '🏋️');
      expect(gym.isWorkout, isTrue);

      final diet = workoutDisplayFor(ko, 'diet')!;
      expect(diet.name, '식단');
      expect(diet.isWorkout, isFalse);

      final other = workoutDisplayFor(ko, 'other')!;
      expect(other.name, '운동');
      expect(other.emoji, '💪');

      expect(workoutDisplayFor(en, 'home_training')!.name, 'Home workout');
    });
  });

  group('workout templates', () {
    for (final locale in ['ko', 'en']) {
      test(
        '$locale: every tile has a label, line, days and a preset deadline',
        () {
          final l10n = locale == 'ko' ? ko : en;
          final templates = workoutTemplatesFor(l10n);
          final presets = workoutDeadlinePresets(l10n);

          expect(templates.map((t) => t.type), WorkoutType.values);
          for (final template in templates) {
            expect(template.label, isNotEmpty, reason: template.id);
            expect(template.id, template.type.id);
            if (template.type == WorkoutType.other) {
              expect(template.action, isEmpty);
              expect(template.categoryId, planCategoryCustom);
            } else {
              expect(template.action, isNotEmpty, reason: template.id);
              expect(template.categoryId, planCategoryExercise);
            }
            expect(
              template.selectedDayIndexes,
              isNotEmpty,
              reason: template.id,
            );
            expect(
              template.selectedDayIndexes.every((d) => d >= 0 && d <= 6),
              isTrue,
            );
            expect(
              presets.any((preset) => preset.matches(template.deadline)),
              isTrue,
              reason: '${template.id} deadline should be a chip',
            );
          }
        },
      );
    }

    test('Korean tile labels match the spec', () {
      expect(workoutTemplatesFor(ko).map((t) => t.label).toList(), [
        '헬스',
        '러닝',
        '홈트',
        '걷기',
        '필라테스',
        '요가',
        '스트레칭',
        '수영',
        '클라이밍',
        '자전거',
        '등산',
        '근력 운동',
        '식단·야식 참기',
        '직접 입력',
      ]);
    });
  });

  group('presets', () {
    test('frequency chips', () {
      expect(workoutFrequencyPresets(ko).map((p) => p.label).toList(), [
        '주 2일',
        '주 3일',
        '평일',
        '주말',
        '매일',
      ]);
    });

    test('deadline chips are once a day with no "off" option', () {
      final presets = workoutDeadlinePresets(ko);
      expect(presets.map((p) => p.label).toList(), [
        '아침 7시',
        '점심 12시',
        '저녁 7시',
        '밤 9시',
        '밤 10시',
      ]);
      expect(presets.map((p) => p.hour).toList(), [7, 12, 19, 21, 22]);
      expect(presets.every((p) => p.time.type != 'none'), isTrue);

      final night = presets.firstWhere((p) => p.id == 'night');
      expect(night.matches(NotificationTime.custom(21, 0)), isTrue);
      expect(night.matches(NotificationTime.custom(21, 30)), isFalse);
      expect(
        night.matches(NotificationTime.custom(21, 0, alertOffset: -10)),
        isFalse,
      );
      expect(
        night.matches(
          NotificationTime.hourly(intervalHours: 2, startHour: 21, endHour: 23),
        ),
        isFalse,
      );
      expect(night.matches(NotificationTime.none()), isFalse);
    });
  });

  group('Plan.workoutType', () {
    Plan plan({String? workoutType}) => Plan(
      id: 'p',
      userId: 'u',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 28, 23, 59, 59),
      state: PlanState.active,
      createdAt: DateTime(2026, 5, 1),
      workoutType: workoutType,
      items: [
        PlanItem(title: '30분 달리기', days: const [1], count: 1),
      ],
    );

    test('is written only when set and read back', () {
      expect(plan().toMap().containsKey('workoutType'), isFalse);

      final map = plan(workoutType: 'running').toMap();
      expect(map['workoutType'], 'running');
      expect(Plan.fromMap(map, 'p').workoutType, 'running');
    });

    test('old documents (missing or empty) read as null', () {
      final map = plan().toMap();
      expect(Plan.fromMap(map, 'p').workoutType, isNull);
      expect(
        Plan.fromMap({...map, 'workoutType': ''}, 'p').workoutType,
        isNull,
      );
      expect(
        Plan.fromMap({
          ...map,
          'startDate': Timestamp.fromDate(DateTime(2026, 5, 1)),
          'workoutType': 7,
        }, 'p').workoutType,
        isNull,
      );
    });

    test('survives copyWith and restart', () {
      final running = plan(workoutType: 'running');
      expect(
        running.copyWith(state: PlanState.completed).workoutType,
        'running',
      );
      expect(running.asRestartTemplate().workoutType, 'running');
      expect(running.asRestartTemplate().id, isNull);
    });
  });
}
