import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/core/services/app_version_gate.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('evaluateAppUpdate', () {
    AppUpdateRequirement eval(int? build, {int? min, int? latest}) =>
        evaluateAppUpdate(
          currentBuild: build,
          config: AppVersionConfig(minBuild: min, latestBuild: latest),
        );

    test('below minBuild blocks', () {
      expect(eval(80, min: 81, latest: 85), AppUpdateRequirement.required);
    });

    test('at minBuild but below latestBuild suggests', () {
      expect(eval(81, min: 81, latest: 85), AppUpdateRequirement.soft);
    });

    test('at or above latestBuild is fine', () {
      expect(eval(85, min: 81, latest: 85), AppUpdateRequirement.none);
      expect(eval(90, min: 81, latest: 85), AppUpdateRequirement.none);
    });

    test('missing values never gate', () {
      expect(eval(null, min: 100, latest: 100), AppUpdateRequirement.none);
      expect(eval(80), AppUpdateRequirement.none);
      expect(eval(80, latest: 81), AppUpdateRequirement.soft);
      expect(eval(80, min: 81), AppUpdateRequirement.required);
    });
  });

  group('AppVersionConfig.fromMap', () {
    test('accepts ints, doubles and numeric strings', () {
      final config = AppVersionConfig.fromMap({
        'minBuild': 81.0,
        'latestBuild': ' 85 ',
      });
      expect(config.minBuild, 81);
      expect(config.latestBuild, 85);
    });

    test('ignores junk and a missing document', () {
      final junk = AppVersionConfig.fromMap({'minBuild': 'abc', 'x': 1});
      expect(junk.minBuild, isNull);
      expect(junk.latestBuild, isNull);
      expect(AppVersionConfig.fromMap(null).minBuild, isNull);
    });
  });

  group('shouldShowSoftUpdatePrompt', () {
    const soft = AppVersionStatus(
      requirement: AppUpdateRequirement.soft,
      currentBuild: 81,
      latestBuild: 85,
    );

    test('shows once per latestBuild', () {
      expect(shouldShowSoftUpdatePrompt(soft, dismissedForBuild: null), isTrue);
      expect(shouldShowSoftUpdatePrompt(soft, dismissedForBuild: 85), isFalse);
      // A newer latestBuild asks again.
      expect(shouldShowSoftUpdatePrompt(soft, dismissedForBuild: 84), isTrue);
    });

    test('never for other requirements', () {
      expect(
        shouldShowSoftUpdatePrompt(
          AppVersionStatus.unknown,
          dismissedForBuild: null,
        ),
        isFalse,
      );
    });
  });

  test('store links point at this app on each platform', () {
    expect(storeUrlForPlatform(TargetPlatform.iOS), kAppStoreUrl);
    expect(storeUrlForPlatform(TargetPlatform.android), kPlayStoreUrl);
    expect(kAppStoreUrl, 'https://apps.apple.com/kr/app/id6761373605');
    expect(kPlayStoreUrl, contains('id=com.devho.nodtry.app'));
  });

  group('AppVersionGateService.check', () {
    late FakeFirebaseFirestore db;

    setUp(() => db = FakeFirebaseFirestore());

    AppVersionGateService service(
      Future<int?> Function() build, {
      Duration timeout = kAppVersionCheckTimeout,
    }) => AppVersionGateService(
      firestore: () => db,
      readCurrentBuild: build,
      timeout: timeout,
    );

    test('reads config/app and compares with the installed build', () async {
      await db.collection('config').doc('app').set({
        'minBuild': 81,
        'latestBuild': 85,
      });

      final blocked = await service(() async => 80).check();
      expect(blocked.requirement, AppUpdateRequirement.required);

      final suggested = await service(() async => 83).check();
      expect(suggested.requirement, AppUpdateRequirement.soft);
      expect(suggested.latestBuild, 85);
      expect(suggested.currentBuild, 83);

      final current = await service(() async => 85).check();
      expect(current.requirement, AppUpdateRequirement.none);
    });

    test('no config document means no gate', () async {
      final status = await service(() async => 1).check();
      expect(status.requirement, AppUpdateRequirement.none);
    });

    test('a failing build read means no gate', () async {
      await db.collection('config').doc('app').set({'minBuild': 999});
      final status = await service(() async => throw Exception('no')).check();
      expect(status.requirement, AppUpdateRequirement.none);
    });

    test('no Firebase means no gate', () async {
      final status = await AppVersionGateService(
        firestore: () => throw StateError('No Firebase App'),
        readCurrentBuild: () async => 1,
      ).check();
      expect(status.requirement, AppUpdateRequirement.none);
    });

    test('a read slower than the timeout means no gate', () async {
      await db.collection('config').doc('app').set({'minBuild': 999});
      final never = Completer<int?>();
      final status = await service(
        () => never.future,
        timeout: const Duration(milliseconds: 20),
      ).check();
      expect(status.requirement, AppUpdateRequirement.none);
    });
  });

  group('AppVersionGate widget', () {
    late SharedPreferences prefs;
    late int storeOpens;
    late AppLocalizations l10n;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storeOpens = 0;
      l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    });

    Widget app(Future<AppVersionStatus> Function() status) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appVersionStatusProvider.overrideWith((ref) => status()),
          openStorePageProvider.overrideWithValue(() async {
            storeOpens++;
            return true;
          }),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AppVersionGate(child: child!),
          home: const Scaffold(body: Text('home')),
        ),
      );
    }

    testWidgets('passes the app through while the check is running', (
      tester,
    ) async {
      final pending = Completer<AppVersionStatus>();
      await tester.pumpWidget(app(() => pending.future));
      await tester.pump();

      expect(find.text('home'), findsOneWidget);
      expect(find.text(l10n.appUpdateRequiredTitle), findsNothing);
    });

    testWidgets('a build below minBuild is blocked with a store button', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          () async => const AppVersionStatus(
            requirement: AppUpdateRequirement.required,
            currentBuild: 80,
            latestBuild: 85,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('home'), findsNothing);
      expect(find.text(l10n.appUpdateRequiredTitle), findsOneWidget);
      expect(find.text(l10n.appUpdateLater), findsNothing);

      await tester.tap(find.text(l10n.appUpdateButton));
      await tester.pump();
      expect(storeOpens, 1);
    });

    testWidgets('a soft update is suggested once per latestBuild', (
      tester,
    ) async {
      Future<AppVersionStatus> soft() async => const AppVersionStatus(
        requirement: AppUpdateRequirement.soft,
        currentBuild: 81,
        latestBuild: 85,
      );

      await tester.pumpWidget(app(soft));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(find.text(l10n.appUpdateSoftTitle), findsOneWidget);

      await tester.tap(find.text(l10n.appUpdateLater));
      await tester.pumpAndSettle();
      expect(find.text(l10n.appUpdateSoftTitle), findsNothing);
      expect(storeOpens, 0);
      expect(prefs.getInt(kSoftUpdateDismissedBuildKey), 85);

      // Next launch: same latestBuild, no prompt.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app(soft));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(find.text(l10n.appUpdateSoftTitle), findsNothing);
    });

    testWidgets('an up-to-date build sees nothing extra', (tester) async {
      await tester.pumpWidget(app(() async => AppVersionStatus.unknown));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text(l10n.appUpdateSoftTitle), findsNothing);
      expect(find.text(l10n.appUpdateRequiredTitle), findsNothing);
    });
  });
}
