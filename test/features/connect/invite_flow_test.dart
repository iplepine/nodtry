import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nod_try/features/connect/application/invite_services.dart';
import 'package:nod_try/features/connect/application/partner_link_binder.dart';
import 'package:nod_try/features/connect/domain/invite_code.dart';
import 'package:nod_try/features/connect/presentation/screens/connect_screen.dart';
import 'package:nod_try/features/connect/presentation/widgets/invite_share_panel.dart';
import 'package:nod_try/features/connect/presentation/widgets/now_invite_card.dart';
import 'package:nod_try/features/onboarding/domain/onboarding_gate.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/connect_repository.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ownerCode = 'K7MP2QXR';
const _myCode = 'MYC2DE34';

UserModel _user(String uid, {String? name, String? code, String? nickname}) {
  final now = DateTime(2026, 10, 3);
  return UserModel(
    uid: uid,
    displayName: name,
    inviteCode: code,
    partnerNickname: nickname,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeClipboard implements InviteClipboard {
  _FakeClipboard([this.text]);

  String? text;
  int reads = 0;
  String? written;

  @override
  Future<bool> hasStrings() async => text != null && text!.isNotEmpty;

  @override
  Future<String?> readText() async {
    reads++;
    return text;
  }

  @override
  Future<void> writeText(String value) async => written = value;
}

class _FakeSharer implements InviteSharer {
  _FakeSharer(this.result);

  final InviteShareResult result;
  final List<String> texts = [];

  @override
  Future<InviteShareResult> share({
    required String text,
    String? subject,
    Rect? origin,
  }) async {
    texts.add(text);
    return result;
  }
}

class _FakeUsers extends Fake implements UserRepository {
  final Map<String, UserModel> byCode = {};
  final List<String?> nicknames = [];

  @override
  Future<UserModel?> getUserByInviteCode(String code) async => byCode[code];

  @override
  Future<void> updatePartnerNickname(String? nickname) async {
    nicknames.add(nickname);
  }
}

/// Connecting flips the shared "partners" list and the link stream, the way
/// the real relation snapshot does.
class _FakeConnect extends Fake implements ConnectRepository {
  _FakeConnect(this.world);

  final _World world;
  final List<String> codes = [];

  @override
  Future<String> connectWithCode(String code) async {
    codes.add(code);
    world.partners = [
      ConnectedUser(user: world.owner, isSupported: true, isCheering: true),
    ];
    world.status.add(ConnectionStatus.active);
    return world.owner.uid;
  }
}

class _FakeRecords extends Fake implements RecordRepository {
  final List<String> managers = [];

  @override
  Future<void> assignManagerToActivePlans(String managerId) async {
    managers.add(managerId);
  }

  @override
  Stream<List<Plan>> getPlansByUserIdStream(String userId) =>
      Stream.value(const []);
}

class _World {
  final owner = _user('owner', name: '지민', code: _ownerCode);
  final me = _user('me', name: '민수', code: _myCode);
  List<ConnectedUser> partners = [];
  final status = StreamController<ConnectionStatus>.broadcast();
}

Future<_World> _pumpConnect(
  WidgetTester tester, {
  _FakeClipboard? clipboard,
  _FakeUsers? users,
  _FakeConnect Function(_World)? connect,
  _FakeRecords? records,
  bool entryMode = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final world = _World();
  addTearDown(world.status.close);
  final fakeUsers = users ?? (_FakeUsers()..byCode[_ownerCode] = world.owner);

  final router = GoRouter(
    initialLocation: '/connect',
    routes: [
      GoRoute(
        path: '/connect',
        builder: (context, state) => ConnectScreen(entryMode: entryMode),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        myProfileProvider.overrideWithValue(AsyncData(world.me)),
        connectedProfilesProvider.overrideWith((ref) async => world.partners),
        connectionStatusStreamProvider.overrideWith((ref) async* {
          yield ConnectionStatus.none;
          yield* world.status.stream;
        }),
        userRepositoryProvider.overrideWithValue(fakeUsers),
        connectRepositoryProvider.overrideWithValue(
          (connect ?? _FakeConnect.new)(world),
        ),
        recordRepositoryProvider.overrideWithValue(records ?? _FakeRecords()),
        inviteClipboardProvider.overrideWithValue(
          clipboard ?? _FakeClipboard(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return world;
}

void main() {
  late AppLocalizations ko;

  setUpAll(() async {
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  group('unit', () {
    test('share-sheet targets map to invite channels', () {
      expect(inviteChannelFromShareRaw('com.kakao.talk'), 'kakao');
      expect(inviteChannelFromShareRaw('com.iwilab.KakaoTalk.Share'), 'kakao');
      expect(
        inviteChannelFromShareRaw('com.apple.UIKit.activity.CopyToPasteboard'),
        'copy',
      );
      expect(
        inviteChannelFromShareRaw('com.apple.UIKit.activity.Message'),
        'other',
      );
      expect(inviteChannelFromShareRaw(''), 'unknown');
      expect(
        inviteChannelFromShareRaw(
          'dev.fluttercommunity.plus/share/unavailable',
        ),
        'unknown',
      );
    });

    test('the Korean invite has the couple tone, the code and the link', () {
      final withPromise = inviteShareMessage(
        ko,
        code: _ownerCode,
        hasPromise: true,
      );
      // From me, in my voice — never my own name in the third person.
      expect(withPromise, startsWith('나 운동 약속 걸었어 🤙 진짜 하는지 봐줘!'));
      expect(withPromise, contains('코드 $_ownerCode 넣으면 바로 연결돼'));
      expect(withPromise, endsWith('https://nod-try.web.app/i/$_ownerCode'));
      // Whatever app the message lands in, the code can be found again.
      expect(findInviteCodeInText(withPromise), _ownerCode);

      final noPromise = inviteShareMessage(
        ko,
        code: _ownerCode,
        hasPromise: false,
      );
      expect(noPromise, startsWith('나 운동 약속 걸 거야 🤙'));
      expect(findInviteCodeInText(noPromise), _ownerCode);
    });

    test('link events: only changes between known statuses count', () {
      expect(partnerLinkEventFor(null, ConnectionStatus.active), isNull);
      expect(
        partnerLinkEventFor(ConnectionStatus.active, ConnectionStatus.active),
        isNull,
      );
      expect(
        partnerLinkEventFor(ConnectionStatus.none, ConnectionStatus.active),
        PartnerLinkEvent.linked,
      );
      expect(
        partnerLinkEventFor(ConnectionStatus.active, ConnectionStatus.none),
        PartnerLinkEvent.unlinked,
      );
      expect(
        partnerLinkEventFor(ConnectionStatus.none, ConnectionStatus.pending),
        isNull,
      );
    });

    group('InviteCodeDetector', () {
      Future<UserModel?> lookup(String code) async =>
          code == _ownerCode ? _user('owner', name: '지민') : null;

      test('never reads the clipboard when it holds no text', () async {
        final clipboard = _FakeClipboard();
        final detector = InviteCodeDetector(
          clipboard: clipboard,
          lookup: lookup,
        );
        expect(await detector.fromClipboard(myCode: _myCode), isNull);
        expect(clipboard.reads, 0);
      });

      test(
        'finds the code in a pasted message and resolves the owner',
        () async {
          final detector = InviteCodeDetector(
            clipboard: _FakeClipboard('둘운완 깔고 코드 $_ownerCode 넣으면 연결돼'),
            lookup: lookup,
          );
          final found = await detector.fromClipboard(
            myCode: _myCode,
            myUid: 'me',
          );
          expect(found?.code, _ownerCode);
          expect(found?.owner.displayName, '지민');
          expect(found?.source, InviteCodeSource.clipboard);
        },
      );

      test('ignores my own code and codes nobody holds', () async {
        var lookups = 0;
        Future<UserModel?> counting(String code) async {
          lookups++;
          return null;
        }

        final mine = InviteCodeDetector(
          clipboard: _FakeClipboard('코드 $_myCode'),
          lookup: counting,
        );
        expect(await mine.fromClipboard(myCode: _myCode), isNull);
        expect(lookups, 0);

        final unknown = InviteCodeDetector(
          clipboard: _FakeClipboard('ZZZZ2345'),
          lookup: counting,
        );
        expect(await unknown.fromClipboard(myCode: _myCode), isNull);
        expect(lookups, 1);
      });

      test('a code that resolves to me is ignored', () async {
        final detector = InviteCodeDetector(
          clipboard: _FakeClipboard(_ownerCode),
          lookup: (_) async => _user('me', name: '민수'),
        );
        expect(
          await detector.fromClipboard(myCode: 'OTHER234', myUid: 'me'),
          isNull,
        );
      });
    });
  });

  group('ConnectScreen', () {
    testWidgets('shows my code big with share and copy', (tester) async {
      await _pumpConnect(tester);

      expect(find.text(ko.connectHeadline), findsOneWidget);
      expect(find.text(groupedInviteCode(_myCode)), findsOneWidget);
      expect(find.text(ko.connectShareInvite), findsOneWidget);
      expect(find.text(ko.connectCopyCode), findsOneWidget);
      expect(find.text(ko.connectHaveCodeTitle), findsOneWidget);
    });

    testWidgets(
      'a typed code is confirmed with the owner, then connects and offers a nickname',
      (tester) async {
        final records = _FakeRecords();
        late _FakeConnect connect;
        final world = await _pumpConnect(
          tester,
          records: records,
          connect: (w) => connect = _FakeConnect(w),
        );

        await tester.enterText(
          find.byKey(const ValueKey('connect-code-field')),
          'k7mp-2qxr',
        );
        await tester.pumpAndSettle();

        // "{이름}의 운동 약속을 봐줄래요?" before anything is written.
        expect(find.text(ko.connectConfirmTitle('지민')), findsOneWidget);
        expect(connect.codes, isEmpty);

        await tester.tap(find.byKey(const ValueKey('invite-confirm-accept')));
        await tester.pumpAndSettle();

        expect(connect.codes, [_ownerCode]);
        expect(records.managers, [world.owner.uid]);

        // Success, then the nickname sheet.
        expect(find.text(ko.connectSuccessTitle('지민')), findsOneWidget);
        expect(find.text(ko.nicknameSheetTitle), findsOneWidget);

        // Pick 자기 and save.
        await tester.tap(find.byKey(const ValueKey('nickname-chip-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nickname-save')));
        await tester.pumpAndSettle();

        final users =
            ProviderScope.containerOf(
                  tester.element(find.byType(ConnectScreen)),
                ).read(userRepositoryProvider)
                as _FakeUsers;
        expect(users.nicknames, ['자기']);

        // They skipped the tutorial, so the loop is explained here.
        expect(find.text(ko.connectHowTitle), findsOneWidget);
        expect(find.text(ko.connectHowAck), findsOneWidget);

        // The person who entered the code is asked to make their own promise.
        expect(find.text(ko.connectSuccessAskTitle), findsOneWidget);
        expect(find.text(ko.connectSuccessMakePromise), findsOneWidget);
      },
    );

    testWidgets('cancelling the confirm sheet connects nothing', (
      tester,
    ) async {
      late _FakeConnect connect;
      await _pumpConnect(tester, connect: (w) => connect = _FakeConnect(w));

      await tester.enterText(
        find.byKey(const ValueKey('connect-code-field')),
        _ownerCode,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('invite-confirm-cancel')));
      await tester.pumpAndSettle();

      expect(connect.codes, isEmpty);
      expect(find.text(ko.connectSuccessTitle('지민')), findsNothing);
    });

    testWidgets('an unknown code says so and asks nothing', (tester) async {
      await _pumpConnect(tester);

      await tester.enterText(
        find.byKey(const ValueKey('connect-code-field')),
        'ZZZZ2345',
      );
      await tester.pumpAndSettle();

      expect(find.text(ko.connectErrorCodeNotFound), findsOneWidget);
      expect(find.byKey(const ValueKey('invite-confirm-title')), findsNothing);
    });

    testWidgets('my own code is refused', (tester) async {
      await _pumpConnect(tester);

      await tester.enterText(
        find.byKey(const ValueKey('connect-code-field')),
        _myCode,
      );
      await tester.pumpAndSettle();

      expect(find.text(ko.connectErrorSelfCode), findsOneWidget);
    });

    testWidgets('a copied invite message is found on open and confirmed', (
      tester,
    ) async {
      final clipboard = _FakeClipboard(
        '나 운동 약속 걸었어 🤙 지민 운동하는지 봐줘! 둘운완 깔고 코드 $_ownerCode 넣으면 '
        '연결돼 → https://nod-try.web.app/i/$_ownerCode',
      );
      await _pumpConnect(tester, clipboard: clipboard, entryMode: true);

      expect(clipboard.reads, 1);
      expect(find.text(ko.connectInviteCodeDetectedTitle), findsOneWidget);
      expect(find.text(ko.connectConfirmTitle('지민')), findsOneWidget);
    });

    testWidgets('an empty clipboard is never read', (tester) async {
      final clipboard = _FakeClipboard();
      await _pumpConnect(tester, clipboard: clipboard);

      expect(clipboard.reads, 0);
      expect(find.byKey(const ValueKey('invite-confirm-title')), findsNothing);
    });

    testWidgets('the share button sends the message and remembers it', (
      tester,
    ) async {
      final sharer = _FakeSharer(
        const InviteShareResult(shared: true, channel: 'kakao'),
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final me = _user('me', name: '민수', code: _myCode);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          myProfileProvider.overrideWithValue(AsyncData(me)),
          recordRepositoryProvider.overrideWithValue(_FakeRecords()),
          inviteSharerProvider.overrideWithValue(sharer),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: InviteSharePanel(surface: 'connect'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('invite-share-button')));
      await tester.pumpAndSettle();

      expect(sharer.texts, hasLength(1));
      expect(sharer.texts.single, contains(_myCode));
      expect(
        sharer.texts.single,
        contains('https://nod-try.web.app/i/$_myCode'),
      );
      expect(find.text(ko.connectInviteSent), findsOneWidget);
      expect(container.read(inviteSharedAtProvider), isNotNull);
      expect(OnboardingStore(prefs).inviteLastSharedAt, isNotNull);
    });
  });

  group('NowInviteCard', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required List<ConnectedUser> partners,
      Map<String, Object> prefs = const {},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      final shared = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(shared),
            myProfileProvider.overrideWithValue(
              AsyncData(_user('me', name: '민수', code: _myCode)),
            ),
            connectedProfilesProvider.overrideWith((ref) async => partners),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: NowInviteCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('asks to invite while there is no partner', (tester) async {
      await pumpCard(tester, partners: const []);
      expect(find.text(ko.nowInviteCardTitle), findsOneWidget);
      expect(find.text(ko.connectShareInvite), findsOneWidget);
      expect(find.text(ko.enterInviteCode), findsOneWidget);
    });

    testWidgets('offers to resend after an invite went out', (tester) async {
      await pumpCard(
        tester,
        partners: const [],
        prefs: {
          OnboardingPrefKeys.inviteLastSharedAt: DateTime(
            2026,
            10,
            3,
          ).millisecondsSinceEpoch,
        },
      );
      expect(find.text(ko.nowInviteCardWaitingTitle), findsOneWidget);
      expect(find.text(ko.nowInviteCardResend), findsOneWidget);
    });

    testWidgets('is hidden once a partner is connected', (tester) async {
      await pumpCard(
        tester,
        partners: [
          ConnectedUser(
            user: _user('p', name: '지민'),
            isSupported: true,
            isCheering: true,
          ),
        ],
      );
      expect(find.byKey(const ValueKey('now-invite-card')), findsNothing);
    });
  });
}
