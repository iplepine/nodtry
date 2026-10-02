import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/core/services/client_metadata_sync.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/app_settings_provider.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserModel _profile({
  String uid = 'me',
  int? clientBuild,
  String? timezone,
  String? locale,
}) {
  final now = DateTime(2026, 10, 2);
  return UserModel(
    uid: uid,
    displayName: '나',
    createdAt: now,
    updatedAt: now,
    clientBuild: clientBuild,
    timezone: timezone,
    locale: locale,
  );
}

class _RecordingSync extends ClientMetadataSync {
  final calls = <({String uid, String locale})>[];

  @override
  Future<void> syncIfNeeded(UserModel profile, {required String locale}) async {
    calls.add((uid: profile.uid, locale: locale));
  }
}

void main() {
  group('resolveClientLocale', () {
    test('the Settings choice wins over the device', () {
      expect(resolveClientLocale(const Locale('ko'), const Locale('en')), 'ko');
      expect(resolveClientLocale(const Locale('en'), const Locale('ko')), 'en');
    });

    test('follows the device when there is no choice; unsupported is en', () {
      expect(resolveClientLocale(null, const Locale('ko', 'KR')), 'ko');
      expect(resolveClientLocale(null, const Locale('en', 'US')), 'en');
      expect(resolveClientLocale(null, const Locale('ja')), 'en');
    });
  });

  group('clientMetadataUpdates', () {
    test('nothing to write when the document already matches', () {
      expect(
        clientMetadataUpdates(
          profile: _profile(
            clientBuild: 81,
            timezone: 'Asia/Seoul',
            locale: 'ko',
          ),
          clientBuild: 81,
          timezone: 'Asia/Seoul',
          locale: 'ko',
        ),
        isEmpty,
      );
    });

    test('writes only what changed', () {
      expect(
        clientMetadataUpdates(
          profile: _profile(
            clientBuild: 80,
            timezone: 'Asia/Seoul',
            locale: 'ko',
          ),
          clientBuild: 81,
          timezone: 'Asia/Seoul',
          locale: 'en',
        ),
        {'clientBuild': 81, 'locale': 'en'},
      );
    });

    test('never erases a value it could not read', () {
      expect(
        clientMetadataUpdates(
          profile: _profile(
            clientBuild: 80,
            timezone: 'Asia/Seoul',
            locale: 'ko',
          ),
          clientBuild: null,
          timezone: '  ',
          locale: 'ko',
        ),
        isEmpty,
      );
    });
  });

  group('ClientMetadataSync.syncIfNeeded', () {
    late FakeFirebaseFirestore db;

    setUp(() => db = FakeFirebaseFirestore());

    ClientMetadataSync sync({String? signedInUid = 'me'}) => ClientMetadataSync(
      firestore: () => db,
      currentUid: () => signedInUid,
      readClientBuild: () async => 81,
      readTimezone: () async => 'Asia/Seoul',
    );

    test('merges the changed fields into the existing user document', () async {
      await db.collection('users').doc('me').set({
        'displayName': '나',
        'clientBuild': 80,
        'locale': 'ko',
      });

      await sync().syncIfNeeded(
        _profile(clientBuild: 80, locale: 'ko'),
        locale: 'ko',
      );

      final data = (await db.collection('users').doc('me').get()).data()!;
      expect(data['clientBuild'], 81);
      expect(data['timezone'], 'Asia/Seoul');
      expect(data['locale'], 'ko');
      expect(data['displayName'], '나', reason: 'other fields are kept');
    });

    test('writes nothing when the profile already matches', () async {
      await db.collection('users').doc('me').set({'displayName': '나'});

      await sync().syncIfNeeded(
        _profile(clientBuild: 81, timezone: 'Asia/Seoul', locale: 'ko'),
        locale: 'ko',
      );

      final data = (await db.collection('users').doc('me').get()).data()!;
      expect(data.containsKey('clientBuild'), isFalse);
      expect(data.containsKey('timezone'), isFalse);
      expect(data.containsKey('locale'), isFalse);
    });

    test('skips a cached profile of another account', () async {
      await db.collection('users').doc('other').set({'displayName': 'x'});

      await sync().syncIfNeeded(_profile(uid: 'other'), locale: 'en');

      final data = (await db.collection('users').doc('other').get()).data()!;
      expect(data.containsKey('clientBuild'), isFalse);
    });

    test('never creates a user document', () async {
      await sync().syncIfNeeded(_profile(), locale: 'ko');

      expect((await db.collection('users').doc('me').get()).exists, isFalse);
    });
  });

  group('clientMetadataSyncBinderProvider', () {
    test('syncs on sign-in and again when the app language changes', () async {
      SharedPreferences.setMockInitialValues({'app.locale_override': 'ko'});
      final prefs = await SharedPreferences.getInstance();
      final recorder = _RecordingSync();
      final profiles = StreamController<UserModel?>();
      addTearDown(profiles.close);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clientMetadataSyncProvider.overrideWithValue(recorder),
          myProfileProvider.overrideWith((ref) => profiles.stream),
        ],
      );
      addTearDown(container.dispose);
      // The app root watches the binder; mirror that (an unlistened provider
      // is paused and its listeners would not run).
      container.listen(clientMetadataSyncBinderProvider, (_, _) {});

      // No user document yet: nothing to sync.
      expect(recorder.calls, isEmpty);

      profiles.add(_profile());
      await Future<void>.delayed(Duration.zero);
      expect(recorder.calls, [(uid: 'me', locale: 'ko')]);

      container
          .read(appSettingsProvider.notifier)
          .setLocale(const Locale('en'));
      await Future<void>.delayed(Duration.zero);
      expect(recorder.calls.last, (uid: 'me', locale: 'en'));
    });
  });
}
