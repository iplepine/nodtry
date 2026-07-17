import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_state.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../utils/analytics.dart';
import '../../../../utils/error_reporter.dart';
import '../../../../utils/ui_error_codes.dart';
// Removed unused AuthService import

/// Maps a failure to a stable code the widget layer turns into localized copy.
/// Firebase's own messages are English-only implementation detail — they used to
/// be shown verbatim ("[firebase_auth/wrong-password] The password is invalid…").
String _authErrorCodeFor(Object error) {
  if (error is! FirebaseAuthException) return AuthErrorCode.generic;
  return switch (error.code) {
    // Recent Firebase versions collapse wrong-password/user-not-found into
    // invalid-credential; keep the older codes mapped for older SDK responses.
    'invalid-credential' || 'wrong-password' => AuthErrorCode.invalidCredential,
    'user-not-found' || 'user-disabled' => AuthErrorCode.userNotFound,
    'email-already-in-use' => AuthErrorCode.emailInUse,
    'invalid-email' => AuthErrorCode.invalidEmail,
    'weak-password' => AuthErrorCode.weakPassword,
    'too-many-requests' => AuthErrorCode.tooManyRequests,
    'network-request-failed' => AuthErrorCode.network,
    _ => AuthErrorCode.generic,
  };
}

final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

class AuthViewModel extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() {
    return const AuthState();
  }

  Future<void> dispatch(AuthIntent intent) async {
    final prevState = state.value ?? const AuthState();

    try {
      if (intent is CheckAuthIntent) {
        await _checkAuth();
      } else if (intent is LoginWithGoogleIntent) {
        await _loginWithGoogle();
      } else if (intent is LoginWithAppleIntent) {
        await _loginWithApple();
      } else if (intent is LoginGuestIntent) {
        await _loginGuest();
      } else if (intent is LoginWithEmailIntent) {
        await _loginWithEmail(intent.email, intent.password);
      } else if (intent is SignUpWithEmailIntent) {
        await _signUpWithEmail(intent.email, intent.password);
      } else if (intent is ClearErrorIntent) {
        state = AsyncValue.data(prevState.copyWith(errorCode: null));
      }
    } catch (e, stack) {
      final failedMethod = switch (intent) {
        LoginWithGoogleIntent() => 'google',
        LoginWithAppleIntent() => 'apple',
        LoginGuestIntent() => 'anonymous',
        LoginWithEmailIntent() => 'email',
        SignUpWithEmailIntent() => 'email',
        _ => null,
      };
      if (failedMethod != null) {
        AnalyticsService.log(AnalyticsEvent.loginFailed, {
          'method': failedMethod,
          'reason': e.runtimeType.toString(),
        });
      }
      ErrorReporter.record(e, stack, reason: 'authDispatch:$failedMethod');
      // Publish the failure exactly once. Emitting AsyncError here *and* then
      // AsyncData below made the splash listener fire on both branches, so a
      // single failed login queued two identical snackbars.
      state = AsyncValue.data(
        prevState.copyWith(
          isAutoLoggingIn: false,
          isGoogleLoading: false,
          isAppleLoading: false,
          isGuestLoading: false,
          isEmailLoading: false,
          errorCode: _authErrorCodeFor(e),
        ),
      );
    }
  }

  Future<void> _checkAuth() async {
    final authService = ref.read(authServiceProvider);
    if (authService.currentUser != null) {
      state = AsyncValue.data(state.value!.copyWith(isAutoLoggingIn: true));
      try {
        final userModel = await ref.read(autoLoginUseCaseProvider).execute();
        if (userModel == null) {
          state = AsyncValue.data(
            state.value!.copyWith(isAutoLoggingIn: false),
          );
        }
        // Navigation is handled in the UI based on auth state or explicitly
      } catch (e) {
        state = AsyncValue.data(
          state.value!.copyWith(
            isAutoLoggingIn: false,
            errorCode: _authErrorCodeFor(e),
          ),
        );
        rethrow;
      }
    } else {
      // 사용자가 없는 경우(로그아웃 상태 등)에 대비하여 로딩 상태를 false로 유지
      state = AsyncValue.data(
        state.value!.copyWith(isAutoLoggingIn: false),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    state = AsyncValue.data(
      state.value!.copyWith(isGoogleLoading: true, errorCode: null),
    );
    try {
      final useCase = ref.read(loginWithGoogleUseCaseProvider);
      await useCase.execute();
      AnalyticsService.logLogin('google');
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isGoogleLoading: false));
    }
  }

  Future<void> _loginWithApple() async {
    state = AsyncValue.data(
      state.value!.copyWith(isAppleLoading: true, errorCode: null),
    );
    try {
      final useCase = ref.read(loginWithAppleUseCaseProvider);
      await useCase.execute();
      AnalyticsService.logLogin('apple');
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isAppleLoading: false));
    }
  }

  Future<void> _loginGuest() async {
    state = AsyncValue.data(
      state.value!.copyWith(isGuestLoading: true, errorCode: null),
    );
    try {
      await ref.read(guestLoginUseCaseProvider).execute();
      ref.invalidate(myProfileProvider);
      AnalyticsService.logLogin('anonymous');
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isGuestLoading: false));
    }
  }

  Future<void> _loginWithEmail(String email, String password) async {
    state = AsyncValue.data(
      state.value!.copyWith(isEmailLoading: true, errorCode: null),
    );
    try {
      final useCase = ref.read(loginWithEmailUseCaseProvider);
      await useCase.execute(email, password);
      AnalyticsService.logLogin('email');
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isEmailLoading: false));
    }
  }

  Future<void> _signUpWithEmail(String email, String password) async {
    state = AsyncValue.data(
      state.value!.copyWith(isEmailLoading: true, errorCode: null),
    );
    try {
      final useCase = ref.read(signUpWithEmailUseCaseProvider);
      await useCase.execute(email, password);
      AnalyticsService.logLogin('email');
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isEmailLoading: false));
    }
  }
}
