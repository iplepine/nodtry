import '../../../models/plan_model.dart';

const planCategoryStudy = 'study';
const planCategoryExercise = 'exercise';
const planCategoryCustom = 'custom';

class PlanCategory {
  final String id;
  final String label;
  final String description;

  const PlanCategory({
    required this.id,
    required this.label,
    required this.description,
  });
}

class StudyPlanTemplate {
  final String id;
  final String categoryId;
  final String label;
  final String action;
  final String description;
  final Set<int> selectedDayIndexes; // 0=Mon, 6=Sun
  final NotificationTime notificationTime;

  StudyPlanTemplate({
    required this.id,
    required this.categoryId,
    required this.label,
    required this.action,
    required this.description,
    required this.selectedDayIndexes,
    required this.notificationTime,
  });

  int get weeklyCount => selectedDayIndexes.length;
}

class PlanDayPreset {
  final String id;
  final String label;
  final String description;
  final Set<int> selectedDayIndexes; // 0=Mon, 6=Sun

  const PlanDayPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.selectedDayIndexes,
  });
}

const planCategories = <PlanCategory>[
  PlanCategory(
    id: planCategoryStudy,
    label: '공부',
    description: '영어, 자격증, 코딩처럼 혼자 미루는 학습',
  ),
  PlanCategory(
    id: planCategoryExercise,
    label: '운동',
    description: '걷기, 헬스장, 스트레칭처럼 시작이 어려운 움직임',
  ),
  PlanCategory(
    id: planCategoryCustom,
    label: '직접 입력',
    description: '추천 없이 내 약속을 직접 쓰기',
  ),
];

final studyPlanTemplates = <StudyPlanTemplate>[
  StudyPlanTemplate(
    id: 'english_sentences',
    categoryId: planCategoryStudy,
    label: '영어',
    action: '영어 문장 10개 소리내어 읽기',
    description: '부담 없이 매일 영어에 노출되는 것을 목표로 해요.',
    selectedDayIndexes: const {0, 1, 2, 3, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'certificate_questions',
    categoryId: planCategoryStudy,
    label: '자격증',
    action: '기출 10문제 풀기',
    description: '많이 풀기보다 정해진 문제 수를 끊기지 않게 반복해요.',
    selectedDayIndexes: const {0, 1, 2, 3, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'coding_study',
    categoryId: planCategoryStudy,
    label: '코딩',
    action: '30분 코딩 공부 또는 문제 1개',
    description: '과한 목표 대신 손을 대는 날을 먼저 확보해요.',
    selectedDayIndexes: const {0, 2, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'reading_note',
    categoryId: planCategoryStudy,
    label: '독서',
    action: '10쪽 읽고 한 줄 기록',
    description: '읽은 흔적을 한 줄로 남겨 파트너가 확인하기 쉽게 해요.',
    selectedDayIndexes: const {0, 2, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'writing_session',
    categoryId: planCategoryStudy,
    label: '글쓰기',
    action: '15분 쓰기 또는 300자 작성',
    description: '완성보다 쓰기 시작한 날을 만드는 데 집중해요.',
    selectedDayIndexes: const {0, 2, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'walking',
    categoryId: planCategoryExercise,
    label: '걷기',
    action: '30분 걷기',
    description: '운동복을 갖추는 것보다 밖에 나가는 약속을 먼저 만들어요.',
    selectedDayIndexes: const {0, 2, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'gym_visit',
    categoryId: planCategoryExercise,
    label: '헬스장',
    action: '헬스장 가서 30분 운동하기',
    description: '완벽한 운동보다 헬스장에 도착하는 날을 늘려요.',
    selectedDayIndexes: const {0, 2, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'stretching',
    categoryId: planCategoryExercise,
    label: '스트레칭',
    action: '10분 스트레칭하기',
    description: '짧게라도 몸을 푸는 약속을 파트너에게 보이게 해요.',
    selectedDayIndexes: const {0, 1, 2, 3, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
];

List<PlanDayPreset> dayPresetsForCategory(String categoryId) {
  switch (categoryId) {
    case planCategoryStudy:
      return const [
        PlanDayPreset(
          id: 'study_three_days',
          label: '주 3일',
          description: '첫 주 3회 성공을 먼저 만들기',
          selectedDayIndexes: {0, 2, 4},
        ),
        PlanDayPreset(
          id: 'study_weekdays',
          label: '평일',
          description: '공부 흐름을 주중에 묶기',
          selectedDayIndexes: {0, 1, 2, 3, 4},
        ),
        PlanDayPreset(
          id: 'study_every_day',
          label: '매일',
          description: '짧게라도 매일 파트너에게 보이기',
          selectedDayIndexes: {0, 1, 2, 3, 4, 5, 6},
        ),
      ];
    case planCategoryExercise:
      return const [
        PlanDayPreset(
          id: 'exercise_three_days',
          label: '주 3일',
          description: '월수금 리듬으로 시작하기',
          selectedDayIndexes: {0, 2, 4},
        ),
        PlanDayPreset(
          id: 'exercise_weekend',
          label: '주말',
          description: '주말에 움직임을 남기기',
          selectedDayIndexes: {5, 6},
        ),
        PlanDayPreset(
          id: 'exercise_every_day',
          label: '매일',
          description: '짧은 스트레칭처럼 매일 확인받기',
          selectedDayIndexes: {0, 1, 2, 3, 4, 5, 6},
        ),
      ];
    default:
      return const [
        PlanDayPreset(
          id: 'custom_three_days',
          label: '주 3일',
          description: '부담을 낮추는 기본값',
          selectedDayIndexes: {0, 2, 4},
        ),
        PlanDayPreset(
          id: 'custom_weekdays',
          label: '평일',
          description: '주중 루틴으로 고정하기',
          selectedDayIndexes: {0, 1, 2, 3, 4},
        ),
        PlanDayPreset(
          id: 'custom_every_day',
          label: '매일',
          description: '작은 행동을 매일 남기기',
          selectedDayIndexes: {0, 1, 2, 3, 4, 5, 6},
        ),
      ];
  }
}
