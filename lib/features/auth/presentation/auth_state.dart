import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAutoLoggingIn,
    @Default(false) bool isGoogleLoading,
    @Default(false) bool isAppleLoading,
    @Default(false) bool isGuestLoading,
    @Default(false) bool isEmailLoading,
    /// An [AuthErrorCode], not a sentence — the widget layer resolves it to
    /// localized copy. See `utils/ui_error_codes.dart`.
    String? errorCode,
  }) = _AuthState;
}

sealed class AuthIntent {
  const AuthIntent();
}

class CheckAuthIntent extends AuthIntent {
  const CheckAuthIntent();
}

class LoginWithGoogleIntent extends AuthIntent {
  const LoginWithGoogleIntent();
}

class LoginWithAppleIntent extends AuthIntent {
  const LoginWithAppleIntent();
}

class LoginGuestIntent extends AuthIntent {
  const LoginGuestIntent();
}

class LoginWithEmailIntent extends AuthIntent {
  final String email;
  final String password;
  const LoginWithEmailIntent({required this.email, required this.password});
}

class SignUpWithEmailIntent extends AuthIntent {
  final String email;
  final String password;
  const SignUpWithEmailIntent({required this.email, required this.password});
}

class ClearErrorIntent extends AuthIntent {
  const ClearErrorIntent();
}
