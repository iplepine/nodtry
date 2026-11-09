import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/domain/duo_stats.dart';
import 'package:nod_try/features/widget_sync/domain/duo_widget_snapshot.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';

// 2026-09-28 is a Monday.
DateTime d(int month, int day, [int hour = 0]) =>
    DateTime(2026, month, day, hour);

final mon = d(9, 28);
final tue = d(9, 29);
final wed = d(9, 30);

Plan plan({
  String id = 'p',
  String userId = 'a',
  String? managerId = 'b',
  List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  List<DateTime> completed = const [],
  List<DateTime> rested = const [],
  String? lastProofPhotoPath,
  DateTime? lastProofAt,
}) {
  final s = d(9, 1);
  return Plan(
    id: id,
    userId: userId,
    managerId: managerId,
    startDate: s,
    endDate: DateTime(2026, 11, 30, 23, 59, 59),
    state: PlanState.active,
    items: [PlanItem(title: '운동', days: days, count: days.length)],
    createdAt: s,
    completedDates: [
      for (final x in completed) x.add(const Duration(hours: 19)),
    ],
    restedDates: [for (final x in rested) x.add(const Duration(hours: 20))],
    lastProofPhotoPath: lastProofPhotoPath,
    lastProofAt: lastProofAt,
  );
}

final ko = lookupAppLocalizations(const Locale('ko'));
final en = lookupAppLocalizations(const Locale('en'));

DuoWidgetSnapshot? build({
  required List<Plan> mine,
  required List<Plan> theirs,
  required DateTime today,
  AppLocalizations? l10n,
  String partnerName = '자기',
  bool hasPartner = true,
}) {
  final stats = computeDuoStats(
    myPlans: mine,
    partnerPlans: theirs,
    today: today,
    hasPartner: hasPartner,
    linkedSince: d(9, 1),
  );
  return buildDuoWidgetSnapshot(
    stats: stats,
    myPlans: mine,
    partnerPlans: theirs,
    partnerName: partnerName,
    l10n: l10n ?? ko,
  );
}

