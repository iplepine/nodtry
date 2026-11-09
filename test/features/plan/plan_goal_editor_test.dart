import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/plan/presentation/widgets/plan_goal_editor.dart';
import 'package:nod_try/l10n/app_localizations.dart';

class _Host extends StatefulWidget {
  final DateTime? initialDate;
  const _Host({this.initialDate});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String title = '';
  DateTime? date;

  @override
  void initState() {
    super.initState();
    date = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return PlanGoalEditor(
      title: title,
      date: date,
      collapsible: false,
      now: DateTime(2026, 11, 9),
      onTitleChanged: (v) => setState(() => title = v),
      onDateChanged: (v) => setState(() => date = v),
      onClear: () => setState(() {
        title = '';
        date = null;
      }),
    );
  }
}

Future<void> _pump(WidgetTester tester, {DateTime? date}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: _Host(initialDate: date)),
    ),
  );
}

EditableText _titleField(WidgetTester tester) => tester.widget<EditableText>(
  find.descendant(
    of: find.byKey(const ValueKey('plan-goal-title-field')),
    matching: find.byType(EditableText),
  ),
);

void main() {
  testWidgets('직접 입력 focuses the title and opens no date picker', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('plan-goal-preset-custom')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
    expect(_titleField(tester).focusNode.hasFocus, isTrue);

    await tester.enterText(
      find.byKey(const ValueKey('plan-goal-title-field')),
      '마라톤',
    );
    await tester.pump();
    expect(find.text('마라톤'), findsOneWidget);
    // Still no date: the hint asks for one.
    expect(find.text('날짜를 고르면 D-day가 보여요'), findsOneWidget);
  });

  testWidgets('a title preset without a date opens the date picker', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('plan-goal-preset-trip')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('a title preset with a date already set opens no picker', (
    tester,
  ) async {
    await _pump(tester, date: DateTime(2026, 12, 24));

    await tester.tap(find.byKey(const ValueKey('plan-goal-preset-wedding')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.text('결혼식'), findsWidgets);
  });
}
