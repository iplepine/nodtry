import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/presentation/connect_state.dart';
import 'package:nod_try/features/connect/presentation/viewmodel/connect_viewmodel.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/repositories/connect_repository.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/providers/repository_provider.dart';

class _FakeConnectRepository extends Fake implements ConnectRepository {
  int connectWithCodeCalls = 0;

  /// Holds `connectWithCode` open so a test can land a second submission while
  /// the first is still in flight.
  Completer<void>? gate;

  @override
  Future<String> connectWithCode(String code) async {
    connectWithCodeCalls++;
    if (gate != null) await gate!.future;
    return 'partner-uid';
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() =>
      const Stream<ConnectionStatus>.empty();
}

class _FakeRecordRepository extends Fake implements RecordRepository {
  int assignManagerCalls = 0;

  @override
  Future<void> assignManagerToActivePlans(String managerId) async {
    assignManagerCalls++;
  }
}

UserModel _me() {
  final now = DateTime(2026, 5, 3);
  return UserModel(
    uid: 'me',
    inviteCode: 'MYCODE12',
    createdAt: now,
    updatedAt: now,
  );
}

ProviderContainer _container(
  _FakeConnectRepository connect,
  _FakeRecordRepository record,
) {
  return ProviderContainer(
    overrides: [
      connectRepositoryProvider.overrideWithValue(connect),
      recordRepositoryProvider.overrideWithValue(record),
      myProfileProvider.overrideWithValue(AsyncData(_me())),
    ],
  );
}

void main() {
  test(
    'a second submission while the first is in flight connects once',
    () async {
      final connect = _FakeConnectRepository()..gate = Completer<void>();
      final record = _FakeRecordRepository();
      final container = _container(connect, record);
      addTearDown(container.dispose);
      await container.read(connectViewModelProvider.future);

      final notifier = container.read(connectViewModelProvider.notifier);

      // Typing the 8th character auto-submits, and the send button stays enabled
      // while the screen awaits the partner list — both can land.
      final first = notifier.dispatch(const SubmitInviteCodeIntent('PARTNER1'));
      final second = notifier.dispatch(
        const SubmitInviteCodeIntent('PARTNER1'),
      );
      connect.gate!.complete();
      await Future.wait([first, second]);

      // Regression: connectWithCode batch-writes two relation docs per call with
      // no duplicate check, so two calls left four relation records for one
      // partner.
      expect(connect.connectWithCodeCalls, 1);
      expect(record.assignManagerCalls, 1);
    },
  );

  test('a later submission still works once the first has finished', () async {
    final connect = _FakeConnectRepository();
    final record = _FakeRecordRepository();
    final container = _container(connect, record);
    addTearDown(container.dispose);
    await container.read(connectViewModelProvider.future);

    final notifier = container.read(connectViewModelProvider.notifier);
    await notifier.dispatch(const SubmitInviteCodeIntent('PARTNER1'));
    expect(connect.connectWithCodeCalls, 1);

    // The guard must clear, otherwise a failed first attempt would lock the
    // user out of retrying.
    await notifier.dispatch(const SubmitInviteCodeIntent('PARTNER2'));
    expect(connect.connectWithCodeCalls, 2);
  });

  test('own invite code is rejected without touching the repository', () async {
    final connect = _FakeConnectRepository();
    final record = _FakeRecordRepository();
    final container = _container(connect, record);
    addTearDown(container.dispose);
    await container.read(connectViewModelProvider.future);

    await container
        .read(connectViewModelProvider.notifier)
        .dispatch(const SubmitInviteCodeIntent('MYCODE12'));

    expect(connect.connectWithCodeCalls, 0);
    expect(
      container.read(connectViewModelProvider).value!.errorMessage,
      isNotNull,
    );
  });
}
