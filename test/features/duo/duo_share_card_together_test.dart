import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:image/image.dart' as img;
import 'package:nod_try/features/connect/application/partner_label_provider.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/features/duo/presentation/duo_share_card.dart';
import 'package:nod_try/features/proof/data/proof_photo_cache.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';

final Uint8List _jpeg = img.encodeJpg(img.Image(width: 8, height: 8));

final DateTime _day = DateTime(2026, 10, 2);

Plan _plan(
  String id, {
  required String owner,
  String? manager,
  String? photo,
  DateTime? at,
  String? lastActionId,
}) => Plan(
  id: id,
  userId: owner,
  managerId: manager,
  startDate: DateTime(2026, 9, 1),
  endDate: DateTime(2026, 10, 25),
  state: PlanState.active,
  items: [
    PlanItem(title: '러닝', days: const [1, 3, 5], count: 3),
  ],
  createdAt: DateTime(2026, 9, 1),
  lastProofPhotoPath: photo,
  lastProofAt: at,
  lastActionId: lastActionId,
);

DuoShareCardData _data({Uint8List? photo, Uint8List? partnerPhoto}) =>
    DuoShareCardData(
      streak: 3,
      date: _day,
      meLabel: '나',
      partnerLabel: '자기',
      me: const DuoPersonDay(
        status: DuoDayStatus.done,
        doneWorkoutTypes: ['running'],
      ),
      partner: const DuoPersonDay(
        status: DuoDayStatus.done,
        doneWorkoutTypes: ['yoga'],
      ),
      photo: photo,
      partnerPhoto: partnerPhoto,
    );

