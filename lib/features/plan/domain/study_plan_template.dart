import '../../../l10n/app_localizations.dart';
import '../../../models/plan_model.dart';

const planCategoryStudy = 'study';
const planCategoryExercise = 'exercise';
const planCategoryVerified = 'verified';
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

List<PlanCategory> planCategoriesFor(AppLocalizations l10n) {
  return [
    PlanCategory(
      id: planCategoryStudy,
      label: l10n.planCategoryStudyLabel,
      description: l10n.planCategoryStudyDescription,
    ),
    PlanCategory(
      id: planCategoryExercise,
      label: l10n.planCategoryExerciseLabel,
      description: l10n.planCategoryExerciseDescription,
    ),
    PlanCategory(
      id: planCategoryVerified,
      label: l10n.planCategoryVerifiedLabel,
      description: l10n.planCategoryVerifiedDescription,
    ),
    PlanCategory(
      id: planCategoryCustom,
      label: l10n.planCategoryCustomLabel,
      description: l10n.planCategoryCustomDescription,
    ),
  ];
}

List<StudyPlanTemplate> studyPlanTemplatesFor(AppLocalizations l10n) {
  return [
    StudyPlanTemplate(
      id: 'english_sentences',
      categoryId: planCategoryStudy,
      label: l10n.planTemplateEnglishLabel,
      action: l10n.planTemplateEnglishAction,
      description: l10n.planTemplateEnglishDescription,
      selectedDayIndexes: const {0, 1, 2, 3, 4},
      notificationTime: NotificationTime.custom(21, 0),
    ),
    StudyPlanTemplate(
      id: 'certificate_questions',
      categoryId: planCategoryStudy,
      label: l10n.planTemplateCertificateLabel,
      action: l10n.planTemplateCertificateAction,
      description: l10n.planTemplateCertificateDescription,
      selectedDayIndexes: const {0, 1, 2, 3, 4},
      notificationTime: NotificationTime.custom(21, 0),
    ),
    StudyPlanTemplate(
      id: 'coding_study',
      categoryId: planCategoryStudy,
      label: l10n.planTemplateCodingLabel,
      action: l10n.planTemplateCodingAction,
      description: l10n.planTemplateCodingDescription,
      selectedDayIndexes: const {0, 2, 4},
      notificationTime: NotificationTime.custom(21, 0),
    ),
    StudyPlanTemplate(
      id: 'reading_note',
      categoryId: planCategoryStudy,
      label: l10n.planTemplateReadingLabel,
      action: l10n.planTemplateReadingAction,
      description: l10n.planTemplateReadingDescription,
      selectedDayIndexes: const {0, 2, 4},
      notificationTime: NotificationTime.custom(21, 0),
    ),
    StudyPlanTemplate(
      id: 'writing_session',
      categoryId: planCategoryStudy,
      label: l10n.planTemplateWritingLabel,
      action: l10n.planTemplateWritingAction,
      description: l10n.planTemplateWritingDescription,
      selectedDayIndexes: const {0, 2, 4},
      notificationTime: NotificationTime.custom(21, 0),
    ),
    StudyPlanTemplate(
      id: 'walking',
      categoryId: planCategoryExercise,
      label: l10n.planTemplateWalkingLabel,
      action: l10n.planTemplateWalkingAction,
      description: l10n.planTemplateWalkingDescription,
      selectedDayIndexes: const {0, 2, 4},
      notificationTime: NotificationTime.custom(21, 0),
    ),
    StudyPlanTemplate(
      id: 'gym_visit',
      categoryId: planCategoryExercise,
      label: l10n.planTemplateGymLabel,
      action: l10n.planTemplateGymAction,
      description: l10n.planTemplateGymDescription,
      selectedDayIndexes: const {0, 2, 4},
      notificationTime: NotificationTime.custom(21, 0),
    ),
    StudyPlanTemplate(
      id: 'stretching',
      categoryId: planCategoryExercise,
      label: l10n.planTemplateStretchingLabel,
      action: l10n.planTemplateStretchingAction,
      description: l10n.planTemplateStretchingDescription,
      selectedDayIndexes: const {0, 1, 2, 3, 4},
      notificationTime: NotificationTime.custom(21, 0),
    ),
  ];
}

