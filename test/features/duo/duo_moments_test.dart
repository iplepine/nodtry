import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/application/duo_moments.dart';
import 'package:nod_try/features/duo/application/review_prompt.dart';
import 'package:nod_try/features/duo/domain/duo_stats.dart';
import 'package:nod_try/features/duo/presentation/duo_share_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 10, 2); // a Friday

DuoDay _day(DuoDayStatus me, DuoDayStatus partner, DateTime date) => DuoDay(
  date: date,
  me: DuoPersonDay(status: me),
  partner: DuoPersonDay(status: partner),
  isToday: date == _today,
);

DuoStats _stats({
  required bool duoToday,
  int streak = 1,
  bool hasPartner = true,
}) {
  final today = _day(
    DuoDayStatus.done,
    duoToday ? DuoDayStatus.off : DuoDayStatus.pending,
    _today,
  );
  return DuoStats(
    streak: streak,
    streakStart: streak > 0
        ? DateTime(_today.year, _today.month, _today.day - streak + 1)
        : null,
    today: today,
    week: [
      for (var i = 0; i < 7; i++)
        i == 4
            ? today
            : _day(
                DuoDayStatus.off,
                DuoDayStatus.off,
                DateTime(2026, 9, 28 + i),
              ),
    ],
    hasPartner: hasPartner,
  );
}

class _Requester implements ReviewRequester {
  _Requester({this.available = true});

  final bool available;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requests++;
}

