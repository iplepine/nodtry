import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../connect_state.dart';
import '../../application/invite_services.dart';
import '../../application/partner_link_binder.dart';
import '../../domain/invite_code.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../repositories/connect_repository.dart';
import '../../../../utils/error_reporter.dart';
import '../../../../utils/analytics.dart';
import '../../../../utils/ui_error_codes.dart';

final connectViewModelProvider =
    AsyncNotifierProvider<ConnectViewModel, ConnectState>(ConnectViewModel.new);

/// The outcome of looking up who owns a code, before asking to connect.
sealed class InviteLookup {
  const InviteLookup();
}

/// [owner] holds [code]; show "{이름}의 운동 약속을 봐줄래요?".
class InviteLookupFound extends InviteLookup {
  const InviteLookupFound(this.code, this.owner);
  final String code;
  final UserModel owner;
}

/// Nothing to confirm; [errorCode] (a [ConnectErrorCode]) is also in state.
class InviteLookupFailed extends InviteLookup {
  const InviteLookupFailed(this.errorCode);
  final String errorCode;
}

class ConnectViewModel extends AsyncNotifier<ConnectState> {
  @override
  FutureOr<ConnectState> build() {
    final myProfile = ref.watch(myProfileProvider).value;

    // Listen to connection status. The `partner_connected` event is logged by
    // partnerLinkBinderProvider (alive for the whole app run), not here.
    ref.listen(connectionStatusStreamProvider, (prev, next) {
      if (next is AsyncData) {
        final status = next.value;
        final current = state.value ?? const ConnectState();
        if (status == ConnectionStatus.active) {
          state = AsyncValue.data(
            current.copyWith(flowState: ConnectFlowState.connected),
          );
          ref.invalidate(connectedProfilesProvider);
        } else if (status == ConnectionStatus.none) {
          state = AsyncValue.data(
            current.copyWith(flowState: ConnectFlowState.initial),
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
      await _submitCode(intent.code, intent.source);
    } else if (intent is DisconnectPartnerIntent) {
      await _disconnect();
    } else if (intent is ClearConnectErrorIntent) {
      state = AsyncValue.data(prevState.copyWith(errorMessage: null));
    }
  }

  void _setError(String code) {
    final current = state.value ?? const ConnectState();
    state = AsyncValue.data(current.copyWith(errorMessage: code));
  }

  /// Checks a typed or linked code and finds its owner, so the screen can ask
  /// before connecting. Clipboard codes are looked up by
  /// [InviteCodeDetector] instead (it stays quiet about misses).
  Future<InviteLookup> lookupInviter(
    String rawCode, {
    InviteCodeSource source = InviteCodeSource.manual,
  }) async {
    final code = normalizeInviteCode(rawCode);
    if (!isValidInviteCode(code)) {
      _setError(ConnectErrorCode.codeFormat);
      return const InviteLookupFailed(ConnectErrorCode.codeFormat);
    }
    final me = ref.read(myProfileProvider).value;
    if (code == me?.inviteCode) {
      _setError(ConnectErrorCode.selfCode);
      return const InviteLookupFailed(ConnectErrorCode.selfCode);
    }

    final UserModel? owner;
    try {
      owner = await ref.read(userRepositoryProvider).getUserByInviteCode(code);
    } on InviteCodeIsMineException {
      // My code, though my profile hasn't loaded or still shows an old one.
      _setError(ConnectErrorCode.selfCode);
      return const InviteLookupFailed(ConnectErrorCode.selfCode);
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'lookupInviter');
      _setError(ConnectErrorCode.connectFailed);
      return const InviteLookupFailed(ConnectErrorCode.connectFailed);
    }
    if (owner != null && owner.uid == me?.uid) {
      _setError(ConnectErrorCode.selfCode);
      return const InviteLookupFailed(ConnectErrorCode.selfCode);
    }
    logInviteCodeDetected(source, matched: owner != null);
    if (owner == null) {
      _setError(ConnectErrorCode.codeNotFound);
      return const InviteLookupFailed(ConnectErrorCode.codeNotFound);
    }
    final current = state.value ?? const ConnectState();
    state = AsyncValue.data(current.copyWith(errorMessage: null));
    return InviteLookupFound(code, owner);
  }

  Future<void> _submitCode(String rawCode, InviteCodeSource source) async {
    final prevState = state.value!;
    // The screen can submit from more than one place (the button, the
    // keyboard action, a clipboard or link code), so two submissions can
    // overlap. connectWithCode batch-writes two relation docs with fresh ids
    // and no duplicate check, so a second run would leave four relation
    // records for one partner.
    if (prevState.isProcessing) return;

    final code = normalizeInviteCode(rawCode);
    final myCode = ref.read(myProfileProvider).value?.inviteCode;

    if (code == myCode) {
      state = AsyncValue.data(
        prevState.copyWith(errorMessage: ConnectErrorCode.selfCode),
      );
      return;
    }

    AnalyticsService.log(AnalyticsEvent.connectCodeSubmitted, {
      'source': source.id,
    });

    state = AsyncValue.data(
      prevState.copyWith(
        isProcessing: true,
        errorMessage: null,
        flowState: ConnectFlowState.waiting,
      ),
    );

    // The relation snapshot can arrive before connectWithCode returns, so the
    // binder must already know this device is the one entering the code.
    ref.read(inviteeLinkPendingProvider.notifier).mark();

    try {
      final repository = ref.read(connectRepositoryProvider);
      final managerId = await repository.connectWithCode(code);

      // My own running promises get the new partner as manager right away.
      // Best effort: the link itself already exists, and the server does the
      // same for both people in onRelationCreated.
      try {
        await ref
            .read(recordRepositoryProvider)
            .assignManagerToActivePlans(managerId);
      } catch (e, s) {
        ErrorReporter.record(e, s, reason: 'assignManagerAfterLink');
      }

      // Us 탭 갱신을 위해 파트너 목록 다시 로드
      ref.invalidate(connectedProfilesProvider);

      state = AsyncValue.data(state.value!.copyWith(isProcessing: false));
    } catch (e, s) {
      ref.read(inviteeLinkPendingProvider.notifier).clear();
      final String errorCode;
      final String reason;
      if (e is InviteCodeNotFoundException) {
        errorCode = ConnectErrorCode.codeNotFound;
        reason = 'not_found';
      } else if (e is InviteCodeIsMineException) {
        errorCode = ConnectErrorCode.selfCode;
        reason = 'self_code';
      } else if (e is InviteLinkRefusedException) {
        // The server (redeemInviteCode) refused before linking — the same
        // message a `partner_connect_failed` push brings for an undone link.
        errorCode = ConnectErrorCode.forFailureReason(e.reason);
        reason = e.reason;
      } else {
        ErrorReporter.record(e, s, reason: 'connectWithCode');
        errorCode = ConnectErrorCode.connectFailed;
        reason = 'exception';
      }
      AnalyticsService.log(AnalyticsEvent.connectFailed, {'reason': reason});
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          flowState: ConnectFlowState.initial,
          errorMessage: errorCode,
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
