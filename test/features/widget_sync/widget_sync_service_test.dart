import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/widget_sync/application/widget_sync_service.dart';
import 'package:nod_try/features/widget_sync/domain/duo_widget_snapshot.dart';

class FakeStore implements DuoWidgetStore {
  final writes = <String?>[];
  int reloads = 0;
  bool fail = false;

  @override
  Future<void> write(String? json) async {
    if (fail) throw StateError('no plugin');
    writes.add(json);
  }

  @override
  Future<void> reloadWidgets() async => reloads++;
}

DuoWidgetSnapshot snap(int streak) => DuoWidgetSnapshot(
  date: '2026-09-30',
  streak: streak,
  headline: '둘이 함께 $streak일째',
  duoDoneToday: false,
  badge: null,
  me: const DuoWidgetPerson(
    name: '나',
    status: DuoWidgetPersonStatus.done,
    statusText: '완료',
  ),
  partner: const DuoWidgetPerson(
    name: '자기',
    status: DuoWidgetPersonStatus.pending,
    statusText: '아직',
  ),
  staleText: '앱에서 오늘을 확인해요',
  locale: 'ko',
);

int streakOf(String? json) =>
    (jsonDecode(json!) as Map<String, dynamic>)['streak'] as int;

/// Wall clock for the service, advanced together with the fake timers.
class _Clock {
  DateTime _now = DateTime(2026, 9, 30, 12);
  DateTime now() => _now;

  Future<void> elapse(WidgetTester tester, Duration d) async {
    _now = _now.add(d);
    await tester.pump(d);
  }
}

void main() {
  testWidgets('first push writes right away and reloads the widgets', (
    tester,
  ) async {
    final clock = _Clock();
    final store = FakeStore();
    final service = WidgetSyncService(store, clock: clock.now);
    service.push(snap(1));
    await tester.pump();
    expect(store.writes, hasLength(1));
    expect(streakOf(store.writes.single), 1);
    expect(store.reloads, 1);
  });

  testWidgets('an identical snapshot is not written again', (tester) async {
    final clock = _Clock();
    final store = FakeStore();
    final service = WidgetSyncService(store, clock: clock.now);
    service.push(snap(1));
    await clock.elapse(tester, const Duration(seconds: 5));
    service.push(snap(1));
    await clock.elapse(tester, const Duration(seconds: 5));
    expect(store.writes, hasLength(1));
  });

  testWidgets('force rewrites an identical snapshot', (tester) async {
    final clock = _Clock();
    final store = FakeStore();
    final service = WidgetSyncService(store, clock: clock.now);
    service.push(snap(1));
    await clock.elapse(tester, const Duration(seconds: 5));
    service.push(snap(1), force: true);
    await clock.elapse(tester, const Duration(seconds: 5));
    expect(store.writes, hasLength(2));
  });

  testWidgets('a burst of changes is coalesced into the latest one', (
    tester,
  ) async {
    final clock = _Clock();
    final store = FakeStore();
    final service = WidgetSyncService(store, clock: clock.now);
    service.push(snap(1));
    await tester.pump();
    service.push(snap(2));
    service.push(snap(3));
    service.push(snap(4));
    await clock.elapse(tester, const Duration(milliseconds: 500));
    expect(store.writes, hasLength(1), reason: 'throttled');
    await clock.elapse(tester, const Duration(seconds: 1));
    expect(store.writes.map(streakOf), [1, 4]);
  });

  testWidgets(
    'a change back to what is stored while throttled writes nothing',
    (tester) async {
      final clock = _Clock();
      final store = FakeStore();
      final service = WidgetSyncService(store, clock: clock.now);
      service.push(snap(1));
      await tester.pump();
      service.push(snap(2));
      service.push(snap(1));
      await clock.elapse(tester, const Duration(seconds: 2));
      expect(store.writes.map(streakOf), [1]);
    },
  );

  testWidgets('clear removes the data once; repeated clears are skipped', (
    tester,
  ) async {
    final clock = _Clock();
    final store = FakeStore();
    final service = WidgetSyncService(store, clock: clock.now);
    service.push(snap(1));
    await clock.elapse(tester, const Duration(seconds: 2));
    service.clear();
    await clock.elapse(tester, const Duration(seconds: 2));
    service.clear();
    service.push(null);
    await clock.elapse(tester, const Duration(seconds: 2));
    expect(store.writes, hasLength(2));
    expect(store.writes.last, isNull);
  });

  testWidgets('the first clear of a run always reaches storage', (
    tester,
  ) async {
    final clock = _Clock();
    final store = FakeStore();
    final service = WidgetSyncService(store, clock: clock.now);
    service.clear();
    await tester.pump();
    expect(store.writes, [null]);
  });

  testWidgets('a failed write is retried on the next push and never throws', (
    tester,
  ) async {
    final clock = _Clock();
    final store = FakeStore()..fail = true;
    final service = WidgetSyncService(store, clock: clock.now);
    service.push(snap(1));
    await clock.elapse(tester, const Duration(seconds: 2));
    expect(store.writes, isEmpty);
    store.fail = false;
    service.push(snap(1));
    await clock.elapse(tester, const Duration(seconds: 2));
    expect(store.writes, hasLength(1));
  });

  testWidgets('nothing is written after dispose', (tester) async {
    final clock = _Clock();
    final store = FakeStore();
    final service = WidgetSyncService(store, clock: clock.now);
    service.push(snap(1));
    await tester.pump();
    service.push(snap(2));
    service.dispose();
    await clock.elapse(tester, const Duration(seconds: 2));
    service.push(snap(3));
    await clock.elapse(tester, const Duration(seconds: 2));
    expect(store.writes.map(streakOf), [1]);
  });
}
