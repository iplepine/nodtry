import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/theme/app_theme.dart';
import 'package:nod_try/widgets/plan/plan_card.dart';

void main() {
  testWidgets('does not overflow on narrow cards with long plan metadata', (
    tester,
  ) async {
    final plan = Plan(
      id: 'narrow-plan',
      userId: 'me',
      startDate: DateTime(2026, 5, 11),
      endDate: DateTime(2026, 6, 8),
      state: PlanState.pendingApproval,
      createdAt: DateTime(2026, 5, 11),
      items: [
        PlanItem(
          title: '매우 긴 약속 제목이 들어와도 우리 탭 카드 오른쪽으로 넘치지 않게 처리하기',
          days: const [1, 2, 3, 4, 5, 6, 7],
          count: 7,
          notificationTime: NotificationTime.custom(23, 59),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.smokyPlumTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: PlanCard(plan: plan, onTap: () {}),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('수락 대기'), findsOneWidget);
  });
}
