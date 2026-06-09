import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../connect_state.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../repositories/connect_repository.dart';
import '../../../../utils/error_reporter.dart';
import '../../../../utils/ui_error_codes.dart';

final connectViewModelProvider =
    AsyncNotifierProvider<ConnectViewModel, ConnectState>(ConnectViewModel.new);

class ConnectViewModel extends AsyncNotifier<ConnectState> {
  @override
  FutureOr<ConnectState> build() {
    final myProfile = ref.watch(myProfileProvider).value;

    // Listen to connection status
    ref.listen(connectionStatusStreamProvider, (prev, next) {
      if (next is AsyncData) {
        final status = next.value;
        if (status == ConnectionStatus.active) {
          state = AsyncValue.data(
            state.value!.copyWith(flowState: ConnectFlowState.connected),
          );
          ref.invalidate(connectedProfilesProvider);
        } else if (status == ConnectionStatus.none) {
          state = AsyncValue.data(
            state.value!.copyWith(flowState: ConnectFlowState.initial),
          );
          ref.invalidate(connectedProfilesProvider);
        }
      }
    });

    return ConnectState(myInviteCode: myProfile?.inviteCode);
  }

  Future<void> dispatch(ConnectIntent intent) async {
    final prevState = state.value!;

    if (intent is SubmitInviteCodeIntent) {
      await _submitCode(intent.code);
    } else if (intent is DisconnectPartnerIntent) {
      await _disconnect();
    } else if (intent is ClearConnectErrorIntent) {
      state = AsyncValue.data(prevState.copyWith(errorMessage: null));
    }
  }

  Future<void> _submitCode(String code) async {
    final prevState = state.value!;
    final myCode = ref.read(myProfileProvider).value?.inviteCode;

    if (code == myCode) {
      state = AsyncValue.data(
        prevState.copyWith(errorMessage: ConnectErrorCode.selfCode),
      );
      return;
    }

    state = AsyncValue.data(
      prevState.copyWith(
        isProcessing: true,
        errorMessage: null,
        flowState: ConnectFlowState.waiting,
      ),
    );

    try {
      final repository = ref.read(connectRepositoryProvider);
      final managerId = await repository.connectWithCode(code);

      // 기존 활성 계획들에 대해서도 매니저 소급 적용
      await ref
          .read(recordRepositoryProvider)
          .assignManagerToActivePlans(managerId);

      // Us 탭 갱신을 위해 파트너 목록 다시 로드
      ref.invalidate(connectedProfilesProvider);

      state = AsyncValue.data(state.value!.copyWith(isProcessing: false));
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'connectWithCode');
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          flowState: ConnectFlowState.initial,
          errorMessage: ConnectErrorCode.connectFailed,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    final prevState = state.value!;
    state = AsyncValue.data(
      prevState.copyWith(isProcessing: true, errorMessage: null),
    );

    try {
      final repository = ref.read(connectRepositoryProvider);
      final connections = await repository.getConnections();

      if (connections.isNotEmpty) {
        final myUid = ref.read(myProfileProvider).value?.uid;
        final targetId = connections.first.executorId == myUid
            ? connections.first.managerId
            : connections.first.executorId;

        await ref.read(disconnectConnectionUseCaseProvider).execute(targetId);
      }
      state = AsyncValue.data(state.value!.copyWith(isProcessing: false));
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'disconnectPartner');
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          errorMessage: ConnectErrorCode.disconnectFailed,
        ),
      );
    }
  }
}
