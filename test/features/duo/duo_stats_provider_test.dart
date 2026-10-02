import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';

class _Records extends Fake implements RecordRepository {
  final streams = <String, StreamController<List<Plan>>>{};

  StreamController<List<Plan>> of(String uid) =>
      streams.putIfAbsent(uid, StreamController<List<Plan>>.broadcast);

  @override
  Stream<List<Plan>> getAllPlansByUserIdStream(String userId) =>
      of(userId).stream;
}

UserModel _user(String uid) {
  final now = DateTime(2026, 9, 1);
  return UserModel(uid: uid, displayName: uid, createdAt: now, updatedAt: now);
}

Plan _plan(String userId, List<int> days, List<DateTime> done) => Plan(
  id: '$userId-plan',
  userId: userId,
  managerId: userId == 'me' ? 'partner' : 'me',
  startDate: DateTime(2026, 9, 28),
  endDate: DateTime(2026, 10, 25, 23, 59, 59),
  state: PlanState.active,
  items: [PlanItem(title: '운동', days: days, count: days.length)],
  createdAt: DateTime(2026, 9, 28),
  completedDates: done,
);

void main() {
  test('combines my plans and my partner\'s into the stats', () async {
    final records = _Records();
    final container = ProviderContainer(
      overrides: [
        recordRepositoryProvider.overrideWithValue(records),
        myProfileProvider.overrideWith((ref) => Stream.value(_user('me'))),
        connectedProfilesProvider.overrideWith(
          (ref) async => [
            ConnectedUser(
              user: _user('partner'),
              isSupported: true,
              isCheering: true,
            ),
          ],
        ),
        duoClockProvider.overrideWithValue(() => DateTime(2026, 10, 2, 21)),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(duoStatsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(myProfileProvider.future);
    await container.read(connectedProfilesProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(duoStatsProvider), isNull); // plans not loaded

    records.of('me').add([
      _plan(
        'me',
        [1, 3, 5],
        [
          DateTime(2026, 9, 28, 19),
          DateTime(2026, 9, 30, 19),
          DateTime(2026, 10, 2, 19),
        ],
      ),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(duoStatsProvider), isNull); // partner still loading

    records.of('partner').add([
      _plan(
        'partner',
        [2, 4],
        [DateTime(2026, 9, 29, 7), DateTime(2026, 10, 1, 7)],
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    final stats = container.read(duoStatsProvider)!;
    expect(stats.hasPartner, isTrue);
    expect(stats.streak, 5);
    expect(stats.todayIsDuoDone, isTrue);
  });

  test('a solo user gets stats of their own', () async {
    final records = _Records();
    final container = ProviderContainer(
      overrides: [
        recordRepositoryProvider.overrideWithValue(records),
        myProfileProvider.overrideWith((ref) => Stream.value(_user('me'))),
        connectedProfilesProvider.overrideWith((ref) async => const []),
        duoClockProvider.overrideWithValue(() => DateTime(2026, 10, 2, 21)),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(duoStatsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(myProfileProvider.future);
    await container.read(connectedProfilesProvider.future);
    await Future<void>.delayed(Duration.zero);

    records.of('me').add([
      _plan('me', [5], [DateTime(2026, 10, 2, 19)]),
    ]);
    await Future<void>.delayed(Duration.zero);

    final stats = container.read(duoStatsProvider)!;
    expect(stats.hasPartner, isFalse);
    expect(stats.streak, 1);
  });

  test('days before the couple linked do not count', () async {
    final records = _Records();
    final container = ProviderContainer(
      overrides: [
        recordRepositoryProvider.overrideWithValue(records),
        myProfileProvider.overrideWith((ref) => Stream.value(_user('me'))),
        connectedProfilesProvider.overrideWith(
          (ref) async => [
            ConnectedUser(
              user: _user('partner'),
              isSupported: true,
              isCheering: true,
              linkedAt: DateTime(2026, 10, 2, 8),
            ),
          ],
        ),
        duoClockProvider.overrideWithValue(() => DateTime(2026, 10, 2, 9)),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(duoStatsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(myProfileProvider.future);
    await container.read(connectedProfilesProvider.future);
    await Future<void>.delayed(Duration.zero);

    // Mon/Wed done alone before the link; the partner has no plans.
    records.of('me').add([
      _plan(
        'me',
        [1, 3, 5],
        [DateTime(2026, 9, 28, 19), DateTime(2026, 9, 30, 19)],
      ),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(duoStatsProvider), isNull); // partner still loading
    records.of('partner').add(const []);
    await Future<void>.delayed(Duration.zero);

    final stats = container.read(duoStatsProvider)!;
    expect(stats.hasPartner, isTrue);
    expect(stats.streak, 0);
  });

  test('"today" moves on after midnight without a plan change', () async {
    var now = DateTime(2026, 10, 2, 21);
    final records = _Records();
    final container = ProviderContainer(
      overrides: [
        recordRepositoryProvider.overrideWithValue(records),
        myProfileProvider.overrideWith((ref) => Stream.value(_user('me'))),
        connectedProfilesProvider.overrideWith((ref) async => const []),
        duoClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(duoStatsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(myProfileProvider.future);
    await container.read(connectedProfilesProvider.future);
    await Future<void>.delayed(Duration.zero);
    records.of('me').add([
      _plan('me', [5, 6], [DateTime(2026, 10, 2, 19)]),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(duoStatsProvider)!.today.date, DateTime(2026, 10, 2));

    // The app resumes the next morning; the plan stream stays quiet.
    now = DateTime(2026, 10, 3, 8);
    container.read(duoTodayProvider.notifier).refresh();
    await Future<void>.delayed(Duration.zero);

    final stats = container.read(duoStatsProvider)!;
    expect(stats.today.date, DateTime(2026, 10, 3));
    expect(stats.todayIsDuoDone, isFalse);
  });
}
