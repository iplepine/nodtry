import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/core/services/notification_service.dart';
import 'package:nod_try/features/connect/application/invite_services.dart';
import 'package:nod_try/features/connect/application/invite_tracker.dart';
import 'package:nod_try/features/connect/application/kakao_invite_sharer.dart';
import 'package:nod_try/features/connect/presentation/widgets/invite_share_panel.dart';
import 'package:nod_try/features/connect/presentation/widgets/kakao_invite_button.dart';
import 'package:nod_try/features/connect/presentation/widgets/now_invite_card.dart';
import 'package:nod_try/features/onboarding/domain/onboarding_gate.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _myCode = 'MYC2DE34';
const _myLink = 'https://nod-try.web.app/i/$_myCode';

UserModel _me() {
  final now = DateTime(2026, 11, 21);
  return UserModel(
    uid: 'me',
    displayName: '민수',
    inviteCode: _myCode,
    createdAt: now,
    updatedAt: now,
  );
}

/// KakaoTalk as the tests need it: installed or not, taking the card or not.
class _FakeKakao implements KakaoInviteSharer {
  _FakeKakao({
    this.available = true,
    this.accepts = true,
    this.throwsOnShare = false,
    this.throwsOnAvailable = false,
  });

  final bool available;
  final bool accepts;
  final bool throwsOnShare;
  final bool throwsOnAvailable;

  final List<KakaoInviteCard> cards = [];

  /// When set, [backInApp] waits for it — the user is still in KakaoTalk.
  Completer<void>? away;

  @override
  Future<bool> isAvailable() async {
    if (throwsOnAvailable) throw StateError('no KakaoTalk plugin');
    return available;
  }

  @override
  Future<bool> share(KakaoInviteCard card) async {
    cards.add(card);
    if (throwsOnShare) throw StateError('KOE009');
    return accepts;
  }

  @override
  Future<void> backInApp() => away?.future ?? Future.value();
}

class _FakeSheet implements InviteSharer {
  _FakeSheet([
    this.result = const InviteShareResult(shared: true, channel: 'other'),
  ]);

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

class _FakeRecords extends Fake implements RecordRepository {
  _FakeRecords({this.activePromise = false});

  final bool activePromise;

  @override
  Stream<List<Plan>> getPlansByUserIdStream(String userId) => Stream.value([
    if (activePromise)
      Plan(
        id: 'plan-1',
        userId: userId,
        startDate: DateTime(2026, 11, 16),
        endDate: DateTime(2026, 12, 13),
        state: PlanState.active,
        createdAt: DateTime(2026, 11, 16),
        items: [
          PlanItem(title: '헬스', days: const [5], count: 1),
        ],
      ),
  ]);
}

class _FakeUsers extends Fake implements UserRepository {
  int termsAccepted = 0;

  @override
  Future<void> markTermsAccepted() async => termsAccepted++;
}

class _FakeNotifications extends Fake implements NotificationService {
  int requests = 0;

  @override
  Future<void> requestPermissionAndRegister() async => requests++;
}

class _CountingTracker implements InviteTracker {
  final List<String> codes = [];

  @override
  Future<void> recordShare({required String uid, required String code}) async {
    codes.add(code);
  }
}

class _Harness {
  _Harness({
    required this.kakao,
    required this.sheet,
    required this.users,
    required this.notifications,
    required this.tracker,
    required this.container,
    required this.prefs,
  });

