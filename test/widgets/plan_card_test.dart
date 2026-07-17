import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/theme/app_theme.dart';
import 'package:nod_try/widgets/plan/plan_card.dart';

Plan _plan() => Plan(
  id: 'plan-1',
  userId: 'me',
  startDate: DateTime(2026, 5, 11),
  endDate: DateTime(2026, 6, 8),
  state: PlanState.pendingApproval,
  createdAt: DateTime(2026, 5, 11),
  items: [
    PlanItem(
      title: '아침 러닝',
      days: const [1, 2, 3, 4, 5],
      count: 5,
      notificationTime: NotificationTime.custom(7, 0),
    ),
  ],
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required bool isOwner,
  VoidCallback? onTap,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.smokyPlumTheme,
      home: Scaffold(
        body: PlanCard(
          plan: _plan(),
          isOwner: isOwner,
          onTap: onTap ?? () {},
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    ),
  );
}

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

  group('owner overflow menu', () {
    testWidgets('owner sees the menu, and it lists 수정/삭제', (tester) async {
      await _pumpCard(
        tester,
        isOwner: true,
        onEdit: () {},
        onDelete: () {},
      );

      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('수정'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('non-owner never sees the menu', (tester) async {
      await _pumpCard(
        tester,
        isOwner: false,
        onEdit: () {},
        onDelete: () {},
      );

      expect(find.byIcon(Icons.more_vert), findsNothing);
      // 대신 기존 chevron 유지.
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tapping 삭제 invokes onDelete once', (tester) async {
      var deleteCount = 0;
      await _pumpCard(
        tester,
        isOwner: true,
        onEdit: () {},
        onDelete: () => deleteCount++,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(deleteCount, 1);
    });

    testWidgets('opening the menu does not trigger card onTap', (tester) async {
      var tapCount = 0;
      await _pumpCard(
        tester,
        isOwner: true,
        onTap: () => tapCount++,
        onDelete: () {},
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(tapCount, 0);
    });

    testWidgets('menu button keeps a 48px tap target', (tester) async {
      await _pumpCard(tester, isOwner: true, onDelete: () {});

      final button = find.ancestor(
        of: find.byIcon(Icons.more_vert),
        matching: find.byType(IconButton),
      );
      final size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('non-editable plan shows 삭제 only', (tester) async {
      await _pumpCard(tester, isOwner: true, onDelete: () {});

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('수정'), findsNothing);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('owner with no actions falls back to chevron', (tester) async {
      await _pumpCard(tester, isOwner: true);

      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
}
