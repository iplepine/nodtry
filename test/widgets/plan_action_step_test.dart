import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/domain/study_plan_template.dart';
import 'package:nod_try/features/plan/presentation/widgets/plan_action_step.dart';
import 'package:nod_try/l10n/app_localizations.dart';

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
}
