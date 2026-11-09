import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/presentation/widgets/plan_progress_card.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';

/// A finished 주 3회 plan (2026-09-28 is a Monday) done Mon–Thu every week:
/// 16 workouts against 12 target days.
Plan _overachievedWeekly() => Plan(
  id: 'w',
  userId: 'me',
  managerId: 'partner',
  startDate: DateTime(2026, 9, 28),
  endDate: DateTime(2026, 10, 25, 23, 59, 59),
  state: PlanState.completed,
  createdAt: DateTime(2026, 9, 28),
  items: [
    PlanItem(title: '러닝', days: const [1, 2, 3, 4, 5, 6, 7], count: 7),
  ],
  completedDates: [
    for (final day in [28, 29, 30]) DateTime(2026, 9, day, 19),
    DateTime(2026, 10, 1, 19),
    for (final monday in [5, 12, 19])
      for (var i = 0; i < 4; i++) DateTime(2026, 10, monday + i, 19),
  ],
  weeklyTarget: 3,
);

Future<void> _pump(WidgetTester tester, Plan plan) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(child: PlanProgressCard(plan: plan)),
      ),
    ),
  );
}

void main() {
  testWidgets('a weekly plan done beyond its targets reads 100%, not 133%', (
    tester,
  ) async {
    final plan = _overachievedWeekly();
    expect(plan.completedDayCount(), 16);
    expect(plan.scheduledDayCount, 12);

    await _pump(tester, plan);

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('133%'), findsNothing);
    expect(find.text('12/12일'), findsOneWidget);
    expect(find.text('16/12일'), findsNothing);
    // The 실천 tile still counts every workout.
    expect(find.text('16일'), findsOneWidget);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator).first,
    );
    expect(bar.value, 1.0);
  });
}