void main() {
  test('date key is zero padded yyyy-MM-dd', () {
    expect(duoWidgetDateKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    expect(duoWidgetDateKey(DateTime(2026, 12, 25)), '2026-12-25');
  });

  test('no stats or no partner: nothing to show', () {
    expect(
      buildDuoWidgetSnapshot(
        stats: null,
        myPlans: const [],
        partnerPlans: const [],
        partnerName: '짝꿍',
        l10n: ko,
      ),
      isNull,
    );
    expect(
      build(
        mine: [
          plan(completed: [mon]),
        ],
        theirs: const [],
        today: mon,
        hasPartner: false,
      ),
      isNull,
    );
  });

  test('streak and both done → duo badge, ko copy', () {
    final mine = [
      plan(id: 'a1', completed: [mon, tue, wed]),
    ];
    final theirs = [
      plan(id: 'b1', userId: 'b', managerId: 'a', completed: [mon, tue, wed]),
    ];
    final s = build(mine: mine, theirs: theirs, today: wed)!;
    expect(s.streak, 3);
    expect(s.headline, '둘이 함께 3일째');
    expect(s.duoDoneToday, isTrue);
    expect(s.badge, '오늘 둘운완이에요 🎉');
    expect(s.me.name, '나');
    expect(s.me.status, DuoWidgetPersonStatus.done);
    expect(s.me.statusText, '완료');
    expect(s.partner.name, '자기');
    expect(s.partner.status, DuoWidgetPersonStatus.done);
    expect(s.date, '2026-09-30');
    expect(s.locale, 'ko');
  });

  test('pending partner keeps the streak and shows 아직', () {
    final mine = [
      plan(id: 'a1', completed: [mon, tue]),
    ];
    final theirs = [
      plan(id: 'b1', userId: 'b', managerId: 'a', completed: [mon]),
    ];
    final s = build(mine: mine, theirs: theirs, today: tue)!;
    expect(s.streak, 1);
    expect(s.duoDoneToday, isFalse);
    expect(s.badge, isNull);
    expect(s.me.status, DuoWidgetPersonStatus.done);
    expect(s.partner.status, DuoWidgetPersonStatus.pending);
    expect(s.partner.statusText, '아직');
  });

  test('streak 0 uses the start line', () {
    final s = build(
      mine: [plan(id: 'a1')],
      theirs: [plan(id: 'b1', userId: 'b', managerId: 'a')],
      today: mon,
    )!;
    expect(s.streak, 0);
    expect(s.headline, '오늘 둘 다 하면 1일째');
  });

  test('proof photo today → done_proof; an older proof does not count', () {
    final mine = [
      plan(
        id: 'a1',
        completed: [tue],
        lastProofPhotoPath: 'proofs/a/a1/x.jpg',
        lastProofAt: tue.add(const Duration(hours: 19)),
      ),
    ];
    final theirs = [
      plan(
        id: 'b1',
        userId: 'b',
        managerId: 'a',
        completed: [mon, tue],
        lastProofPhotoPath: 'proofs/b/b1/y.jpg',
        lastProofAt: mon.add(const Duration(hours: 19)),
      ),
    ];
    final s = build(mine: mine, theirs: theirs, today: tue)!;
    expect(s.me.status, DuoWidgetPersonStatus.doneWithProof);
    expect(s.me.statusText, '인증샷 📸');
    expect(s.partner.status, DuoWidgetPersonStatus.done);
  });

  test('rest pass and unscheduled day', () {
    final mine = [
      plan(id: 'a1', days: [2], rested: [tue]),
    ];
    final theirs = [
      plan(id: 'b1', userId: 'b', managerId: 'a', days: [1]),
    ];
    final s = build(mine: mine, theirs: theirs, today: tue)!;
    expect(s.me.status, DuoWidgetPersonStatus.rested);
    expect(s.me.statusText, '휴식권');
    expect(s.partner.status, DuoWidgetPersonStatus.notScheduled);
    expect(s.partner.statusText, '쉬는 날');
  });

  test('en copy and JSON shape', () {
    final mine = [
      plan(id: 'a1', completed: [mon, tue]),
    ];
    final theirs = [
      plan(id: 'b1', userId: 'b', managerId: 'a', completed: [mon, tue]),
    ];
    final s = build(
      mine: mine,
      theirs: theirs,
      today: tue,
      l10n: en,
      partnerName: 'your partner',
    )!;
    expect(s.headline, 'Together 2 days');
    expect(s.badge, 'Both done today 🎉');
    expect(s.me.name, 'Me');
    expect(s.me.statusText, 'Done');
    expect(s.locale, 'en');

    final json =
        jsonDecode(s.encode(updatedAt: DateTime.utc(2026, 9, 29, 12)))
            as Map<String, dynamic>;
    expect(json['v'], kDuoWidgetSnapshotVersion);
    expect(json['date'], '2026-09-29');
    expect(json['streak'], 2);
    expect(json['duoDone'], true);
    expect(json['me'], {'name': 'Me', 'status': 'done', 'text': 'Done'});
    expect((json['partner'] as Map)['name'], 'your partner');
    expect(json['stale'], 'Open to see today');
    expect(json['updatedAt'], isA<int>());
    // Privacy: nothing but names, statuses and copy.
    expect(json.keys.toSet(), {
      'v',
      'date',
      'streak',
      'headline',
      'duoDone',
      'badge',
      'me',
      'partner',
      'stale',
      'locale',
      'updatedAt',
    });
  });

  test('equality ignores updatedAt', () {
    final mine = [
      plan(id: 'a1', completed: [mon]),
    ];
    final theirs = [plan(id: 'b1', userId: 'b', managerId: 'a')];
    final a = build(mine: mine, theirs: theirs, today: mon)!;
    final b = build(mine: mine, theirs: theirs, today: mon)!;
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('ko copy never uses 님 after the partner name', () {
    for (final text in [
      ko.homeWidgetStreak(5),
      ko.homeWidgetStreakZero,
      ko.homeWidgetTodayDuoDone,
      ko.homeWidgetStale,
    ]) {
      expect(text.contains('님'), isFalse, reason: text);
      expect(text.contains('애인'), isFalse, reason: text);
    }
    expect(en.homeWidgetStreak(1), 'Together 1 day');
  });
}