  final _FakeKakao kakao;
  final _FakeSheet sheet;
  final _FakeUsers users;
  final _FakeNotifications notifications;
  final _CountingTracker tracker;
  final ProviderContainer container;
  final SharedPreferences prefs;
}

/// Pumps [child] with every invite seam faked. [kakao] null leaves the real
/// sharer in place — with no `.env` key, exactly what ships today.
Future<_Harness> _pump(
  WidgetTester tester, {
  required Widget child,
  _FakeKakao? kakao,
  _FakeSheet? sheet,
  bool activePromise = false,
  Map<String, Object> prefValues = const {},
  Locale locale = const Locale('ko'),
}) async {
  SharedPreferences.setMockInitialValues(prefValues);
  final prefs = await SharedPreferences.getInstance();
  final fakeSheet = sheet ?? _FakeSheet();
  final users = _FakeUsers();
  final notifications = _FakeNotifications();
  final tracker = _CountingTracker();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      myProfileProvider.overrideWithValue(AsyncData(_me())),
      connectedProfilesProvider.overrideWith(
        (ref) async => const <ConnectedUser>[],
      ),
      recordRepositoryProvider.overrideWithValue(
        _FakeRecords(activePromise: activePromise),
      ),
      userRepositoryProvider.overrideWithValue(users),
      notificationServiceProvider.overrideWithValue(notifications),
      inviteSharerProvider.overrideWithValue(fakeSheet),
      inviteTrackerProvider.overrideWithValue(tracker),
      if (kakao != null) kakaoInviteSharerProvider.overrideWithValue(kakao),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(
    kakao: kakao ?? _FakeKakao(available: false),
    sheet: fakeSheet,
    users: users,
    notifications: notifications,
    tracker: tracker,
    container: container,
    prefs: prefs,
  );
}

/// Analytics is `AnalyticsService.log`, which in debug prints
/// `[Analytics] name {params}`: collect those lines while [body] runs.
Future<List<String>> _analyticsDuring(Future<void> Function() body) async {
  final lines = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && message.startsWith('[Analytics]')) {
      lines.add(message);
    }
  };
  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return lines;
}

