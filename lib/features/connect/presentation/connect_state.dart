import 'package:freezed_annotation/freezed_annotation.dart';

part 'connect_state.freezed.dart';

enum ConnectFlowState { initial, waiting, connected, error }

@freezed
abstract class ConnectState with _$ConnectState {
  const factory ConnectState({
    @Default(ConnectFlowState.initial) ConnectFlowState flowState,
    String? myInviteCode,
    String? errorMessage,
    @Default(false) bool isProcessing,
  }) = _ConnectState;
}

sealed class ConnectIntent {
  const ConnectIntent();
}

class SubmitInviteCodeIntent extends ConnectIntent {
  final String code;
  const SubmitInviteCodeIntent(this.code);
}

class DisconnectPartnerIntent extends ConnectIntent {
  const DisconnectPartnerIntent();
}

class ClearConnectErrorIntent extends ConnectIntent {
  const ClearConnectErrorIntent();
}
