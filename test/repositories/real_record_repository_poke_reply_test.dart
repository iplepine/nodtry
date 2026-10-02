import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/repositories/mock_record_repository.dart';
import 'package:nod_try/repositories/real_record_repository.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(String? uid) : currentUser = uid == null ? null : _FakeUser(uid);

  @override
  final User? currentUser;
}

const _owner = 'owner-uid';
const _manager = 'manager-uid';

Map<String, dynamic> _planDoc() {
  final now = DateTime.now();
  return {
    'userId': _owner,
    'managerId': _manager,
    'state': 'active',
    'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'endDate': Timestamp.fromDate(now.add(const Duration(days: 20))),
    'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
    'items': [
      {
        'title': '헬스장 가기',
        'days': [1, 2, 3, 4, 5, 6, 7],
        'count': 7,
      },
    ],
    'completedDates': <Timestamp>[],
    'verifiedDates': <Timestamp>[],
    'lastPokeAt': Timestamp.fromDate(now),
    'lastPokeMessage': '똑똑! 오늘 약속 기다리고 있어',
  };
}

void main() {
  late FakeFirebaseFirestore db;

  RealRecordRepository repoAs(String? uid) =>
      RealRecordRepository(firestore: db, auth: _FakeAuth(uid));

  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.collection('plans').doc('plan-1').set(_planDoc());
  });

  group('replyToPoke', () {
    test(
      'writes one cheers doc with reactionType reply and the text',
      () async {
        await repoAs(
          _owner,
        ).replyToPoke('plan-1', toUserId: _manager, message: '지금 간다 🏃');

        final cheers = await db.collection('cheers').get();
        expect(cheers.docs, hasLength(1));
        final doc = cheers.docs.single.data();
        expect(doc['fromUserId'], _owner);
        expect(doc['toUserId'], _manager);
        expect(doc['planId'], 'plan-1');
        expect(doc['reactionType'], 'reply');
        expect(doc['reactionType'], kPokeReplyReactionType);
        expect(doc['message'], '지금 간다 🏃');
        expect(doc['createdAt'], isNotNull);
      },
    );

    test('touches nothing on the plan (the knock stays as it was)', () async {
      final before = (await db.collection('plans').doc('plan-1').get()).data();

      await repoAs(
        _owner,
      ).replyToPoke('plan-1', toUserId: _manager, message: '오늘은 봐줘 🙏');

      final after = (await db.collection('plans').doc('plan-1').get()).data();
      expect(after, before);
      expect(await db.collection('actions').get().then((s) => s.docs), isEmpty);
    });

    test('signed out: nothing is written', () async {
      await expectLater(
        repoAs(null).replyToPoke('plan-1', toUserId: _manager, message: 'x'),
        throwsException,
      );
      expect((await db.collection('cheers').get()).docs, isEmpty);
    });
  });

  group('sendCheer', () {
    test('writes an emoji cheer and never marks the day 인정', () async {
      await repoAs(_manager).sendCheer(
        _owner,
        planId: 'plan-1',
        emoji: '💪',
        message: '할 수 있어! 기다릴게 💪',
      );

      final doc = (await db.collection('cheers').get()).docs.single.data();
      expect(doc['fromUserId'], _manager);
      expect(doc['toUserId'], _owner);
      expect(doc['planId'], 'plan-1');
      expect(doc['reactionType'], '💪');
      expect(doc['message'], '할 수 있어! 기다릴게 💪');

      final plan = (await db.collection('plans').doc('plan-1').get()).data()!;
      expect(plan['verifiedDates'], isEmpty);
      expect(plan.containsKey('lastUpdatedBy'), isFalse);
    });

    test(
      'without a plan or message only the required fields are written',
      () async {
        await repoAs(_manager).sendCheer(_owner, emoji: '❤️');

        final doc = (await db.collection('cheers').get()).docs.single.data();
        expect(doc.containsKey('planId'), isFalse);
        expect(doc.containsKey('message'), isFalse);
        expect(doc['reactionType'], '❤️');
      },
    );
  });

  test('the mock repository records replies and cheers too', () async {
    final mock = MockRecordRepository();
    await mock.replyToPoke('p', toUserId: 'u', message: '지금 간다 🏃');
    await mock.sendCheer('u', planId: 'p', emoji: '💪', message: 'go');
    expect(mock.sentCheers.map((c) => c['reactionType']), ['reply', '💪']);
    expect(mock.sentCheers.first['message'], '지금 간다 🏃');
  });
}