DuoStats _stats() {
  final today = DuoDay(
    date: _day,
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
    streak: 4,
    streakStart: DateTime(2026, 9, 29),
    today: today,
    week: [
      for (var i = 0; i < 7; i++)
        i == 4
            ? today
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

class _Sharer implements ShareCardSharer {
  int count = 0;

  @override
  Future<ShareCardResult> sharePng(
    Uint8List png, {
    required String text,
    Rect? origin,
  }) async {
    count++;
    return const ShareCardResult(shared: true, target: 'kakao');
  }
}

Widget _app(Widget child, {List overrides = const []}) => ProviderScope(
  overrides: [...overrides],
  child: MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

const _myPhoto = 'proofs/me/mine/a1.jpg';
const _partnerPhoto = 'proofs/partner/theirs/b1.jpg';

void main() {
  group('layout decision', () {
    final myPlans = [
      _plan('mine', owner: 'me', photo: _myPhoto, at: DateTime(2026, 10, 2, 8)),
    ];
    final partnerPlans = [
      _plan(
        'theirs',
        owner: 'partner',
        manager: 'me',
        photo: _partnerPhoto,
        at: DateTime(2026, 10, 2, 9),
      ),
    ];

    ({String mine, String partner})? decide({
      bool allowed = true,
      String? myUid = 'me',
      String? partnerUid = 'partner',
      List<Plan>? mine,
      List<Plan>? theirs,
    }) => shareCardTogetherPhotoPathsOf(
      partnerAllowed: allowed,
      myUid: myUid,
      partnerUid: partnerUid,
      myPlans: mine ?? myPlans,
      partnerPlans: theirs ?? partnerPlans,
      day: _day,
    );

    test('both photos, partner allowed: together', () {
      expect(decide(), (mine: _myPhoto, partner: _partnerPhoto));
    });

    test('partner has not allowed it (missing = false): never', () {
      expect(decide(allowed: false), isNull);
    });

    test('without either uid: never', () {
      expect(decide(myUid: null), isNull);
      expect(decide(partnerUid: null), isNull);
      expect(decide(partnerUid: 'me'), isNull);
    });

    test('either of us without a photo: never', () {
      expect(decide(mine: [_plan('mine', owner: 'me')]), isNull);
      expect(
        decide(
          theirs: [_plan('theirs', owner: 'partner', manager: 'me')],
        ),
        isNull,
      );
    });

    test('only partner plans I manage count (Storage lets me read those)', () {
      expect(
        decide(
          theirs: [
            _plan(
              'theirs',
              owner: 'partner',
              manager: 'someone-else',
              photo: _partnerPhoto,
              at: DateTime(2026, 10, 2, 9),
            ),
          ],
        ),
        isNull,
      );
    });

    test('same day preferred, else the latest of each', () {
      final older = _plan(
        'old',
        owner: 'partner',
        manager: 'me',
        photo: 'proofs/partner/old/x.jpg',
        at: DateTime(2026, 9, 20),
      );
      final newer = _plan(
        'new',
        owner: 'partner',
        manager: 'me',
        photo: 'proofs/partner/new/y.jpg',
        at: DateTime(2026, 9, 30),
      );
      expect(
        decide(theirs: [older, newer])?.partner,
        'proofs/partner/new/y.jpg',
      );
      expect(
        decide(theirs: [older, newer, ...partnerPlans])?.partner,
        _partnerPhoto,
      );
    });

    test('a path that is not the plan owner\'s is skipped', () {
      expect(
        shareCardLatestProofPhotoPathOf([
          _plan(
            'x',
            owner: 'partner',
            photo: 'proofs/someone/x/1.jpg',
            at: DateTime(2026, 9, 1),
          ),
        ], day: _day),
        isNull,
      );
    });

    test('offered layouts need consent and both loaded photos', () {
      expect(
        shareCardLayoutsOf(
          partnerAllowed: true,
          hasMyPhoto: true,
          hasPartnerPhoto: true,
        ),
        [ShareCardLayout.single, ShareCardLayout.together],
      );
      for (final (allowed, mine, theirs) in [
        (false, true, true),
        (true, false, true),
        (true, true, false),
      ]) {
        expect(
          shareCardLayoutsOf(
            partnerAllowed: allowed,
            hasMyPhoto: mine,
            hasPartnerPhoto: theirs,
          ),
          [ShareCardLayout.single],
        );
      }
    });
  });

  group('the card', () {
    testWidgets('together: both photos split, labelled by nickname', (
      tester,
    ) async {
      final data = _data(photo: _jpeg, partnerPhoto: _jpeg);
      expect(data.layout, ShareCardLayout.together);
      await tester.pumpWidget(
        _app(
          Center(
            child: FittedBox(child: DuoShareCard(data: data)),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('share-card-together')), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
      expect(find.byKey(const ValueKey('share-card-partner')), findsOneWidget);
      expect(find.text("스토어에서 '둘운완' 검색"), findsOneWidget);
      expect(tester.getSize(find.byType(DuoShareCard)), const Size(360, 640));
    });

    testWidgets('a partner photo alone is never shown', (tester) async {
      final data = _data(partnerPhoto: _jpeg);
      expect(data.layout, ShareCardLayout.single);
      await tester.pumpWidget(
        _app(
          Center(
            child: FittedBox(child: DuoShareCard(data: data)),
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.byKey(const ValueKey('share-card-together')), findsNothing);
    });
  });

  group('the sheet', () {
    final logs = <String>[];

    /// Captures debugPrint (where analytics events show in debug) and puts
    /// it back before the test ends, as the binding requires.
    void testWidgets(String name, WidgetTesterCallback body) {
      flutter_test.testWidgets(name, (tester) async {
        logs.clear();
        final original = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logs.add(message);
        };
        try {
          await body(tester);
        } finally {
          debugPrint = original;
        }
      });
    }

    Future<_Sharer> open(
      WidgetTester tester, {
      required bool allowed,
      Set<String> failing = const {},
      List<String>? fetched,
    }) async {
      final sharer = _Sharer();
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
          overrides: [
            duoStatsProvider.overrideWith((ref) => _stats()),
            myProfileProvider.overrideWithValue(
              AsyncData(
                UserModel(
                  uid: 'me',
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ),
            ),
            myDuoPlansProvider.overrideWith(
              (ref) => [
                _plan(
                  'mine',
                  owner: 'me',
                  manager: 'partner',
                  photo: _myPhoto,
                  at: DateTime(2026, 10, 2, 8),
                ),
              ],
            ),
            partnerDuoPlansProvider.overrideWith(
              (ref) => [
                _plan(
                  'theirs',
                  owner: 'partner',
                  manager: 'me',
                  photo: _partnerPhoto,
                  at: DateTime(2026, 10, 2, 9),
                ),
              ],
            ),
            partnerLabelProvider.overrideWithValue(
              const PartnerLabel(
                partnerUid: 'partner',
                nickname: '자기',
                displayName: '김진짜',
              ),
            ),
            shareCardPartnerConsentProvider.overrideWithValue(
              (uid) async => uid == 'partner' && allowed,
            ),
            proofPhotoCacheProvider.overrideWithValue(
              ProofPhotoCache(
                fetch: (path) async {
                  fetched?.add(path);
                  if (failing.contains(path)) {
                    throw Exception('storage/unauthorized');
                  }
                  return _jpeg;
                },
                directory: () async => null,
              ),
            ),
            shareCardCaptureProvider.overrideWithValue(
              (_) async => Uint8List.fromList([1]),
            ),
            shareCardSharerProvider.overrideWithValue(sharer),
          ],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return sharer;
    }

    testWidgets('partner allowed: toggle to together and share it', (
      tester,
    ) async {
      final fetched = <String>[];
      final sharer = await open(tester, allowed: true, fetched: fetched);

      expect(fetched.toSet(), {_myPhoto, _partnerPhoto});
      expect(find.byKey(const ValueKey('share-layout-single')), findsOneWidget);
      expect(find.text('카드에는 내 인증샷만 들어가요.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('share-sheet-consent-hint')),
        findsNothing,
      );
      // Single is the default.
      expect(find.byKey(const ValueKey('share-card-together')), findsNothing);

      await tester.tap(find.text('둘 사진 같이'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('share-card-together')), findsOneWidget);
      expect(find.text('짝꿍이 허용한 인증샷이 같이 들어가요.'), findsOneWidget);
      expect(find.textContaining('김진짜'), findsNothing);

      await tester.tap(find.text('공유하기'));
      await tester.pumpAndSettle();
      expect(sharer.count, 1);
      expect(
        logs.where((l) => l.contains('share_card_shared')).single,
        contains('layout: together'),
      );
    });

    testWidgets('single share logs layout single', (tester) async {
      await open(tester, allowed: true);
      await tester.tap(find.text('공유하기'));
      await tester.pumpAndSettle();
      expect(
        logs.where((l) => l.contains('share_card_shared')).single,
        contains('layout: single'),
      );
    });

    testWidgets('partner has not allowed it: hint, no toggle, no fetch', (
      tester,
    ) async {
      final fetched = <String>[];
      await open(tester, allowed: false, fetched: fetched);

      expect(fetched, [_myPhoto]);
      expect(find.byKey(const ValueKey('share-layout-together')), findsNothing);
      expect(find.text('짝꿍이 허용하면 둘 사진을 같이 넣을 수 있어요'), findsOneWidget);
    });

    testWidgets('partner photo unreadable: falls back to single', (
      tester,
    ) async {
      await open(tester, allowed: true, failing: {_partnerPhoto});

      expect(find.byKey(const ValueKey('share-layout-together')), findsNothing);
      expect(find.byKey(const ValueKey('share-card-together')), findsNothing);
      expect(find.text('카드에는 내 인증샷만 들어가요.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('share-sheet-consent-hint')),
        findsNothing,
      );
    });
  });
}
