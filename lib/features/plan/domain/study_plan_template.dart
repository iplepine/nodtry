import '../../../models/plan_model.dart';

class StudyPlanTemplate {
  final String id;
  final String label;
  final String action;
  final String description;
  final Set<int> selectedDayIndexes; // 0=Mon, 6=Sun
  final NotificationTime notificationTime;

  StudyPlanTemplate({
    required this.id,
    required this.label,
    required this.action,
    required this.description,
    required this.selectedDayIndexes,
    required this.notificationTime,
  });

  int get weeklyCount => selectedDayIndexes.length;
}

final studyPlanTemplates = <StudyPlanTemplate>[
  StudyPlanTemplate(
    id: 'english_sentences',
    label: '영어',
    action: '영어 문장 10개 소리내어 읽기',
    description: '부담 없이 매일 영어에 노출되는 것을 목표로 해요.',
    selectedDayIndexes: const {0, 1, 2, 3, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'certificate_questions',
    label: '자격증',
    action: '기출 10문제 풀기',
    description: '많이 풀기보다 정해진 문제 수를 끊기지 않게 반복해요.',
    selectedDayIndexes: const {0, 1, 2, 3, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'coding_study',
    label: '코딩',
    action: '30분 코딩 공부 또는 문제 1개',
    description: '과한 목표 대신 손을 대는 날을 먼저 확보해요.',
    selectedDayIndexes: const {0, 2, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'reading_note',
    label: '독서',
    action: '10쪽 읽고 한 줄 기록',
    description: '읽은 흔적을 한 줄로 남겨 파트너가 확인하기 쉽게 해요.',
    selectedDayIndexes: const {0, 2, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
  StudyPlanTemplate(
    id: 'writing_session',
    label: '글쓰기',
    action: '15분 쓰기 또는 300자 작성',
    description: '완성보다 쓰기 시작한 날을 만드는 데 집중해요.',
    selectedDayIndexes: const {0, 2, 4},
    notificationTime: NotificationTime.custom(21, 0),
  ),
];
