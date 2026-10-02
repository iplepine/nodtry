import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/domain/invite_code.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/repositories/connect_repository.dart';
import 'package:nod_try/repositories/real_connect_repository.dart';
import 'package:nod_try/repositories/real_record_repository.dart';
import 'package:nod_try/repositories/real_user_repository.dart';

import '../support/participant_query_spy.dart';

/// What the callable SDK throws: an HttpsError from our functions carries
/// `details.reason`; a function that isn't deployed is a bare not-found.
class _CallableError extends FirebaseFunctionsException {
  _CallableError(String code, {String? reason})
    : super(
        code: code,
        message: code,
        details: reason == null ? null : {'reason': reason},
      );
}

/// Records callable invocations and answers with [answer].
class _Callables {
  _Callables(this.answer);

  /// A backend without the invite-code callables (deployed before them).
  _Callables.missing() : answer = ((_, _) => throw _CallableError('not-found'));

  final Object? Function(String name, Map<String, Object?> data) answer;
  final calls = <String>[];

  Future<Object?> call(String name, Map<String, Object?> data) async {
    calls.add('$name ${data['code']}');
    return answer(name, data);
  }
}

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

/// A signed-in guest, as initializeUser reads it ([email] for an account
/// that has one).
class _GuestUser extends Fake implements User {
  _GuestUser(this.uid, {this.email});

  @override
  final String uid;

  @override
  bool get isAnonymous => email == null;

  @override
  List<UserInfo> get providerData => const [];

  @override
  final String? email;

  @override
  String? get displayName => null;

  @override
  String? get photoURL => null;
}

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(String uid) : currentUser = _FakeUser(uid);

  @override
  final User? currentUser;
}

