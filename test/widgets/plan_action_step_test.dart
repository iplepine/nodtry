import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/study_plan_template.dart';
import 'package:nod_try/features/plan/presentation/widgets/plan_action_step.dart';
import 'package:nod_try/features/plan/presentation/widgets/plan_day_selection_step.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';

void main() {
  testWidgets('shows a clear button when action text exists', (tester) async {
    final controller = TextEditingController(text: '30분 걷기');
    final focusNode = FocusNode();
    var didClear = false;

    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlanActionStep(
            controller: controller,
            focusNode: focusNode,
            categories: planCategories,
            selectedCategoryId: planCategoryExercise,
            onCategorySelected: (_) {},
            templates: studyPlanTemplates,
            selectedTemplateId: 'walking',
            onTemplateSelected: (_) {},
            onActionCleared: () {
              didClear = true;
            },
          ),
        ),
      ),
    );

    expect(find.byTooltip('비우기'), findsOneWidget);

    await tester.tap(find.byTooltip('비우기'));

    expect(didClear, isTrue);
  });

  testWidgets('hides recommendations for direct input', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlanActionStep(
            controller: controller,
            focusNode: focusNode,
            categories: planCategories,
            selectedCategoryId: planCategoryCustom,
            onCategorySelected: (_) {},
            templates: studyPlanTemplates,
            selectedTemplateId: null,
            onTemplateSelected: (_) {},
            onActionCleared: () {},
          ),
        ),
      ),
    );

    expect(find.text('추천 약속'), findsNothing);
    expect(find.text('내 약속'), findsOneWidget);
  });

  testWidgets('shows partner preview and category day presets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlanDaySelectionStep(
              selectedDays: const {0, 2, 4},
              onDayToggle: (_) {},
              onDayPresetSelected: (_) {},
              notificationTime: NotificationTime.custom(21, 0),
              onTimeChanged: (_) {},
              selectedCategoryId: planCategoryStudy,
              action: '영어 문장 10개 소리내어 읽기',
              partnerName: '지민',
              hasPartner: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('추천 빈도'), findsOneWidget);
    expect(find.text('주 3일'), findsOneWidget);
    expect(find.text('평일'), findsOneWidget);
    expect(find.text('매일'), findsOneWidget);
    expect(find.text('파트너에게 이렇게 보여요'), findsOneWidget);
    expect(find.textContaining('지민님에게 "영어 문장 10개 소리내어 읽기"'), findsOneWidget);
    expect(find.textContaining('오후 9시'), findsOneWidget);
  });
}