List<StudyPlanTemplate> verifiedRoutinesFor(AppLocalizations l10n) {
  return [
    StudyPlanTemplate(
      id: 'verified_morning_light',
      categoryId: planCategoryVerified,
      label: l10n.planTemplateMorningLightLabel,
      action: l10n.planTemplateMorningLightAction,
      description: l10n.planTemplateMorningLightDescription,
      selectedDayIndexes: const {0, 1, 2, 3, 4, 5, 6},
      notificationTime: NotificationTime.custom(7, 0),
    ),
    StudyPlanTemplate(
      id: 'verified_caffeine_delay',
      categoryId: planCategoryVerified,
      label: l10n.planTemplateCaffeineDelayLabel,
      action: l10n.planTemplateCaffeineDelayAction,
      description: l10n.planTemplateCaffeineDelayDescription,
      selectedDayIndexes: const {0, 1, 2, 3, 4, 5, 6},
      notificationTime: NotificationTime.custom(9, 30),
    ),
    StudyPlanTemplate(
      id: 'verified_physio_sigh',
      categoryId: planCategoryVerified,
      label: l10n.planTemplatePhysioSighLabel,
      action: l10n.planTemplatePhysioSighAction,
      description: l10n.planTemplatePhysioSighDescription,
      selectedDayIndexes: const {0, 1, 2, 3, 4, 5, 6},
      notificationTime: NotificationTime.preset('lunch'),
    ),
    StudyPlanTemplate(
      id: 'verified_focus_90',
      categoryId: planCategoryVerified,
      label: l10n.planTemplateFocus90Label,
      action: l10n.planTemplateFocus90Action,
      description: l10n.planTemplateFocus90Description,
      selectedDayIndexes: const {0, 1, 2, 3, 4},
      notificationTime: NotificationTime.custom(10, 0),
    ),
    StudyPlanTemplate(
      id: 'verified_sleep_env',
      categoryId: planCategoryVerified,
      label: l10n.planTemplateSleepEnvLabel,
      action: l10n.planTemplateSleepEnvAction,
      description: l10n.planTemplateSleepEnvDescription,
      selectedDayIndexes: const {0, 1, 2, 3, 4, 5, 6},
      notificationTime: NotificationTime.custom(22, 0),
    ),
    StudyPlanTemplate(
      id: 'verified_strength_2x',
      categoryId: planCategoryVerified,
      label: l10n.planTemplateStrength2xLabel,
      action: l10n.planTemplateStrength2xAction,
      description: l10n.planTemplateStrength2xDescription,
      // Twice weekly, spaced for recovery (Tue / Thu).
      selectedDayIndexes: const {1, 4},
      notificationTime: NotificationTime.custom(18, 0),
    ),
  ];
}

List<PlanDayPreset> dayPresetsForCategory(
  AppLocalizations l10n,
  String categoryId,
) {
  switch (categoryId) {
    case planCategoryStudy:
      return [
        PlanDayPreset(
          id: 'study_three_days',
          label: l10n.planDayPresetThreeDaysLabel,
          description: l10n.planDayPresetStudyThreeDaysDesc,
          selectedDayIndexes: const {0, 2, 4},
        ),
        PlanDayPreset(
          id: 'study_weekdays',
          label: l10n.planDayPresetWeekdaysLabel,
          description: l10n.planDayPresetStudyWeekdaysDesc,
          selectedDayIndexes: const {0, 1, 2, 3, 4},
        ),
        PlanDayPreset(
          id: 'study_every_day',
          label: l10n.planDayPresetEveryDayLabel,
          description: l10n.planDayPresetStudyEveryDayDesc,
          selectedDayIndexes: const {0, 1, 2, 3, 4, 5, 6},
        ),
      ];
    case planCategoryExercise:
      return [
        PlanDayPreset(
          id: 'exercise_three_days',
          label: l10n.planDayPresetThreeDaysLabel,
          description: l10n.planDayPresetExerciseThreeDaysDesc,
          selectedDayIndexes: const {0, 2, 4},
        ),
        PlanDayPreset(
          id: 'exercise_weekend',
          label: l10n.planDayPresetWeekendLabel,
          description: l10n.planDayPresetExerciseWeekendDesc,
          selectedDayIndexes: const {5, 6},
        ),
        PlanDayPreset(
          id: 'exercise_every_day',
          label: l10n.planDayPresetEveryDayLabel,
          description: l10n.planDayPresetExerciseEveryDayDesc,
          selectedDayIndexes: const {0, 1, 2, 3, 4, 5, 6},
        ),
      ];
    default:
      return [
        PlanDayPreset(
          id: 'custom_three_days',
          label: l10n.planDayPresetThreeDaysLabel,
          description: l10n.planDayPresetCustomThreeDaysDesc,
          selectedDayIndexes: const {0, 2, 4},
        ),
        PlanDayPreset(
          id: 'custom_weekdays',
          label: l10n.planDayPresetWeekdaysLabel,
          description: l10n.planDayPresetCustomWeekdaysDesc,
          selectedDayIndexes: const {0, 1, 2, 3, 4},
        ),
        PlanDayPreset(
          id: 'custom_every_day',
          label: l10n.planDayPresetEveryDayLabel,
          description: l10n.planDayPresetCustomEveryDayDesc,
          selectedDayIndexes: const {0, 1, 2, 3, 4, 5, 6},
        ),
      ];
  }
}
