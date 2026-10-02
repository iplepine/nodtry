import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/repositories/real_record_repository.dart';
import 'package:nod_try/utils/context_free_l10n.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(String uid) : currentUser = _FakeUser(uid);

  @override
  final User? currentUser;
}

const _owner = 'owner-uid';
const _manager = 'manager-uid';

Map<String, dynamic> _planDoc({bool withTitle = true}) {
  final now = DateTime.now();
  return {
    'userId': _owner,
    'managerId': _manager,
    'state': 'active',
    'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'endDate': Timestamp.fromDate(now.add(const Duration(days: 20))),
    'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'items': withTitle
        ? [
            {
              'title': '헬스장 가기',
              'days': [1, 2, 3, 4, 5, 6, 7],
              'count': 7,
            },
          ]
        : <Map<String, dynamic>>[],
    'completedDates': <Timestamp>[],
    'verifiedDates': <Timestamp>[],
  };
}

/// Copy the pivot retired. None of it may be written to Firestore or shown.
final _retired = RegExp(r'실천 메이트|accountability partner|님');

void main() {
  late FakeFirebaseFirestore db;

  RealRecordRepository repoAs(String uid) =>
      RealRecordRepository(firestore: db, auth: _FakeAuth(uid));

  setUp(() {
    db = FakeFirebaseFirestore();
    setContextFreeLocaleCode('ko');
  });

  tearDown(() => setContextFreeLocaleCode(null));

  group('default knock messages', () {
    test(
      'a plan knock without a message stores the partner-free default',
      () async {
        await db.collection('plans').doc('plan-1').set(_planDoc());

        await repoAs(_manager).pokePartner('plan-1');

        final plan = (await db.collection('plans').doc('plan-1').get()).data()!;
        expect(plan['lastPokeMessage'], kDefaultPlanPokeMessage);
        expect(plan['lastPokeMessage'], isNot(matches(_retired)));
        expect(plan['lastPokeMessage'], contains('똑똑'));
      },
    );

    test('a passed message is stored as is', () async {
      await db.collection('plans').doc('plan-1').set(_planDoc());

      await repoAs(_manager).pokePartner('plan-1', message: '헬스장 가자 🏃');

      final plan = (await db.collection('plans').doc('plan-1').get()).data()!;
      expect(plan['lastPokeMessage'], '헬스장 가자 🏃');
    });

    test('a user knock without a message stores the workout default', () async {
      await repoAs(_manager).pokeUser(_owner);

      final cheers = await db.collection('cheers').get();
      expect(cheers.docs, hasLength(1));
      final cheer = cheers.docs.single.data();
      expect(cheer['message'], kDefaultUserPokeMessage);
      expect(cheer['message'], isNot(matches(_retired)));
      expect(cheer['reactionType'], 'poke');
    });
  });

  group('poke header', () {
    test('shows the stored knock message', () {
      expect(pokeHeaderFor('헬스장 가자 🏃'), '헬스장 가자 🏃');
    });

    test('replaces a legacy 실천 메이트 message with the current default', () async {
      final ko = await AppLocalizations.delegate.load(const Locale('ko'));
      const legacy = '똑똑! 실천 메이트가 기다리고 있어요. 오늘 약속을 정리해볼까요?';

      expect(pokeHeaderFor(legacy), ko.nowHeaderPokeWaiting);
      expect(pokeHeaderFor(legacy), isNot(matches(_retired)));
    });

    test('falls back to the default when the message is empty', () async {
      final ko = await AppLocalizations.delegate.load(const Locale('ko'));

      expect(pokeHeaderFor(null), ko.nowHeaderPokeWaiting);
      expect(pokeHeaderFor('   '), ko.nowHeaderPokeWaiting);
    });

    test('follows the app language picked in Settings', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      setContextFreeLocaleCode('en');

      expect(pokeHeaderFor(null), en.nowHeaderPokeWaiting);
    });
  });

  group('untitled plan fallback', () {
    test('a record of an untitled plan gets the neutral "약속" title', () async {
      await db
          .collection('plans')
          .doc('plan-1')
          .set(_planDoc(withTitle: false));

      await repoAs(_owner).reportCompletion('plan-1');

      final actions = await db.collection('actions').get();
      expect(actions.docs.single.data()['title'], '약속');
    });

    test('uses the English fallback when the app is in English', () async {
      setContextFreeLocaleCode('en');
      await db
          .collection('plans')
          .doc('plan-1')
          .set(_planDoc(withTitle: false));

      await repoAs(_owner).reportCompletion('plan-1');

      final actions = await db.collection('actions').get();
      expect(actions.docs.single.data()['title'], 'Promise');
    });
  });
}
