import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/application/partner_link_binder.dart';
import 'package:nod_try/features/connect/presentation/connect_state.dart';
import 'package:nod_try/features/connect/presentation/viewmodel/connect_viewmodel.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/repositories/connect_repository.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/repositories/user_repository.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/utils/ui_error_codes.dart';

class _FakeConnectRepository extends Fake implements ConnectRepository {
  int connectWithCodeCalls = 0;
  final List<String> codes = [];
  Object? error;

  /// Holds `connectWithCode` open so a test can land a second submission while
  /// the first is still in flight.
  Completer<void>? gate;

  @override
  Future<String> connectWithCode(String code) async {
    connectWithCodeCalls++;
    codes.add(code);
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
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

class _FakeUserRepository extends Fake implements UserRepository {
  final Map<String, UserModel> byCode = {};
  final List<String> lookups = [];
  Object? error;

  @override
  Future<UserModel?> getUserByInviteCode(String code) async {
    lookups.add(code);
    if (error != null) throw error!;
    return byCode[code];
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

UserModel _owner() {
  final now = DateTime(2026, 5, 3);
  return UserModel(
    uid: 'partner-uid',
    displayName: '지민',
    inviteCode: 'K7MP2QXR',
    createdAt: now,
    updatedAt: now,
  );
}

ProviderContainer _container(
  _FakeConnectRepository connect,
  _FakeRecordRepository record, {
  _FakeUserRepository? users,
}) {
  return ProviderContainer(
    overrides: [
      connectRepositoryProvider.overrideWithValue(connect),
      recordRepositoryProvider.overrideWithValue(record),
      userRepositoryProvider.overrideWithValue(users ?? _FakeUserRepository()),
      myProfileProvider.overrideWithValue(AsyncData(_me())),
      connectionStatusStreamProvider.overrideWith(
        (ref) => const Stream<ConnectionStatus>.empty(),
      ),
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

  test('a typed code is normalized before connecting', () async {
    final connect = _FakeConnectRepository();
    final container = _container(connect, _FakeRecordRepository());
    addTearDown(container.dispose);
    await container.read(connectViewModelProvider.future);

    await container
        .read(connectViewModelProvider.notifier)
        .dispatch(const SubmitInviteCodeIntent(' k7mp-2qxr '));

    expect(connect.codes, ['K7MP2QXR']);
  });

  test('this device is marked as the invitee until the link lands', () async {
    final connect = _FakeConnectRepository()..gate = Completer<void>();
    final container = _container(connect, _FakeRecordRepository());
    addTearDown(container.dispose);
    await container.read(connectViewModelProvider.future);

    final pending = container
        .read(connectViewModelProvider.notifier)
        .dispatch(const SubmitInviteCodeIntent('K7MP2QXR'));
    // Set before the relation snapshot can arrive.
    expect(container.read(inviteeLinkPendingProvider), isTrue);
    connect.gate!.complete();
    await pending;
  });

  test('a failed link clears the invitee mark and says why', () async {
    final connect = _FakeConnectRepository()
      ..error = const InviteCodeNotFoundException();
    final container = _container(connect, _FakeRecordRepository());
    addTearDown(container.dispose);
    await container.read(connectViewModelProvider.future);

    await container
        .read(connectViewModelProvider.notifier)
        .dispatch(const SubmitInviteCodeIntent('K7MP2QXR'));

    expect(container.read(inviteeLinkPendingProvider), isFalse);
    final state = container.read(connectViewModelProvider).value!;
    expect(state.errorMessage, ConnectErrorCode.codeNotFound);
    expect(state.isProcessing, isFalse);
  });

  test('the server refusing the link says who already has a partner', () async {
    for (final (reason, errorCode) in [
      ('owner_taken', ConnectErrorCode.ownerTaken),
      ('self_taken', ConnectErrorCode.selfTaken),
    ]) {
      final connect = _FakeConnectRepository()
        ..error = InviteLinkRefusedException(reason);
      final record = _FakeRecordRepository();
      final container = _container(connect, record);
      addTearDown(container.dispose);
      await container.read(connectViewModelProvider.future);

      await container
          .read(connectViewModelProvider.notifier)
          .dispatch(const SubmitInviteCodeIntent('K7MP2QXR'));

      final state = container.read(connectViewModelProvider).value!;
      expect(state.errorMessage, errorCode, reason: reason);
      expect(state.isProcessing, isFalse);
      expect(container.read(inviteeLinkPendingProvider), isFalse);
      expect(record.assignManagerCalls, 0);
    }
  });

  group('lookupInviter', () {
    test('a code the server says is mine is the self-code error', () async {
      // e.g. my profile still shows a code the server has since rotated.
      final users = _FakeUserRepository()
        ..error = const InviteCodeIsMineException();
      final container = _container(
        _FakeConnectRepository(),
        _FakeRecordRepository(),
        users: users,
      );
      addTearDown(container.dispose);
      await container.read(connectViewModelProvider.future);

      final result = await container
          .read(connectViewModelProvider.notifier)
          .lookupInviter('ZZZZ2345');

      expect(
        (result as InviteLookupFailed).errorCode,
        ConnectErrorCode.selfCode,
      );
    });

    test('a failed lookup (offline, rate limit) is not "not found"', () async {
      final users = _FakeUserRepository()..error = Exception('unavailable');
      final container = _container(
        _FakeConnectRepository(),
        _FakeRecordRepository(),
        users: users,
      );
      addTearDown(container.dispose);
      await container.read(connectViewModelProvider.future);

      final result = await container
          .read(connectViewModelProvider.notifier)
          .lookupInviter('ZZZZ2345');

      expect(
        (result as InviteLookupFailed).errorCode,
        ConnectErrorCode.connectFailed,
      );
    });

    test('finds the owner of a typed code', () async {
      final users = _FakeUserRepository()..byCode['K7MP2QXR'] = _owner();
      final container = _container(
        _FakeConnectRepository(),
        _FakeRecordRepository(),
        users: users,
      );
      addTearDown(container.dispose);
      await container.read(connectViewModelProvider.future);

      final result = await container
          .read(connectViewModelProvider.notifier)
          .lookupInviter('k7mp 2qxr');

      expect(result, isA<InviteLookupFound>());
      final found = result as InviteLookupFound;
      expect(found.code, 'K7MP2QXR');
      expect(found.owner.displayName, '지민');
      expect(users.lookups, ['K7MP2QXR']);
      expect(
        container.read(connectViewModelProvider).value!.errorMessage,
        isNull,
      );
    });

    test('rejects a malformed code without a lookup', () async {
      final users = _FakeUserRepository();
      final container = _container(
        _FakeConnectRepository(),
        _FakeRecordRepository(),
        users: users,
      );
      addTearDown(container.dispose);
      await container.read(connectViewModelProvider.future);

      final result = await container
          .read(connectViewModelProvider.notifier)
          .lookupInviter('ABC12');

      expect(result, isA<InviteLookupFailed>());
      expect(users.lookups, isEmpty);
      expect(
        container.read(connectViewModelProvider).value!.errorMessage,
        ConnectErrorCode.codeFormat,
      );
    });

    test('my own code and an unknown code are errors', () async {
      final users = _FakeUserRepository();
      final container = _container(
        _FakeConnectRepository(),
        _FakeRecordRepository(),
        users: users,
      );
      addTearDown(container.dispose);
      await container.read(connectViewModelProvider.future);
      final notifier = container.read(connectViewModelProvider.notifier);

      final mine = await notifier.lookupInviter('mycode12');
      expect((mine as InviteLookupFailed).errorCode, ConnectErrorCode.selfCode);
      expect(users.lookups, isEmpty);

      final unknown = await notifier.lookupInviter('ZZZZ2345');
      expect(
        (unknown as InviteLookupFailed).errorCode,
        ConnectErrorCode.codeNotFound,
      );
    });
  });
}
