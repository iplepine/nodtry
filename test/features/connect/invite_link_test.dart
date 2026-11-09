import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nod_try/features/connect/application/invite_link_binder.dart';
import 'package:nod_try/features/connect/domain/invite_code.dart';
import 'package:nod_try/features/connect/domain/invite_link.dart';
import 'package:nod_try/features/onboarding/domain/onboarding_gate.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLinkSource implements IncomingLinkSource {
  _FakeLinkSource({this.initial, this.initialDelay = Duration.zero});

  final Uri? initial;
  final Duration initialDelay;
  final StreamController<Uri> controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => controller.stream;

  @override
  Future<Uri?> initialLink() => Future.delayed(initialDelay, () => initial);
}

class _ThrowingLinkSource implements IncomingLinkSource {
  @override
  Stream<Uri> get links => Stream.error(StateError('no plugin'));

  @override
  Future<Uri?> initialLink() => Future.error(StateError('no plugin'));
}

Future<OnboardingStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return OnboardingStore(await SharedPreferences.getInstance());
}

void main() {
  group('inviteCodeFromPath', () {
    String? code(String url) => inviteCodeFromPath(Uri.parse(url));

    test('reads /i/{CODE}', () {
      expect(code('https://nod-try.web.app/i/K7MP2QXR'), 'K7MP2QXR');
      expect(code('/i/K7MP2QXR'), 'K7MP2QXR');
    });

    test('tolerates a trailing slash, a query and a fragment', () {
      expect(code('https://nod-try.web.app/i/K7MP2QXR/'), 'K7MP2QXR');
      expect(code('https://nod-try.web.app/i/K7MP2QXR?utm=kakao'), 'K7MP2QXR');
      expect(code('https://nod-try.web.app/i/K7MP2QXR/?a=1#x'), 'K7MP2QXR');
    });

    test('upper-cases like typed codes (chat apps lower-case URLs)', () {
      expect(code('https://nod-try.web.app/i/k7mp2qxr'), 'K7MP2QXR');
      expect(code('https://nod-try.web.app/i/K7mp-2QXR'), 'K7MP2QXR');
    });

    test('keeps old codes with 0/O/1/I/L as they are', () {
      expect(code('https://nod-try.web.app/i/AB01OIL9'), 'AB01OIL9');
    });

    test('accepts /i/?code= like the landing page', () {
      expect(code('https://nod-try.web.app/i/?code=k7mp2qxr'), 'K7MP2QXR');
      expect(code('https://nod-try.web.app/i?code=K7MP2QXR'), 'K7MP2QXR');
    });

    test('rejects other paths and malformed codes', () {
      expect(code('https://nod-try.web.app/'), isNull);
      expect(code('https://nod-try.web.app/i/'), isNull);
      expect(code('https://nod-try.web.app/i/SHORT'), isNull);
      expect(code('https://nod-try.web.app/i/K7MP2QXRX'), isNull);
      expect(code('https://nod-try.web.app/i/K7MP2QX!'), isNull);
      expect(code('https://nod-try.web.app/i/K7MP2QXR/extra'), isNull);
      expect(code('https://nod-try.web.app/x/K7MP2QXR'), isNull);
      expect(code('https://nod-try.web.app/privacy'), isNull);
    });
  });

  group('classifyIncomingLink', () {
    IncomingLink classify(String url) => classifyIncomingLink(Uri.parse(url));

    test('invite links on both Hosting domains', () {
      expect(
        classify('https://nod-try.web.app/i/K7MP2QXR'),
        const InviteIncomingLink('K7MP2QXR'),
      );
      expect(
        classify('https://nod-try.firebaseapp.com/i/k7mp2qxr/'),
        const InviteIncomingLink('K7MP2QXR'),
      );
      expect(
        classify('https://NOD-TRY.WEB.APP/i/K7MP2QXR'),
        const InviteIncomingLink('K7MP2QXR'),
      );
    });

    test('the custom scheme from the landing page is an invite too', () {
      expect(
        classify('onmybehalf://app/i/K7MP2QXR'),
        const InviteIncomingLink('K7MP2QXR'),
      );
    });

    test('other custom-scheme paths keep routing like before', () {
      expect(
        classify('onmybehalf://app/home'),
        const RouteIncomingLink('/home'),
      );
      expect(
        classify('onmybehalf://app/connect?mode=enter'),
        const RouteIncomingLink('/connect?mode=enter'),
      );
      expect(classify('onmybehalf://app'), const RouteIncomingLink('/'));
    });

    test('foreign links are ignored', () {
      expect(
        classify('https://example.com/i/K7MP2QXR'),
        isA<IgnoredIncomingLink>(),
      );
      expect(
        classify('https://nod-try.web.app/privacy'),
        isA<IgnoredIncomingLink>(),
      );
      expect(
        classify('com.googleusercontent.apps.123:/oauth2redirect?code=abc'),
        isA<IgnoredIncomingLink>(),
      );
    });

    test('inviteLinkLocation is the router path the redirect knows', () {
      final location = inviteLinkLocation('K7MP2QXR');
      expect(location, '/i/K7MP2QXR');
      expect(inviteCodeFromLocation(Uri.parse(location)), 'K7MP2QXR');
    });
  });

  group('stash', () {
    test('an invite link is kept for after sign-in, source link', () async {
      final store = await _freshStore();
      final code = await stashInviteLink(
        store,
        Uri.parse('https://nod-try.web.app/i/k7mp2qxr'),
      );
      expect(code, 'K7MP2QXR');
      expect(store.pendingCodeEntry, isTrue);
      expect(store.pendingInviteCode, 'K7MP2QXR');
      expect(store.pendingInviteSource, InviteCodeSource.link.id);
    });

    test('after sign-in the kept code opens code entry with it', () async {
      final store = await _freshStore();
      await stashInviteLink(
        store,
        Uri.parse('https://nod-try.web.app/i/K7MP2QXR'),
      );

      // A brand-new user would otherwise see the invite step.
      expect(
        postLoginRoute(
          legacyUser: false,
          inviteStepDone: false,
          pendingCodeEntry: store.pendingCodeEntry,
          hasPartner: false,
        ),
        PostLoginRoute.codeEntry,
      );
      final entry = Uri.parse(
        AppRoutes.connectEntry(
          code: store.pendingInviteCode,
          source: InviteCodeSource.fromId(store.pendingInviteSource),
        ),
      );
      expect(entry.queryParameters, {
        'mode': 'enter',
        'code': 'K7MP2QXR',
        'source': 'link',
      });
    });

    test('a link that is not an invite keeps nothing', () async {
      final store = await _freshStore();
      expect(
        await stashInviteLink(store, Uri.parse('onmybehalf://app/home')),
        isNull,
      );
      expect(store.pendingCodeEntry, isFalse);
      expect(store.pendingInviteCode, isNull);
    });

    test('the launch link is kept before the first frame', () async {
      final store = await _freshStore();
      final code = await stashLaunchInviteLink(
        store,
        _FakeLinkSource(
          initial: Uri.parse('https://nod-try.web.app/i/K7MP2QXR'),
        ),
      );
      expect(code, 'K7MP2QXR');
      expect(store.pendingInviteCode, 'K7MP2QXR');
    });

    test(
      'no launch link, a slow one or a broken plugin never block start',
      () async {
        final store = await _freshStore();
        expect(await stashLaunchInviteLink(store, _FakeLinkSource()), isNull);
        expect(
          await stashLaunchInviteLink(
            store,
            _FakeLinkSource(
              initial: Uri.parse('https://nod-try.web.app/i/K7MP2QXR'),
              initialDelay: const Duration(milliseconds: 200),
            ),
            timeout: const Duration(milliseconds: 10),
          ),
          isNull,
        );
        expect(
          await stashLaunchInviteLink(store, _ThrowingLinkSource()),
          isNull,
        );
        expect(store.pendingCodeEntry, isFalse);
      },
    );
  });

  group('IncomingLinkHandler', () {
    test('an invite is kept, announced, then opened in the router', () async {
      final store = await _freshStore();
      final events = <String>[];
      final handler = IncomingLinkHandler(
        readStore: () => store,
        navigate: (location) {
          // Kept before navigating, so the redirect and splash see it.
          expect(store.pendingInviteCode, 'K7MP2QXR');
          events.add('go $location');
        },
        onInvite: (code) => events.add('invite $code'),
      );
      await handler.handle(Uri.parse('https://nod-try.web.app/i/k7mp2qxr'));
      expect(events, ['invite K7MP2QXR', 'go /i/K7MP2QXR']);
    });

    test('the same link delivered twice in a row is handled once', () async {
      var now = DateTime(2026, 11, 9, 12);
      final store = await _freshStore();
      final locations = <String>[];
      final handler = IncomingLinkHandler(
        readStore: () => store,
        navigate: locations.add,
        clock: () => now,
      );
      final uri = Uri.parse('https://nod-try.web.app/i/K7MP2QXR');
      await handler.handle(uri);
      await handler.handle(uri);
      expect(locations, ['/i/K7MP2QXR']);

      // Tapped again later: opened again.
      now = now.add(const Duration(seconds: 5));
      await handler.handle(uri);
      expect(locations, ['/i/K7MP2QXR', '/i/K7MP2QXR']);

      // A different link right away is not a repeat.
      await handler.handle(Uri.parse('https://nod-try.web.app/i/ABCD2345'));
      expect(locations.last, '/i/ABCD2345');
    });

    test(
      'custom-scheme routes pass through, foreign links do nothing',
      () async {
        final store = await _freshStore();
        final locations = <String>[];
        final handler = IncomingLinkHandler(
          readStore: () => store,
          navigate: locations.add,
        );
        await handler.handle(Uri.parse('onmybehalf://app/home'));
        await handler.handle(Uri.parse('https://example.com/i/K7MP2QXR'));
        expect(locations, ['/home']);
        expect(store.pendingCodeEntry, isFalse);
      },
    );

    test('still opens the invite when the store is unavailable', () async {
      final locations = <String>[];
      final handler = IncomingLinkHandler(
        readStore: () => throw StateError('no prefs'),
        navigate: locations.add,
      );
      await handler.handle(Uri.parse('https://nod-try.web.app/i/K7MP2QXR'));
      expect(locations, ['/i/K7MP2QXR']);
    });
  });

  group('incomingLinkBinderProvider', () {
    testWidgets('a warm-start invite link opens /i/{CODE} and keeps the code', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final source = _FakeLinkSource();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('start')),
          GoRoute(
            path: AppRoutes.inviteLink,
            builder: (_, state) =>
                Text('invite ${state.pathParameters['code']}'),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          incomingLinkSourceProvider.overrideWithValue(source),
          routerProvider.overrideWithValue(router),
        ],
      );
      addTearDown(container.dispose);
      container.read(incomingLinkBinderProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      expect(find.text('start'), findsOneWidget);

      source.controller.add(Uri.parse('https://nod-try.web.app/i/k7mp2qxr'));
      await tester.pumpAndSettle();

      expect(find.text('invite K7MP2QXR'), findsOneWidget);
      expect(container.read(openedInviteLinkProvider), 'K7MP2QXR');
      final store = OnboardingStore(prefs);
      expect(store.pendingInviteCode, 'K7MP2QXR');
      expect(store.pendingInviteSource, 'link');
    });

    test('a link plugin that errors is ignored', () {
      final container = ProviderContainer(
        overrides: [
          incomingLinkSourceProvider.overrideWithValue(_ThrowingLinkSource()),
        ],
      );
      addTearDown(container.dispose);
      expect(() => container.read(incomingLinkBinderProvider), returnsNormally);
    });
  });
}