void main() {
  group('decideDuoShareOffer', () {
    test('nothing until today is a duo day', () {
      expect(
        decideDuoShareOffer(
          stats: _stats(duoToday: false),
          offeredDay: null,
          offeredMilestones: const {},
        ),
        isNull,
      );
    });

    test('nothing without a partner', () {
      expect(
        decideDuoShareOffer(
          stats: _stats(duoToday: true, hasPartner: false),
          offeredDay: null,
          offeredMilestones: const {},
        ),
        isNull,
      );
    });

    test('a duo day offers the card once that day', () {
      final offer = decideDuoShareOffer(
        stats: _stats(duoToday: true, streak: 2),
        offeredDay: null,
        offeredMilestones: const {},
      );
      expect(offer!.trigger, DuoShareTrigger.today);
      expect(offer.milestoneKey, isNull);

      expect(
        decideDuoShareOffer(
          stats: _stats(duoToday: true, streak: 2),
          offeredDay: duoDayKey(_today),
          offeredMilestones: const {},
        ),
        isNull,
      );
    });

    for (final milestone in kDuoShareMilestones) {
      test('streak $milestone is a milestone, once per run', () {
        final stats = _stats(duoToday: true, streak: milestone);
        final offer = decideDuoShareOffer(
          stats: stats,
          offeredDay: null,
          offeredMilestones: const {},
        );
        expect(offer!.trigger, DuoShareTrigger.milestone);
        expect(
          offer.milestoneKey,
          '$milestone@${duoDayKey(stats.streakStart!)}',
        );

        // Already celebrated for this run: nothing more by itself.
        final again = decideDuoShareOffer(
          stats: stats,
          offeredDay: '2026-09-30',
          offeredMilestones: {offer.milestoneKey!},
        );
        expect(again, isNull);
      });
    }

    test('the milestones are 3, 7, 14, 21, 30, 50 and 100', () {
      expect(kDuoShareMilestones, [3, 7, 14, 21, 30, 50, 100]);
    });

    test('the first duo day ever is offered as a plain duo day', () {
      for (final streak in [1, 2, 4, 6, 8, 29, 31]) {
        expect(
          decideDuoShareOffer(
            stats: _stats(duoToday: true, streak: streak),
            offeredDay: null,
            offeredMilestones: const {},
          )!.trigger,
          DuoShareTrigger.today,
          reason: '$streak',
        );
      }
    });

    test('after that, an ordinary duo day offers nothing', () {
      for (final streak in [1, 2, 4, 6, 8, 29, 31]) {
        expect(
          decideDuoShareOffer(
            stats: _stats(duoToday: true, streak: streak),
            offeredDay: '2026-09-30',
            offeredMilestones: const {},
          ),
          isNull,
          reason: '$streak',
        );
      }
    });
  });

  group('DuoMomentsStore', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('remembers the offered day and milestones', () async {
      final store = DuoMomentsStore(prefs);
      expect(store.shareOfferedDay, isNull);
      await store.markOffered('2026-10-02', milestoneKey: '3@2026-09-30');
      expect(store.shareOfferedDay, '2026-10-02');
      expect(store.milestonesOffered, {'3@2026-09-30'});
      await store.markOffered('2026-10-03');
      expect(store.milestonesOffered, {'3@2026-09-30'});
    });

    test('duo_done_day is logged once per day, only on a duo day', () async {
      final store = DuoMomentsStore(prefs);
      expect(await logDuoDoneDayOnce(_stats(duoToday: false), store), isFalse);
      expect(await logDuoDoneDayOnce(_stats(duoToday: true), store), isTrue);
      expect(await logDuoDoneDayOnce(_stats(duoToday: true), store), isFalse);
      expect(store.doneDayLogged, duoDayKey(_today));
    });
  });

  group('review prompt', () {
    test('dueReviewTrigger: first duo day, then the 3rd 인정', () {
      expect(
        dueReviewTrigger(
          hadDuoDay: false,
          propsReceived: 2,
          promptsShown: 0,
          fired: const {},
        ),
        isNull,
      );
      expect(
        dueReviewTrigger(
          hadDuoDay: true,
          propsReceived: 0,
          promptsShown: 0,
          fired: const {},
        ),
        ReviewTrigger.firstDuoDay,
      );
      expect(
        dueReviewTrigger(
          hadDuoDay: true,
          propsReceived: 3,
          promptsShown: 1,
          fired: {ReviewTrigger.firstDuoDay.id},
        ),
        ReviewTrigger.thirdProps,
      );
      expect(
        dueReviewTrigger(
          hadDuoDay: false,
          propsReceived: 3,
          promptsShown: 0,
          fired: const {},
        ),
        ReviewTrigger.thirdProps,
      );
    });

    test('never more than 3 asks in total', () {
      expect(kMaxReviewPrompts, 3);
      expect(
        dueReviewTrigger(
          hadDuoDay: true,
          propsReceived: 10,
          promptsShown: 3,
          fired: const {},
        ),
        isNull,
      );
    });

    test('each trigger asks once and the count is kept', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReviewPromptStore(await SharedPreferences.getInstance());
      final requester = _Requester();

      expect(
        await maybeRequestReview(
          store: store,
          requester: requester,
          hadDuoDay: true,
          propsReceived: 0,
        ),
        ReviewTrigger.firstDuoDay,
      );
      expect(
        await maybeRequestReview(
          store: store,
          requester: requester,
          hadDuoDay: true,
          propsReceived: 1,
        ),
        isNull,
      );
      expect(
        await maybeRequestReview(
          store: store,
          requester: requester,
          hadDuoDay: true,
          propsReceived: 3,
        ),
        ReviewTrigger.thirdProps,
      );
      expect(
        await maybeRequestReview(
          store: store,
          requester: requester,
          hadDuoDay: true,
          propsReceived: 30,
        ),
        isNull,
      );
      await Future<void>.delayed(Duration.zero);
      expect(requester.requests, 2);
      expect(store.promptsShown, 2);
    });

    test('stops at the cap even with fresh triggers', () async {
      SharedPreferences.setMockInitialValues({ReviewPromptPrefKeys.count: 3});
      final store = ReviewPromptStore(await SharedPreferences.getInstance());
      final requester = _Requester();
      expect(
        await maybeRequestReview(
          store: store,
          requester: requester,
          hadDuoDay: true,
          propsReceived: 3,
        ),
        isNull,
      );
      expect(requester.requests, 0);
    });

    test('unavailable: nothing is counted, it can ask another day', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReviewPromptStore(await SharedPreferences.getInstance());
      expect(
        await maybeRequestReview(
          store: store,
          requester: _Requester(available: false),
          hadDuoDay: true,
          propsReceived: 0,
        ),
        isNull,
      );
      expect(store.promptsShown, 0);
      expect(store.fired, isEmpty);
    });

    test('a failing request never throws', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReviewPromptStore(await SharedPreferences.getInstance());
      final result = await maybeRequestReview(
        store: store,
        requester: _ThrowingRequester(),
        hadDuoDay: true,
        propsReceived: 0,
      );
      expect(result, ReviewTrigger.firstDuoDay);
      await Future<void>.delayed(Duration.zero);
    });
  });
}

class _ThrowingRequester implements ReviewRequester {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => throw Exception('no store');
}