void main() {
  late AppLocalizations ko;
  late AppLocalizations en;

  setUpAll(() async {
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('the card', () {
    test('[ko] couple tone, grouped code, one button to the invite link', () {
      final card = kakaoInviteCard(ko, code: _myCode, hasPromise: true);

      expect(card.title, '나 운동 약속 걸었어 🤙 진짜 하는지 봐줘!');
      expect(card.description, '둘운완 깔고 코드 MYC2 DE34 넣으면 바로 연결돼');
      expect(card.buttonTitle, '초대 확인하기');
      expect(card.imageUrl, 'https://nod-try.web.app/og.png');
      expect(card.link, _myLink);
    });

    test('[ko] the title changes when there is no promise yet', () {
      final running = kakaoInviteCard(ko, code: _myCode, hasPromise: true);
      final notYet = kakaoInviteCard(ko, code: _myCode, hasPromise: false);

      expect(notYet.title, '나 운동 약속 걸 거야 🤙 진짜 하는지 봐줘!');
      expect(notYet.title, isNot(running.title));
      // Everything else is the same card.
      expect(notYet.description, running.description);
      expect(notYet.buttonTitle, running.buttonTitle);
      expect(notYet.link, running.link);
    });

    test('[en] has the grouped code and both titles', () {
      final running = kakaoInviteCard(en, code: _myCode, hasPromise: true);
      final notYet = kakaoInviteCard(en, code: _myCode, hasPromise: false);

      expect(running.title, 'I made a workout promise 🤙 Back me up!');
      expect(notYet.title, "I'm making a workout promise 🤙 Back me up!");
      expect(
        running.description,
        'Get DuoDone and enter code MYC2 DE34 to connect',
      );
      expect(running.buttonTitle, 'Open invite');
    });

    test('never names the sender or calls the partner 님/애인', () {
      for (final l10n in [ko, en]) {
        for (final hasPromise in [true, false]) {
          final card = kakaoInviteCard(
            l10n,
            code: _myCode,
            hasPromise: hasPromise,
          );
          final text = '${card.title} ${card.description} ${card.buttonTitle}';
          expect(text, isNot(contains('님')));
          expect(text, isNot(contains('애인')));
          expect(text, isNot(contains('민수')));
        }
      }
    });

    test('an old code that is not 8 long is left ungrouped', () {
      final card = kakaoInviteCard(ko, code: 'ABC234', hasPromise: false);
      expect(card.description, contains('코드 ABC234 넣으면'));
    });

    test('the feed template: og image, one button, plain web links only', () {
      final card = kakaoInviteCard(ko, code: _myCode, hasPromise: true);
      final json = kakaoInviteFeedTemplate(card).toJson();

      expect(json['object_type'], 'feed');
      final content = json['content'] as Map<String, dynamic>;
      expect(content['title'], card.title);
      expect(content['description'], card.description);
      expect(content['image_url'], 'https://nod-try.web.app/og.png');
      expect(content['image_width'], 1200);
      expect(content['image_height'], 630);
      expect(content['link'], {'web_url': _myLink, 'mobile_web_url': _myLink});

      final buttons = json['buttons'] as List;
      expect(buttons, hasLength(1));
      expect(buttons.single, {
        'title': '초대 확인하기',
        'link': {'web_url': _myLink, 'mobile_web_url': _myLink},
      });

      // No app-execution params and no kakao{KEY}:// scheme: the https
      // invite link is the only way in.
      final wire = jsonEncode(json);
      expect(wire, isNot(contains('execution_params')));
      expect(wire, isNot(contains('kakaolink')));
    });
  });

  group('without a Kakao native app key', () {
    test('the SDK is never started and the card is unavailable', () async {
      const sharer = KakaoSdkInviteSharer();

      expect(kakaoNativeAppKey(), isNull);
      expect(await ensureKakaoShareSdk(), isFalse);
      expect(await sharer.isAvailable(), isFalse);
      expect(
        await sharer.share(
          kakaoInviteCard(ko, code: _myCode, hasPromise: true),
        ),
        isFalse,
      );
    });

    testWidgets('the panel is today\'s: one coral share button', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        child: const InviteSharePanel(surface: 'connect'),
      );

      expect(find.byKey(const ValueKey('invite-kakao-button')), findsNothing);
      expect(find.text(ko.inviteShareOtherApps), findsNothing);
      final share = find.byKey(const ValueKey('invite-share-button'));
      expect(tester.widget(share), isA<FilledButton>());
      expect(
        find.descendant(of: share, matching: find.text(ko.connectShareInvite)),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('invite-copy-button')), findsOneWidget);

      await tester.tap(share);
      await tester.pumpAndSettle();
      expect(h.sheet.texts, hasLength(1));
      expect(find.text(ko.connectInviteSent), findsOneWidget);
    });

    testWidgets('the Now card is today\'s: one coral share button', (
      tester,
    ) async {
      await _pump(tester, child: const NowInviteCard());

      expect(find.byKey(const ValueKey('now-invite-kakao')), findsNothing);
      expect(find.text(ko.inviteShareOtherApps), findsNothing);
      final share = find.byKey(const ValueKey('now-invite-share'));
      expect(tester.widget(share), isA<FilledButton>());
      expect(
        find.descendant(of: share, matching: find.text(ko.connectShareInvite)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('now-invite-enter-code')),
        findsOneWidget,
      );
    });
  });

  group('backInApp', () {
    const sharer = KakaoSdkInviteSharer();

    testWidgets('completes when the app is resumed after KakaoTalk took over', (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      var back = false;
      unawaited(sharer.backInApp().then((_) => back = true));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      // Away for longer than the "did KakaoTalk open at all" wait.
      await tester.pump(const Duration(minutes: 2));
      expect(back, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(back, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(back, isTrue);
    });

    testWidgets('gives up waiting when KakaoTalk never comes to the front', (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var back = false;
      unawaited(sharer.backInApp().then((_) => back = true));

      await tester.pump(const Duration(seconds: 2));
      expect(back, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(back, isTrue);
    });
  });

  group('InviteSharePanel with KakaoTalk', () {
    testWidgets('shows the yellow KakaoTalk button above "다른 앱으로 보내기"', (
      tester,
    ) async {
      await _pump(
        tester,
        kakao: _FakeKakao(),
        child: const InviteSharePanel(surface: 'connect'),
      );

      final kakaoButton = find.byKey(const ValueKey('invite-kakao-button'));
      expect(
        find.descendant(of: kakaoButton, matching: find.text('카카오톡으로 초대 보내기')),
        findsOneWidget,
      );
      final filled = tester.widget<FilledButton>(
        find.descendant(of: kakaoButton, matching: find.byType(FilledButton)),
      );
      expect(filled.style?.backgroundColor?.resolve({}), kKakaoYellow);
      expect(kKakaoYellow, const Color(0xFFFEE500));
      expect(filled.style?.foregroundColor?.resolve({}), kKakaoLabel);

      // The share sheet is still there, one step down, under its old key.
      final other = find.byKey(const ValueKey('invite-share-button'));
      expect(tester.widget(other), isA<OutlinedButton>());
      expect(
        find.descendant(of: other, matching: find.text('다른 앱으로 보내기')),
        findsOneWidget,
      );
      expect(find.text(ko.connectShareInvite), findsNothing);
      expect(
        tester.getTopLeft(kakaoButton).dy,
        lessThan(tester.getTopLeft(other).dy),
      );
      expect(
        tester.getSize(other).height,
        lessThan(tester.getSize(kakaoButton).height),
      );
      expect(find.byKey(const ValueKey('invite-copy-button')), findsOneWidget);
      expect(find.text(ko.termsNoticeInvite), findsOneWidget);
    });

    testWidgets('a failing availability check leaves today\'s button', (
      tester,
    ) async {
      await _pump(
        tester,
        kakao: _FakeKakao(throwsOnAvailable: true),
        child: const InviteSharePanel(surface: 'connect'),
      );

      expect(find.byKey(const ValueKey('invite-kakao-button')), findsNothing);
      expect(
        tester.widget(find.byKey(const ValueKey('invite-share-button'))),
        isA<FilledButton>(),
      );
    });

    testWidgets('sends the card and does the same bookkeeping as a share', (
      tester,
    ) async {
      var shared = 0;
      final h = await _pump(
        tester,
        kakao: _FakeKakao(),
        child: InviteSharePanel(surface: 'connect', onShared: () => shared++),
      );

      final events = await _analyticsDuring(() async {
        await tester.tap(find.byKey(const ValueKey('invite-kakao-button')));
        await tester.pumpAndSettle();
      });

      expect(h.kakao.cards, [
        kakaoInviteCard(ko, code: _myCode, hasPromise: false),
      ]);
      expect(h.sheet.texts, isEmpty);

      expect(h.container.read(inviteSharedAtProvider), isNotNull);
      expect(OnboardingStore(h.prefs).inviteLastSharedAt, isNotNull);
      expect(h.tracker.codes, [_myCode]);
      expect(events, [
        '[Analytics] invite_shared '
            '{channel: kakao_card, surface: connect, has_promise: false}',
        '[Analytics] invite_code_shared {method: kakao_card}',
      ]);

      // The steps after any sent invite.
      expect(find.text(ko.connectInviteSent), findsOneWidget);
      expect(h.users.termsAccepted, 1);
      expect(h.notifications.requests, 1);
      expect(shared, 1);
    });

    testWidgets('a running promise changes the card title', (tester) async {
      final h = await _pump(
        tester,
        kakao: _FakeKakao(),
        activePromise: true,
        child: const InviteSharePanel(surface: 'onboarding'),
      );

      final events = await _analyticsDuring(() async {
        await tester.tap(find.byKey(const ValueKey('invite-kakao-button')));
        await tester.pumpAndSettle();
      });

      expect(h.kakao.cards.single.title, ko.inviteKakaoCardTitle);
      expect(
        events.first,
        '[Analytics] invite_shared '
        '{channel: kakao_card, surface: onboarding, has_promise: true}',
      );
    });

    testWidgets(
      'the snackbar and the permission prompt wait until the user is back',
      (tester) async {
        final kakao = _FakeKakao()..away = Completer<void>();
        var shared = 0;
        final h = await _pump(
          tester,
          kakao: kakao,
          child: InviteSharePanel(surface: 'connect', onShared: () => shared++),
        );

        await tester.tap(find.byKey(const ValueKey('invite-kakao-button')));
        await tester.pump();
        await tester.pump();

        // KakaoTalk is in front: the invite is already on record...
        expect(kakao.cards, hasLength(1));
        expect(h.container.read(inviteSharedAtProvider), isNotNull);
        expect(h.users.termsAccepted, 1);
        // ...but nothing that needs the screen has happened yet.
        expect(find.text(ko.connectInviteSent), findsNothing);
        expect(h.notifications.requests, 0);
        expect(shared, 0);
        // Both buttons stay off while the send is in flight.
        expect(
          tester
              .widget<OutlinedButton>(
                find.byKey(const ValueKey('invite-share-button')),
              )
              .onPressed,
          isNull,
        );

        kakao.away!.complete();
        await tester.pumpAndSettle();

        expect(find.text(ko.connectInviteSent), findsOneWidget);
        expect(h.notifications.requests, 1);
        expect(shared, 1);
      },
    );

    testWidgets('falls back to the share sheet when KakaoTalk says no', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        kakao: _FakeKakao(accepts: false),
        sheet: _FakeSheet(
          const InviteShareResult(shared: true, channel: 'kakao'),
        ),
        child: const InviteSharePanel(surface: 'connect'),
      );

      final events = await _analyticsDuring(() async {
        await tester.tap(find.byKey(const ValueKey('invite-kakao-button')));
        await tester.pumpAndSettle();
      });

      expect(h.kakao.cards, hasLength(1));
      // The plain message went out instead, with the code and the link.
      expect(h.sheet.texts.single, contains(_myCode));
      expect(h.sheet.texts.single, contains(_myLink));
      // Counted as what it was: a share-sheet send, not a card.
      expect(events, [
        '[Analytics] invite_shared '
            '{channel: kakao, surface: connect, has_promise: false}',
        '[Analytics] invite_code_shared {method: share}',
      ]);
      expect(h.tracker.codes, [_myCode]);
      expect(find.text(ko.connectInviteSent), findsOneWidget);
      expect(h.users.termsAccepted, 1);
      expect(h.notifications.requests, 1);
    });

    testWidgets('falls back to the share sheet when the Kakao SDK throws', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        kakao: _FakeKakao(throwsOnShare: true),
        child: const InviteSharePanel(surface: 'connect'),
      );

      final events = await _analyticsDuring(() async {
        await tester.tap(find.byKey(const ValueKey('invite-kakao-button')));
        await tester.pumpAndSettle();
      });

      expect(h.sheet.texts, hasLength(1));
      expect(events.last, '[Analytics] invite_code_shared {method: share}');
      expect(events.join(), isNot(contains('kakao_card')));
      expect(find.text(ko.connectInviteSent), findsOneWidget);
      expect(h.container.read(inviteSharedAtProvider), isNotNull);
    });

    testWidgets('a fallback sheet the user closes sends nothing', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        kakao: _FakeKakao(accepts: false),
        sheet: _FakeSheet(
          const InviteShareResult(shared: false, channel: 'dismissed'),
        ),
        child: const InviteSharePanel(surface: 'connect'),
      );

      final events = await _analyticsDuring(() async {
        await tester.tap(find.byKey(const ValueKey('invite-kakao-button')));
        await tester.pumpAndSettle();
      });

      expect(h.sheet.texts, hasLength(1));
      expect(events, isEmpty);
      expect(h.tracker.codes, isEmpty);
      expect(h.container.read(inviteSharedAtProvider), isNull);
      expect(find.text(ko.connectInviteSent), findsNothing);
      expect(h.users.termsAccepted, 0);
      expect(h.notifications.requests, 0);
    });

    testWidgets('"다른 앱으로 보내기" opens the share sheet, not KakaoTalk', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        kakao: _FakeKakao(),
        child: const InviteSharePanel(surface: 'connect'),
      );

      final events = await _analyticsDuring(() async {
        await tester.tap(find.byKey(const ValueKey('invite-share-button')));
        await tester.pumpAndSettle();
      });

      expect(h.kakao.cards, isEmpty);
      expect(h.sheet.texts, hasLength(1));
      expect(events, [
        '[Analytics] invite_shared '
            '{channel: other, surface: connect, has_promise: false}',
        '[Analytics] invite_code_shared {method: share}',
      ]);
      expect(find.text(ko.connectInviteSent), findsOneWidget);
    });

    testWidgets('[en] labels', (tester) async {
      await _pump(
        tester,
        kakao: _FakeKakao(),
        locale: const Locale('en'),
        child: const InviteSharePanel(surface: 'connect'),
      );

      expect(find.text('Send invite on KakaoTalk'), findsOneWidget);
      expect(find.text('Send with another app'), findsOneWidget);
    });
  });

  group('NowInviteCard with KakaoTalk', () {
    testWidgets('the main button sends the card; the sheet is a text link', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        kakao: _FakeKakao(),
        child: const NowInviteCard(),
      );

      final kakaoButton = find.byKey(const ValueKey('now-invite-kakao'));
      expect(
        find.descendant(of: kakaoButton, matching: find.text('카카오톡으로 초대 보내기')),
        findsOneWidget,
      );
      final other = find.byKey(const ValueKey('now-invite-share'));
      expect(tester.widget(other), isA<TextButton>());
      expect(
        find.descendant(of: other, matching: find.text('다른 앱으로 보내기')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('now-invite-enter-code')),
        findsOneWidget,
      );
      expect(find.text(ko.connectShareInvite), findsNothing);

      final events = await _analyticsDuring(() async {
        await tester.tap(kakaoButton);
        await tester.pumpAndSettle();
      });

      expect(h.kakao.cards.single.link, _myLink);
      expect(h.sheet.texts, isEmpty);
      expect(
        events.first,
        '[Analytics] invite_shared '
        '{channel: kakao_card, surface: now_card, has_promise: false}',
      );
      // Sent: the card now waits for the partner and offers a resend.
      expect(find.text(ko.nowInviteCardWaitingTitle), findsOneWidget);
      expect(
        find.descendant(of: kakaoButton, matching: find.text('카카오톡으로 다시 보내기')),
        findsOneWidget,
      );
    });

    testWidgets('after an invite went out the button offers a resend', (
      tester,
    ) async {
      await _pump(
        tester,
        kakao: _FakeKakao(),
        prefValues: {
          OnboardingPrefKeys.inviteLastSharedAt: DateTime(
            2026,
            11,
            20,
          ).millisecondsSinceEpoch,
        },
        child: const NowInviteCard(),
      );

      expect(find.text(ko.nowInviteCardWaitingTitle), findsOneWidget);
      expect(find.text(ko.inviteKakaoResend), findsOneWidget);
      expect(find.text(ko.nowInviteCardResend), findsNothing);
    });

    testWidgets('"다른 앱으로 보내기" opens the share sheet', (tester) async {
      final h = await _pump(
        tester,
        kakao: _FakeKakao(),
        child: const NowInviteCard(),
      );

      await tester.tap(find.byKey(const ValueKey('now-invite-share')));
      await tester.pumpAndSettle();

      expect(h.kakao.cards, isEmpty);
      expect(h.sheet.texts, hasLength(1));
    });

    testWidgets('a card KakaoTalk refuses still goes out by share sheet', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        kakao: _FakeKakao(throwsOnShare: true),
        child: const NowInviteCard(),
      );

      await tester.tap(find.byKey(const ValueKey('now-invite-kakao')));
      await tester.pumpAndSettle();

      expect(h.sheet.texts, hasLength(1));
      expect(find.text(ko.nowInviteCardWaitingTitle), findsOneWidget);
    });
  });
}
