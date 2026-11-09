import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/application/invite_services.dart';
import 'package:nod_try/features/connect/application/invite_tracker.dart';
import 'package:nod_try/features/connect/presentation/widgets/invite_share_panel.dart';
import 'package:nod_try/features/now/application/notification_routing.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _myCode = 'MYC2DE34';

class _FakeSharer implements InviteSharer {
  _FakeSharer(this.result);

  final InviteShareResult result;

  @override
  Future<InviteShareResult> share({
    required String text,
    String? subject,
    Rect? origin,
  }) async => result;
}

class _FakeClipboard implements InviteClipboard {
  @override
  Future<bool> hasStrings() async => false;

  @override
  Future<String?> readText() async => null;

  @override
  Future<void> writeText(String text) async {}
}

class _FakeRecords extends Fake implements RecordRepository {
  @override
  Stream<List<Plan>> getPlansByUserIdStream(String userId) =>
      Stream.value(const []);
}

class _ThrowingTracker implements InviteTracker {
  int calls = 0;

  @override
  Future<void> recordShare({required String uid, required String code}) {
    calls++;
    throw StateError('offline');
  }
}

UserModel _me() {
  final now = DateTime(2026, 11, 9);
  return UserModel(
    uid: 'me',
    displayName: '민수',
    inviteCode: _myCode,
    createdAt: now,
    updatedAt: now,
  );
}

Future<ProviderContainer> _pumpPanel(
  WidgetTester tester, {
  required InviteTracker tracker,
  required InviteShareResult result,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      myProfileProvider.overrideWithValue(AsyncData(_me())),
      recordRepositoryProvider.overrideWithValue(_FakeRecords()),
      inviteSharerProvider.overrideWithValue(_FakeSharer(result)),
      inviteClipboardProvider.overrideWithValue(_FakeClipboard()),
      inviteTrackerProvider.overrideWithValue(tracker),
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
  return container;
}

void main() {
  group('FirestoreInviteTracker', () {
    late FakeFirebaseFirestore db;
    late FirestoreInviteTracker tracker;

    setUp(() {
      db = FakeFirebaseFirestore();
      tracker = FirestoreInviteTracker(() => db);
    });

    test('the first share creates invites/{uid} with the client fields '
        'only', () async {
      await tracker.recordShare(uid: 'me', code: _myCode);

      final data = (await db.doc('invites/me').get()).data()!;
      expect(data.keys.toSet(), {
        'inviterUid',
        'code',
        'createdAt',
        'lastSharedAt',
        'shareCount',
      });
      expect(data['inviterUid'], 'me');
      expect(data['code'], _myCode);
      expect(data['shareCount'], 1);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['lastSharedAt'], isA<Timestamp>());
    });

    test('sharing again bumps the count and keeps the server fields', () async {
      final createdAt = Timestamp.fromDate(DateTime(2026, 11, 1));
      await db.doc('invites/me').set({
        'inviterUid': 'me',
        'code': 'OLDC0DE2',
        'createdAt': createdAt,
        'lastSharedAt': createdAt,
        'shareCount': 2,
        'remindersSent': 2,
        'remindersCycleAt': createdAt,
      });

      await tracker.recordShare(uid: 'me', code: _myCode);

      final data = (await db.doc('invites/me').get()).data()!;
      expect(data['code'], _myCode);
      expect(data['shareCount'], 3);
      expect(data['createdAt'], createdAt);
      expect(
        (data['lastSharedAt'] as Timestamp).toDate().isAfter(
          createdAt.toDate(),
        ),
        isTrue,
      );
      // Server-only: untouched (the new lastSharedAt starts a new cycle).
      expect(data['remindersSent'], 2);
      expect(data['remindersCycleAt'], createdAt);
    });
  });

  group('share → invites upsert', () {
    testWidgets('the share button records the invite', (tester) async {
      final db = FakeFirebaseFirestore();
      await _pumpPanel(
        tester,
        tracker: FirestoreInviteTracker(() => db),
        result: const InviteShareResult(shared: true, channel: 'kakao'),
      );

      await tester.tap(find.byKey(const ValueKey('invite-share-button')));
      await tester.pumpAndSettle();

      final data = (await db.doc('invites/me').get()).data();
      expect(data, isNotNull);
      expect(data!['code'], _myCode);
      expect(data['shareCount'], 1);
    });

    testWidgets('copying the code records it too', (tester) async {
      final db = FakeFirebaseFirestore();
      await _pumpPanel(
        tester,
        tracker: FirestoreInviteTracker(() => db),
        result: const InviteShareResult(shared: true, channel: 'kakao'),
      );

      await tester.tap(find.byKey(const ValueKey('invite-copy-button')));
      await tester.pumpAndSettle();

      expect((await db.doc('invites/me').get()).data()?['code'], _myCode);
    });

    testWidgets('a dismissed share sheet records nothing', (tester) async {
      final db = FakeFirebaseFirestore();
      await _pumpPanel(
        tester,
        tracker: FirestoreInviteTracker(() => db),
        result: const InviteShareResult(shared: false, channel: 'dismissed'),
      );

      await tester.tap(find.byKey(const ValueKey('invite-share-button')));
      await tester.pumpAndSettle();

      expect((await db.doc('invites/me').get()).exists, isFalse);
    });

    testWidgets('a failing write never breaks the share', (tester) async {
      final tracker = _ThrowingTracker();
      final container = await _pumpPanel(
        tester,
        tracker: tracker,
        result: const InviteShareResult(shared: true, channel: 'kakao'),
      );

      await tester.tap(find.byKey(const ValueKey('invite-share-button')));
      await tester.pumpAndSettle();

      expect(tracker.calls, 1);
      expect(container.read(inviteSharedAtProvider), isNotNull);
      final ko = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(find.text(ko.connectInviteSent), findsOneWidget);
    });
  });

  test('an invite_reminder push opens the invite screen', () {
    expect(
      notificationOpenTargetFor('invite_reminder'),
      NotificationOpenTarget.invite,
    );
  });
}
