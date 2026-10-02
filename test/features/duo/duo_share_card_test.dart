import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nod_try/features/connect/application/partner_label_provider.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/features/duo/presentation/duo_share_card.dart';
import 'package:nod_try/features/proof/data/proof_photo_cache.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';

final Uint8List _jpeg = img.encodeJpg(img.Image(width: 8, height: 8));

DuoShareCardData _data({Uint8List? photo, int streak = 5}) => DuoShareCardData(
  streak: streak,
  date: DateTime(2026, 10, 2),
  meLabel: '나',
  partnerLabel: '자기',
  me: const DuoPersonDay(
    status: DuoDayStatus.done,
    doneWorkoutTypes: ['running'],
  ),
  partner: const DuoPersonDay(status: DuoDayStatus.off),
  photo: photo,
);

/// The card is laid out unconstrained, the way the sheet's FittedBox does.
Widget _fitted(Widget card) => Center(child: FittedBox(child: card));

Widget _app(Widget child, {List overrides = const []}) => ProviderScope(
  overrides: [...overrides],
  child: MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

class _Sharer implements ShareCardSharer {
  final shared = <({Uint8List png, String text})>[];

  @override
  Future<ShareCardResult> sharePng(
    Uint8List png, {
    required String text,
    Rect? origin,
  }) async {
    shared.add((png: png, text: text));
    return const ShareCardResult(shared: true, target: 'instagram');
  }
}

Plan _myPlan(String id, {String? photo, DateTime? at}) => Plan(
  id: id,
  userId: 'me',
  managerId: 'partner-uid',
  startDate: DateTime(2026, 9, 28),
  endDate: DateTime(2026, 10, 25),
  state: PlanState.active,
  items: [
    PlanItem(title: '러닝', days: const [1, 3, 5], count: 3),
  ],
  createdAt: DateTime(2026, 9, 28),
  lastProofPhotoPath: photo,
  lastProofAt: at,
);

DuoStats _stats() {
  final day = DuoDay(
    date: DateTime(2026, 10, 2),
    me: const DuoPersonDay(
      status: DuoDayStatus.done,
      doneWorkoutTypes: ['gym'],
    ),
    partner: const DuoPersonDay(
      status: DuoDayStatus.done,
      doneWorkoutTypes: ['yoga'],
    ),
    isToday: true,
  );
  return DuoStats(
    streak: 7,
    streakStart: DateTime(2026, 9, 26),
    today: day,
    week: [
      for (var i = 0; i < 7; i++)
        i == 4
            ? day
            : DuoDay(
                date: DateTime(2026, 9, 28 + i),
                me: DuoPersonDay.off,
                partner: DuoPersonDay.off,
                isToday: false,
              ),
    ],
    hasPartner: true,
  );
}

void main() {
  group('the card', () {
    testWidgets('shows the streak, both workouts, the date and the stores', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_fitted(DuoShareCard(data: _data()))));
      expect(find.text('#둘운완 연속 5일'), findsOneWidget);
      expect(find.text('나 ✓ 🏃 러닝'), findsOneWidget);
      expect(find.text('자기 · 쉬는 날'), findsOneWidget);
      expect(find.text('2026.10.02 (금)'), findsOneWidget);
      expect(find.text("스토어에서 '둘운완' 검색"), findsOneWidget);
      expect(find.textContaining('Google Play'), findsNothing);
      expect(tester.getSize(find.byType(DuoShareCard)), const Size(360, 640));
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('puts my photo behind the text when there is one', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_fitted(DuoShareCard(data: _data(photo: _jpeg)))),
      );
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('without a streak it is just #둘운완', (tester) async {
      await tester.pumpWidget(
        _app(_fitted(DuoShareCard(data: _data(streak: 0)))),
      );
      expect(find.text('#둘운완'), findsOneWidget);
    });

    testWidgets('renders to a 1080×1920 PNG', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          _fitted(
            RepaintBoundary(
              key: key,
              child: DuoShareCard(data: _data()),
            ),
          ),
        ),
      );
      final png = await tester.runAsync(() => captureShareCardPng(key));
      final decoded = img.decodePng(png!)!;
      expect(decoded.width, 1080);
      expect(decoded.height, 1920);
    });
  });

  group('helpers', () {
    testWidgets('person lines', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(
        shareCardPersonLine(
          l10n,
          '나',
          const DuoPersonDay(
            status: DuoDayStatus.done,
            doneWorkoutTypes: ['running', null, 'running'],
          ),
        ),
        '나 ✓ 🏃 러닝 · 약속',
      );
      expect(
        shareCardPersonLine(
          l10n,
          '짝꿍',
          const DuoPersonDay(status: DuoDayStatus.rested),
        ),
        '짝꿍 · 휴식권',
      );
      expect(
        shareCardPersonLine(
          l10n,
          '짝꿍',
          const DuoPersonDay(status: DuoDayStatus.pending),
        ),
        '짝꿍 · 아직',
      );
    });

    test('shareCardProofPhotoPathOf picks my newest photo of that day', () {
      final day = DateTime(2026, 10, 2);
      expect(shareCardProofPhotoPathOf(const [], day: day), isNull);
      expect(
        shareCardProofPhotoPathOf([
          _myPlan(
            'a',
            photo: 'proofs/me/a/1.jpg',
            at: DateTime(2026, 10, 2, 8),
          ),
          _myPlan(
            'b',
            photo: 'proofs/me/b/2.jpg',
            at: DateTime(2026, 10, 2, 19),
          ),
          _myPlan('c'),
        ], day: day),
        'proofs/me/b/2.jpg',
      );
    });

    test('an earlier day\'s photo never goes on the card', () {
      // Recorded today without a photo, or only the partner worked out:
      // the last photo is from days ago.
      expect(
        shareCardProofPhotoPathOf([
          _myPlan('a', photo: 'proofs/me/a/1.jpg', at: DateTime(2026, 9, 20)),
        ], day: DateTime(2026, 10, 2)),
        isNull,
      );
    });

    test('a photo of an older record of the plan is skipped', () {
      // lastProofPhotoPath still points at the photo while today's record
      // (lastActionId) has none.
      final plan = _myPlan(
        'a',
        photo: 'proofs/me/a/morning.jpg',
        at: DateTime(2026, 10, 2, 7),
      ).copyWith(lastActionId: 'evening');
      expect(
        shareCardProofPhotoPathOf([plan], day: DateTime(2026, 10, 2)),
        isNull,
      );
    });

    test('share targets', () {
      expect(shareCardTargetFromRaw('com.kakao.talk'), 'kakao');
      expect(
        shareCardTargetFromRaw('com.burbn.instagram.shareextension'),
        'instagram',
      );
      expect(
        shareCardTargetFromRaw('com.apple.UIKit.activity.SaveToCameraRoll'),
        'save',
      );
      expect(
        shareCardTargetFromRaw('com.apple.UIKit.activity.CopyToPasteboard'),
        'copy',
      );
      expect(shareCardTargetFromRaw(''), 'unknown');
      expect(shareCardTargetFromRaw('com.whatsapp'), 'other');
    });
  });

  group('the sheet', () {
    testWidgets('shares the card with my photo and the nickname only', (
      tester,
    ) async {
      final sharer = _Sharer();
      final fetched = <String>[];
      final captured = Uint8List.fromList([1, 2, 3]);
      var result = false;

      await tester.pumpWidget(
        _app(
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async {
                result = await showDuoShareCardSheet(
                  context,
                  ref,
                  trigger: DuoShareTrigger.milestone,
                );
              },
              child: const Text('open'),
            ),
          ),
          overrides: [
            duoStatsProvider.overrideWith((ref) => _stats()),
            myDuoPlansProvider.overrideWith(
              (ref) => [
                _myPlan(
                  'mine',
                  photo: 'proofs/me/mine/a.jpg',
                  at: DateTime(2026, 10, 2),
                ),
              ],
            ),
            partnerLabelProvider.overrideWithValue(
              const PartnerLabel(
                partnerUid: 'partner-uid',
                nickname: '자기',
                displayName: '김진짜',
              ),
            ),
            proofPhotoCacheProvider.overrideWithValue(
              ProofPhotoCache(
                fetch: (path) async {
                  fetched.add(path);
                  return _jpeg;
                },
                directory: () async => null,
              ),
            ),
            shareCardCaptureProvider.overrideWithValue((_) async => captured),
            shareCardSharerProvider.overrideWithValue(sharer),
          ],
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('둘이 함께 7일째! 🎉 자랑해 볼까요?'), findsOneWidget);
      expect(find.text('#둘운완 연속 7일'), findsOneWidget);
      expect(find.text('나 ✓ 🏋️ 헬스'), findsOneWidget);
      expect(find.text('자기 ✓ 🧘 요가'), findsOneWidget);
      expect(find.textContaining('김진짜'), findsNothing);
      expect(find.text('카드에는 내 인증샷만 들어가요.'), findsOneWidget);
      // Only my own photo is ever fetched.
      expect(fetched, ['proofs/me/mine/a.jpg']);

      await tester.tap(find.text('공유하기'));
      await tester.pumpAndSettle();

      expect(sharer.shared, hasLength(1));
      expect(sharer.shared.single.png, captured);
      expect(sharer.shared.single.text, contains('#둘운완'));
      expect(result, isTrue);
      expect(find.byType(DuoShareSheet), findsNothing);
    });

    testWidgets('다음에 closes without sharing', (tester) async {
      final sharer = _Sharer();
      await tester.pumpWidget(
        _app(
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showDuoShareCardSheet(
                context,
                ref,
                trigger: DuoShareTrigger.today,
              ),
              child: const Text('open'),
            ),
          ),
          overrides: [
            duoStatsProvider.overrideWith((ref) => _stats()),
            myDuoPlansProvider.overrideWith((ref) => const <Plan>[]),
            partnerLabelProvider.overrideWithValue(
              const PartnerLabel(partnerUid: 'p', displayName: '김진짜'),
            ),
            shareCardSharerProvider.overrideWithValue(sharer),
          ],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('오늘 둘운완이에요 🎉 자랑해 볼까요?'), findsOneWidget);
      // No nickname: the generic 짝꿍, never the real name.
      expect(find.text('짝꿍 ✓ 🧘 요가'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('share-sheet-later')));
      await tester.pumpAndSettle();
      expect(sharer.shared, isEmpty);
      expect(find.byType(DuoShareSheet), findsNothing);
    });

    testWidgets('no partner: no sheet', (tester) async {
      await tester.pumpWidget(
        _app(
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showDuoShareCardSheet(
                context,
                ref,
                trigger: DuoShareTrigger.manual,
              ),
              child: const Text('open'),
            ),
          ),
          overrides: [duoStatsProvider.overrideWith((ref) => null)],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(DuoShareSheet), findsNothing);
    });
  });
}
