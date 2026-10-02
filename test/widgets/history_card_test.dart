import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nod_try/features/proof/data/proof_photo_cache.dart';
import 'package:nod_try/features/proof/presentation/proof_photo_view.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/theme/app_theme.dart';
import 'package:nod_try/widgets/history/history_card.dart';
import 'package:nod_try/widgets/reaction_icon.dart';

Widget _wrap(Widget child, {List<String>? fetched}) {
  return ProviderScope(
    overrides: [
      proofPhotoCacheProvider.overrideWith(
        (ref) => ProofPhotoCache(
          fetch: (path) async {
            fetched?.add(path);
            return img.encodeJpg(img.Image(width: 4, height: 4));
          },
          directory: () async => null,
        ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.smokyPlumTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

HistoryItem _item({
  String executorId = 'partner',
  bool isVerifiedByMe = false,
  bool isVerifiedByPartner = false,
  String? reaction,
  String? proofPhotoPath,
  String? proofSource,
  DateTime? proofTakenAt,
}) {
  return HistoryItem(
    id: 'a1',
    planId: 'plan-1',
    date: DateTime(2026, 10, 2, 19),
    title: '헬스장 가기',
    status: HistoryStatus.done,
    executorId: executorId,
    isVerifiedByMe: isVerifiedByMe,
    isVerifiedByPartner: isVerifiedByPartner,
    reaction: reaction,
    proofPhotoPath: proofPhotoPath,
    proofSource: proofSource,
    proofTakenAt: proofTakenAt,
  );
}

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

  testWidgets("a partner's record is given 인정 with one tap", (tester) async {
    final reacted = <String>[];
    await tester.pumpWidget(
      _wrap(HistoryCard(item: _item(), isMe: false, onReact: reacted.add)),
    );
    await tester.pumpAndSettle();

    // The old keyboard-first "인정!" button is gone.
    expect(find.text('인정!'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('react-💪')));
    await tester.pump();

    expect(reacted, ['💪']);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('no 인정 row on a record of a plan I don\'t manage', (
    tester,
  ) async {
    // e.g. the partner's plan that ended before we linked: the rules deny
    // the 인정, so it isn't offered.
    await tester.pumpWidget(
      _wrap(
        HistoryCard(
          item: _item().copyWith(canVerify: false),
          isMe: false,
          onReact: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('react-💪')), findsNothing);
  });

  testWidgets('한마디 is offered next to the reactions', (tester) async {
    var notes = 0;
    await tester.pumpWidget(
      _wrap(
        HistoryCard(
          item: _item(),
          isMe: false,
          onReact: (_) {},
          onAddNote: () => notes++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('react-add-note')));
    expect(notes, 1);
  });

  testWidgets('the reaction I gave shows on the record', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HistoryCard(
          item: _item(isVerifiedByMe: true, reaction: '🔥'),
          isMe: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('내가 인정했어요'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is ReactionIcon && w.reaction == '🔥'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('react-🔥')), findsNothing);
  });

  testWidgets("my partner's reaction shows on my record", (tester) async {
    await tester.pumpWidget(
      _wrap(
        HistoryCard(
          item: _item(
            executorId: 'me',
            isVerifiedByPartner: true,
            reaction: '❤️',
          ),
          isMe: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('짝꿍이 인정했어요'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is ReactionIcon && w.reaction == '❤️'),
      findsOneWidget,
    );
  });

  testWidgets('a record with a proof photo shows it with its badge', (
    tester,
  ) async {
    final fetched = <String>[];
    const path = 'proofs/partner/plan-1/a1.jpg';
    await tester.pumpWidget(
      _wrap(
        HistoryCard(
          item: _item(
            proofPhotoPath: path,
            proofSource: 'gallery',
            proofTakenAt: DateTime(2026, 9, 28, 7),
          ),
          isMe: false,
          onReact: (_) {},
        ),
        fetched: fetched,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProofPhoto), findsOneWidget);
    expect(fetched, [path]);
    expect(find.text('🖼️ 앨범 · 9/28 촬영'), findsOneWidget);
  });
}
