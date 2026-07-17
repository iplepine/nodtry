import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../connect_state.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../repositories/connect_repository.dart';
import '../../../../utils/error_reporter.dart';
import '../../../../utils/analytics.dart';
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
          // 라이브 전환(none/waiting -> active)일 때만 1회 기록한다. 앱 재시작 시
          // 첫 emission은 prev가 AsyncLoading이라 제외되어 양쪽 사용자 모두
          // 활성화 1건으로만 잡힌다(코드 입력자/공유자 공통).
          final prevStatus =
              prev is AsyncData<ConnectionStatus> ? prev.value : null;
          if (prevStatus != null && prevStatus != ConnectionStatus.active) {
            AnalyticsService.log(AnalyticsEvent.partnerConnected);
          }
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
    // The screen submits from three places (typing the 8th character, the
    // button, and a clipboard paste) and awaits the profile list before getting
    // here, so two submissions can overlap. connectWithCode batch-writes two
    // relation docs with fresh ids and no duplicate check, so a second run would
    // leave four relation records for one partner.
    if (prevState.isProcessing) return;

    final myCode = ref.read(myProfileProvider).value?.inviteCode;

    if (code == myCode) {
      state = AsyncValue.data(
        prevState.copyWith(errorMessage: ConnectErrorCode.selfCode),
      );
      return;
    }

    AnalyticsService.log(AnalyticsEvent.connectCodeSubmitted);

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
      AnalyticsService.log(AnalyticsEvent.connectFailed, {'reason': 'exception'});
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
        AnalyticsService.log(AnalyticsEvent.partnerDisconnected);
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
