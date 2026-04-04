import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_state.dart';
import '../../../../providers/repository_provider.dart';
// Removed unused AuthService import

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
        state = AsyncValue.data(prevState.copyWith(errorMessage: null));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      state = AsyncValue.data(
        prevState.copyWith(
          isAutoLoggingIn: false,
          isGoogleLoading: false,
          isAppleLoading: false,
          isGuestLoading: false,
          isEmailLoading: false,
          errorMessage: e.toString(),
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
            errorMessage: e.toString(),
          ),
        );
        rethrow;
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    state = AsyncValue.data(
      state.value!.copyWith(isGoogleLoading: true, errorMessage: null),
    );
    try {
      final useCase = ref.read(loginWithGoogleUseCaseProvider);
      await useCase.execute();
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isGoogleLoading: false));
    }
  }

  Future<void> _loginWithApple() async {
    state = AsyncValue.data(
      state.value!.copyWith(isAppleLoading: true, errorMessage: null),
    );
    try {
      final useCase = ref.read(loginWithAppleUseCaseProvider);
      await useCase.execute();
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isAppleLoading: false));
    }
  }

  Future<void> _loginGuest() async {
    state = AsyncValue.data(
      state.value!.copyWith(isGuestLoading: true, errorMessage: null),
    );
    try {
      await ref.read(guestLoginUseCaseProvider).execute();
      ref.invalidate(myProfileProvider);
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isGuestLoading: false));
    }
  }

  Future<void> _loginWithEmail(String email, String password) async {
    state = AsyncValue.data(
      state.value!.copyWith(isEmailLoading: true, errorMessage: null),
    );
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(email, password);
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isEmailLoading: false));
    }
  }

  Future<void> _signUpWithEmail(String email, String password) async {
    state = AsyncValue.data(
      state.value!.copyWith(isEmailLoading: true, errorMessage: null),
    );
    try {
      final useCase = ref.read(signUpWithEmailUseCaseProvider);
      await useCase.execute(email, password);
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isEmailLoading: false));
    }
  }
}
