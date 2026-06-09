import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/presentation/widgets/promise_proposal_sheet.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';

Plan _plan({
  required List<int> days,
  DateTime? startDate,
  int durationDays = 28,
  List<DateTime> completedDates = const [],
}) {
  final resolvedStartDate = startDate ?? DateTime(2026, 1, 5);
  return Plan(
    id: 'plan-test',
    userId: 'user-test',
    managerId: 'manager-test',
    startDate: resolvedStartDate,
    endDate: resolvedStartDate.add(Duration(days: durationDays - 1)),
    state: PlanState.active,
    items: [PlanItem(title: '공부하기', days: days, count: 1)],
    createdAt: resolvedStartDate,
    completedDates: completedDates,
  );
}

Future<void> _pumpSheet(
  WidgetTester tester,
  Plan plan, {
  DateTime? asOf,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PromiseProposalSheet(plan: plan, asOf: asOf),
      ),
    ),
  );
}

void main() {
  testWidgets('shows duration and scheduled-day bound', (tester) async {
    await _pumpSheet(
      tester,
      _plan(days: const [DateTime.monday, DateTime.wednesday, DateTime.friday]),
      asOf: DateTime(2026, 1, 5),
    );

    expect(find.text('총 28일짜리 약속 · 실천 예정 12일'), findsOneWidget);
    expect(find.text('현재 성공 0일 · 실패 0일 · 남은 예정 12일'), findsOneWidget);
    expect(find.text('보상은 최대 12일, 벌칙은 최대 12일까지 정할 수 있어요.'), findsOneWidget);
    expect(find.text('9일'), findsOneWidget);
    expect(find.text('최대 12일'), findsOneWidget);
  });

  testWidgets('keeps increment button within scheduled-day limit', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      _plan(days: const [DateTime.monday, DateTime.wednesday, DateTime.friday]),
      asOf: DateTime(2026, 1, 5),
    );

    final addFinder = find.widgetWithIcon(IconButton, Icons.add_circle_outline);
    for (var i = 0; i < 3; i++) {
      await tester.tap(addFinder);
      await tester.pump();
    }

    expect(find.text('12일'), findsOneWidget);
    final addButton = tester.widget<IconButton>(addFinder);
    expect(addButton.onPressed, isNull);
  });

  testWidgets('limits reward target to current successes plus remaining days', (
    tester,
  ) async {
    final startDate = DateTime(2026, 1, 1);
    final completedDates = List.generate(
      5,
      (index) => startDate.add(Duration(days: index)),
    );

    await _pumpSheet(
      tester,
      _plan(
        startDate: startDate,
        durationDays: 30,
        days: const [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
        completedDates: completedDates,
      ),
      asOf: startDate.add(const Duration(days: 20)),
    );

    expect(find.text('총 30일짜리 약속이에요'), findsOneWidget);
    expect(find.text('현재 성공 5일 · 실패 15일 · 남은 예정 10일'), findsOneWidget);
    expect(find.text('보상은 최대 15일, 벌칙은 최대 25일까지 정할 수 있어요.'), findsOneWidget);
    expect(find.text('12일'), findsOneWidget);
    expect(find.text('최대 15일'), findsOneWidget);
  });
}