Future<void> _seedUser(
  FakeFirebaseFirestore db,
  String uid, {
  String? code,
  String? nickname,
}) {
  return db.collection('users').doc(uid).set({
    'displayName': uid,
    if (code != null) 'inviteCode': code,
    if (nickname != null) 'partnerNickname': nickname,
    'loginType': 'guest',
    'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
    'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
  });
}

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  group('RealConnectRepository.connectWithCode via redeemInviteCode', () {
    late ParticipantQuerySpy spy;
    setUp(() => spy = ParticipantQuerySpy(db));

    RealConnectRepository repoWith(_Callables callables) =>
        RealConnectRepository(
          firestore: spy,
          auth: _FakeAuth('me'),
          callables: callables.call,
        );

    test('links on the server: no users query, no client writes', () async {
      final callables = _Callables(
        (_, _) => {'partnerId': 'owner', 'alreadyLinked': false},
      );

      final owner = await repoWith(callables).connectWithCode(' k7mp-2qxr ');

      expect(owner, 'owner');
      expect(callables.calls, ['redeemInviteCode K7MP2QXR']);
      expect(spy.queries, isEmpty);
      expect((await db.collection('relations').get()).docs, isEmpty);
    });

    test('an existing link is a success', () async {
      final callables = _Callables(
        (_, _) => {'partnerId': 'owner', 'alreadyLinked': true},
      );
      expect(await repoWith(callables).connectWithCode('K7MP2QXR'), 'owner');
    });

    test('a malformed code never reaches the server', () async {
      final callables = _Callables((_, _) => fail('called'));
      await expectLater(
        repoWith(callables).connectWithCode('nope'),
        throwsA(isA<InviteCodeNotFoundException>()),
      );
      expect(callables.calls, isEmpty);
    });

    test('the server\'s reasons surface as today\'s errors', () async {
      Future<void> expectReason(String reason, Matcher matcher) async {
        final callables = _Callables(
          (_, _) => throw _CallableError('failed-precondition', reason: reason),
        );
        await expectLater(
          repoWith(callables).connectWithCode('K7MP2QXR'),
          throwsA(matcher),
          reason: reason,
        );
      }

      await expectReason('not_found', isA<InviteCodeNotFoundException>());
      await expectReason('code_format', isA<InviteCodeNotFoundException>());
      await expectReason('self_code', isA<InviteCodeIsMineException>());
      await expectReason(
        'owner_taken',
        isA<InviteLinkRefusedException>().having(
          (e) => e.reason,
          'reason',
          'owner_taken',
        ),
      );
      await expectReason(
        'self_taken',
        isA<InviteLinkRefusedException>().having(
          (e) => e.reason,
          'reason',
          'self_taken',
        ),
      );
      await expectReason('rate_limited', isA<FirebaseFunctionsException>());
      expect(spy.queries, isEmpty);
    });

    test(
      '"not found" from the server never falls back to the users query',
      () async {
        // The code is on a users doc, but the server says nobody holds it (e.g.
        // it was just rotated): the old client-side path must not link anyway.
        await _seedUser(db, 'owner', code: 'K7MP2QXR');
        final callables = _Callables(
          (_, _) => throw _CallableError('not-found', reason: 'not_found'),
        );

        await expectLater(
          repoWith(callables).connectWithCode('K7MP2QXR'),
          throwsA(isA<InviteCodeNotFoundException>()),
        );
        expect(spy.queries, isEmpty);
        expect((await db.collection('relations').get()).docs, isEmpty);
      },
    );

    test('other failures (offline, internal) are thrown as is', () async {
      final callables = _Callables(
        (_, _) => throw _CallableError('unavailable'),
      );
      await expectLater(
        repoWith(callables).connectWithCode('K7MP2QXR'),
        throwsA(isA<FirebaseFunctionsException>()),
      );
      expect(spy.queries, isEmpty);
    });

    test('a backend without the callable links the old way', () async {
      await _seedUser(db, 'owner', code: 'K7MP2QXR');
      for (final missing in ['not-found', 'unimplemented']) {
        await db.collection('relations').get().then((s) async {
          for (final doc in s.docs) {
            await doc.reference.delete();
          }
        });
        final callables = _Callables((_, _) => throw _CallableError(missing));

        expect(await repoWith(callables).connectWithCode('K7MP2QXR'), 'owner');
        expect((await db.collection('relations').get()).docs, hasLength(2));
      }
      // The legacy lookup is the one users query (denied under rules.next,
      // which is only deployed once the callables are).
      expect(spy.shapes.toSet(), {
        'users where inviteCode == K7MP2QXR limit 1',
      });
    });
  });

  group('RealConnectRepository.connectWithCode (no callable yet)', () {
    test(
      'writes both relation docs stamped with the inviter and code',
      () async {
        await _seedUser(db, 'owner', code: 'K7MP2QXR');
        await _seedUser(db, 'me', code: 'MYC2DE34');
        final repo = RealConnectRepository(
          firestore: db,
          auth: _FakeAuth('me'),
          callables: _Callables.missing().call,
        );

        final owner = await repo.connectWithCode(' k7mp-2qxr ');

        expect(owner, 'owner');
        final relations = await db.collection('relations').get();
        expect(relations.docs, hasLength(2));
        final pairs = relations.docs
            .map((d) => '${d['managerId']}>${d['executorId']}')
            .toSet();
        expect(pairs, {'owner>me', 'me>owner'});
        for (final doc in relations.docs) {
          // Read by the server's onRelationCreated (inviter push, stale codes).
          expect(doc['inviterId'], 'owner');
          expect(doc['inviteCode'], 'K7MP2QXR');
          expect(doc['status'], 'active');
        }
      },
    );

    test('an unknown code writes nothing', () async {
      final repo = RealConnectRepository(
        firestore: db,
        auth: _FakeAuth('me'),
        callables: _Callables.missing().call,
      );
      await expectLater(
        repo.connectWithCode('ZZZZ2345'),
        throwsA(isA<InviteCodeNotFoundException>()),
      );
      await expectLater(
        repo.connectWithCode('nope'),
        throwsA(isA<InviteCodeNotFoundException>()),
      );
      expect((await db.collection('relations').get()).docs, isEmpty);
    });

    test('my own code writes nothing', () async {
      await _seedUser(db, 'me', code: 'MYC2DE34');
      final repo = RealConnectRepository(
        firestore: db,
        auth: _FakeAuth('me'),
        callables: _Callables.missing().call,
      );
      await expectLater(
        repo.connectWithCode('MYC2DE34'),
        throwsA(isA<InviteCodeIsMineException>()),
      );
      expect((await db.collection('relations').get()).docs, isEmpty);
    });
  });

  test('disconnecting deletes the pair and my nickname for them', () async {
    await _seedUser(db, 'owner', code: 'K7MP2QXR');
    await _seedUser(db, 'me', code: 'MYC2DE34', nickname: '자기');
    final repo = RealConnectRepository(
      firestore: db,
      auth: _FakeAuth('me'),
      callables: _Callables.missing().call,
    );
    await repo.connectWithCode('K7MP2QXR');
    // Another couple's link stays.
    await db.collection('relations').add({
      'managerId': 'mallory',
      'executorId': 'carol',
    });

    await repo.disconnectByUser('owner');

    final left = (await db.collection('relations').get()).docs;
    expect(left.map((d) => d['managerId']), ['mallory']);
    final me = await db.collection('users').doc('me').get();
    expect(me.data()!.containsKey('partnerNickname'), isFalse);
  });

  test('generateInviteCode stores a code from the new alphabet', () async {
    await _seedUser(db, 'me', code: 'OLD0CODE');
    final repo = RealConnectRepository(firestore: db, auth: _FakeAuth('me'));

    final code = await repo.generateInviteCode();

    expect(code.split('').every(kInviteCodeAlphabet.contains), isTrue);
    final me = await db.collection('users').doc('me').get();
    expect(me['inviteCode'], code);
  });

  group('RealUserRepository', () {
    test('saves, trims and clears the partner nickname', () async {
      await _seedUser(db, 'me');
      final repo = RealUserRepository(firestore: db, auth: _FakeAuth('me'));

      await repo.updatePartnerNickname('  우리 자기  ');
      var me = await db.collection('users').doc('me').get();
      expect(me['partnerNickname'], '우리 자기');

      await repo.updatePartnerNickname('가나다라마바사아자차카타');
      me = await db.collection('users').doc('me').get();
      expect((me['partnerNickname'] as String).runes.length, 10);

      await repo.updatePartnerNickname(null);
      me = await db.collection('users').doc('me').get();
      expect(me.data()!.containsKey('partnerNickname'), isFalse);
    });

    test('markPivotNoticeSeen sets the optional flag', () async {
      await _seedUser(db, 'me');
      final repo = RealUserRepository(firestore: db, auth: _FakeAuth('me'));
      await repo.markPivotNoticeSeen();
      final me = await db.collection('users').doc('me').get();
      expect(me['pivotNoticeSeen'], isTrue);
    });

    test(
      'getUserByInviteCode without the callable: normalizes, skips malformed '
      'codes, and refuses my own',
      () async {
        await _seedUser(db, 'owner', code: 'K7MP2QXR');
        await _seedUser(db, 'me', code: 'MYC2DE34');
        final repo = RealUserRepository(
          firestore: db,
          auth: _FakeAuth('me'),
          callables: _Callables.missing().call,
        );
        expect((await repo.getUserByInviteCode('k7mp 2qxr'))?.uid, 'owner');
        expect(await repo.getUserByInviteCode('short'), isNull);
        expect(await repo.getUserByInviteCode('ZZZZ2345'), isNull);
        await expectLater(
          repo.getUserByInviteCode('MYC2DE34'),
          throwsA(isA<InviteCodeIsMineException>()),
        );
      },
    );

    group('getUserByInviteCode via resolveInviteCode', () {
      late ParticipantQuerySpy spy;
      setUp(() => spy = ParticipantQuerySpy(db));

      RealUserRepository repoWith(_Callables callables) => RealUserRepository(
        firestore: spy,
        auth: _FakeAuth('me'),
        callables: callables.call,
      );

      test('returns the owner the server resolved, without a query', () async {
        final callables = _Callables(
          (_, _) => {
            'uid': 'owner',
            'displayName': '지민',
            'profileImageUrl': 'https://example.com/p.jpg',
          },
        );

        final owner = await repoWith(
          callables,
        ).getUserByInviteCode('k7mp-2qxr');

        expect(owner?.uid, 'owner');
        expect(owner?.displayName, '지민');
        expect(owner?.profileImageUrl, 'https://example.com/p.jpg');
        expect(owner?.inviteCode, 'K7MP2QXR');
        expect(callables.calls, ['resolveInviteCode K7MP2QXR']);
        expect(spy.queries, isEmpty);
      });

      test('nobody / malformed is null; my own code throws', () async {
        Future<UserModel?> lookup(Object? Function() answer) => repoWith(
          _Callables((_, _) => answer()),
        ).getUserByInviteCode('K7MP2QXR');

        expect(
          await lookup(
            () => throw _CallableError('not-found', reason: 'not_found'),
          ),
          isNull,
        );
        expect(
          await lookup(
            () =>
                throw _CallableError('invalid-argument', reason: 'code_format'),
          ),
          isNull,
        );
        await expectLater(
          lookup(
            () => throw _CallableError(
              'failed-precondition',
              reason: 'self_code',
            ),
          ),
          throwsA(isA<InviteCodeIsMineException>()),
        );
        await expectLater(
          lookup(() => {'uid': 'me'}),
          throwsA(isA<InviteCodeIsMineException>()),
        );
        await expectLater(
          lookup(
            () => throw _CallableError(
              'resource-exhausted',
              reason: 'rate_limited',
            ),
          ),
          throwsA(isA<FirebaseFunctionsException>()),
        );
        expect(spy.queries, isEmpty);
      });
    });

    test('profiles are read one doc per uid', () async {
      await _seedUser(db, 'owner');
      final spy = ParticipantQuerySpy(db);
      final repo = RealUserRepository(firestore: spy, auth: _FakeAuth('me'));

      final users = await repo.getUsersByIds(['owner', 'gone']);

      expect(users.map((u) => u.uid), ['owner']);
      expect(spy.queries, isEmpty);
    });

    test('never writes the account email to the users doc', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final spy = ParticipantQuerySpy(db);
      final repo = RealUserRepository(firestore: spy, auth: _FakeAuth('me'));

      await repo.initializeUser(_GuestUser('fresh', email: 'new@example.com'));
      final fresh = await db.collection('users').doc('fresh').get();
      expect(fresh.data()!.containsKey('email'), isFalse);
      // No invite-code uniqueness query (users can't be listed).
      expect(spy.queries, isEmpty);

      // An older doc keeps what it has (ops strips it), but isn't updated.
      await db.collection('users').doc('old').set({
        'email': 'old@example.com',
        'loginType': 'guest',
        'isAnonymous': false,
        'inviteCode': 'K7MP2QXR',
      });
      await repo.initializeUser(
        _GuestUser('old', email: 'changed@example.com'),
      );
      final old = await db.collection('users').doc('old').get();
      expect(old['email'], 'old@example.com');
    });

    test('UserModel neither reads nor writes email in Firestore', () async {
      await db.collection('users').doc('p').set({
        'displayName': 'p',
        'email': 'p@example.com',
      });
      final model = UserModel.fromFirestore(
        await db.collection('users').doc('p').get(),
      );
      expect(model.email, isNull);

      final withEmail = UserModel(
        uid: 'x',
        email: 'x@example.com',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(withEmail.toFirestore().containsKey('email'), isFalse);
    });

    test(
      'new accounts and backfills get codes from the new alphabet',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final repo = RealUserRepository(firestore: db, auth: _FakeAuth('me'));

        await repo.initializeUser(_GuestUser('fresh'));
        final fresh = await db.collection('users').doc('fresh').get();
        final freshCode = fresh['inviteCode'] as String;
        expect(isValidInviteCode(freshCode), isTrue);
        expect(freshCode.split('').every(kInviteCodeAlphabet.contains), isTrue);

        await db.collection('users').doc('old').set({
          'displayName': 'old',
          'loginType': 'guest',
          'isAnonymous': true,
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'updatedAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        });
        await repo.initializeUser(_GuestUser('old'));
        final old = await db.collection('users').doc('old').get();
        final oldCode = old['inviteCode'] as String;
        expect(oldCode.split('').every(kInviteCodeAlphabet.contains), isTrue);
      },
    );
  });

  group('UserModel nickname fields', () {
    test(
      'read from Firestore, optional, and kept in the local cache',
      () async {
        await _seedUser(db, 'me', nickname: ' 여보 ');
        final doc = await db.collection('users').doc('me').get();
        final model = UserModel.fromFirestore(doc);
        expect(model.partnerNickname, '여보');
        expect(model.pivotNoticeSeen, isNull);

        final cached = UserModel.fromJson(
          model.copyWith(pivotNoticeSeen: true).toJson(),
        );
        expect(cached.partnerNickname, '여보');
        expect(cached.pivotNoticeSeen, isTrue);
        expect(
          model.copyWith(clearPartnerNickname: true).partnerNickname,
          isNull,
        );
      },
    );

    test('old documents without the fields still load', () async {
      await db.collection('users').doc('old').set({
        'displayName': 'old',
        'partnerNickname': '',
        'pivotNoticeSeen': 'yes',
      });
      final doc = await db.collection('users').doc('old').get();
      final model = UserModel.fromFirestore(doc);
      expect(model.partnerNickname, isNull);
      expect(model.pivotNoticeSeen, isNull);
      expect(model.toFirestore().containsKey('partnerNickname'), isFalse);
    });
  });

  group('assignManagerToActivePlans', () {
    Future<void> seedPlan(String id, Map<String, Object?> data) {
      return db.collection('plans').doc(id).set({
        'userId': 'me',
        'items': [],
        'startDate': Timestamp.fromDate(DateTime(2026, 10, 1)),
        'endDate': Timestamp.fromDate(DateTime(2026, 10, 28)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
        ...data,
      });
    }

    test(
      'gives unmanaged running promises the partner and keeps them running',
      () async {
        await seedPlan('solo', {'state': 'active'});
        await seedPlan('managed', {'state': 'active', 'managerId': 'other'});
        await seedPlan('done', {'state': 'completed'});
        final repo = RealRecordRepository(firestore: db, auth: _FakeAuth('me'));

        await repo.assignManagerToActivePlans('partner');

        final solo = await db.collection('plans').doc('solo').get();
        expect(solo['managerId'], 'partner');
        // No approval step any more: the promise stays active.
        expect(solo['state'], 'active');
        expect(solo['lastUpdatedBy'], kSystemLinkUpdater);

        final managed = await db.collection('plans').doc('managed').get();
        expect(managed['managerId'], 'other');
        final done = await db.collection('plans').doc('done').get();
        expect(done.data()!.containsKey('managerId'), isFalse);
      },
    );
  });
}
