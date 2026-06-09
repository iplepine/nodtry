import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/theme/app_theme.dart';
import 'package:nod_try/widgets/history/history_card.dart';

void main() {
  testWidgets('wraps header metadata instead of overflowing on narrow cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(260, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final item = HistoryItem(
      id: 'history-narrow',
      planId: 'plan-1',
      date: DateTime(2026, 5, 11),
      title: '아주 긴 약속 제목이 들어와도 히스토리 카드가 가로로 깨지지 않게 처리하기',
      status: HistoryStatus.actuallyDone,
      executorId: 'partner',
      partnerName: '파트너',
      note: '실천 메모도 여러 줄로 자연스럽게 내려가야 해요.',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.smokyPlumTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(260, 640),
              textScaler: TextScaler.linear(1.45),
            ),
            child: Scaffold(
              // In production HistoryCard lives in a scrolling list, so it gets
              // unbounded vertical space. Mirror that here; otherwise large
              // text-scale content overflows the fixed viewport height (which
              // never happens in the real, scrollable history tab).
              body: SingleChildScrollView(
                child: HistoryCard(item: item, isMe: false),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('했어'), findsOneWidget);
  });
}
