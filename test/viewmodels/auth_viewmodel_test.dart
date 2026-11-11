import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/auth/domain/auth_login_result.dart';
import 'package:nod_try/features/auth/domain/usecases/login_with_email_use_case.dart';
import 'package:nod_try/features/auth/domain/usecases/login_with_google_use_case.dart';
import 'package:nod_try/features/auth/presentation/auth_state.dart';
import 'package:nod_try/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/utils/analytics.dart';
import 'package:nod_try/utils/ui_error_codes.dart';

class _ThrowingLoginUseCase implements LoginWithEmailUseCase {
  _ThrowingLoginUseCase(this.error);

  final Object error;

  @override
  Future<AuthLoginResult> execute(String email, String password) async {
    throw error;
  }
}

class _CancelledGoogleLoginUseCase implements LoginWithGoogleUseCase {
  @override
  Future<AuthLoginResult> execute() async {
    return const AuthLoginResult.cancelled();
  }
}

class _ResultLoginUseCase implements LoginWithEmailUseCase {
  _ResultLoginUseCase(this.result);

  final AuthLoginResult result;

  @override
  Future<AuthLoginResult> execute(String email, String password) async {
    return result;
  }
}

class _BlockingLoginUseCase implements LoginWithEmailUseCase {
  final entered = Completer<void>();
  final release = Completer<void>();
  var calls = 0;

  @override
  Future<AuthLoginResult> execute(String email, String password) async {
    calls++;
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return const AuthLoginResult.success();
  }
}

ProviderContainer _containerThrowing(Object error) {
  return ProviderContainer(
    overrides: [
      loginWithEmailUseCaseProvider.overrideWithValue(
        _ThrowingLoginUseCase(error),
      ),
    ],
  );
}

Future<AuthState> _attemptLogin(ProviderContainer container) async {
  await container.read(authViewModelProvider.future);
  await container
      .read(authViewModelProvider.notifier)
      .dispatch(const LoginWithEmailIntent(email: 'a@b.com', password: 'nope'));
  return container.read(authViewModelProvider).value!;
}

void main() {
  late List<(String, Map<String, Object>?)> analyticsEvents;

  setUp(() {
    analyticsEvents = [];
    AnalyticsService.setTestSink(
      (name, parameters) => analyticsEvents.add((name, parameters)),
    );
  });

  tearDown(() => AnalyticsService.setTestSink(null));

  test(
    'a rejected credential becomes a stable code, not a Firebase string',
    () async {
      final container = _containerThrowing(
        FirebaseAuthException(
          code: 'invalid-credential',
          message:
              'The password is invalid or the user does not have a password.',
        ),
      );
      addTearDown(container.dispose);

      final state = await _attemptLogin(container);

      // Regression: this used to be `e.toString()`, so the login screen showed
      // "[firebase_auth/invalid-credential] The password is invalid or ...".
      expect(state.errorCode, AuthErrorCode.invalidCredential);
      expect(state.isEmailLoading, isFalse);
      expect(analyticsEvents, hasLength(1));
      expect(analyticsEvents.single.$1, AnalyticsEvent.loginFailed);
      expect(analyticsEvents.single.$2, {
        'method': 'email',
        'stage': 'provider',
        'reason': 'FirebaseAuthException',
        'error_code': 'invalid-credential',
      });
    },
  );

  test('an unmapped failure falls back to the generic code', () async {
    final container = _containerThrowing(Exception('something odd'));
    addTearDown(container.dispose);

    final state = await _attemptLogin(container);

    expect(state.errorCode, AuthErrorCode.generic);
  });

  test('a network failure is distinguished from a bad password', () async {
    final container = _containerThrowing(
      FirebaseAuthException(code: 'network-request-failed'),
    );
    addTearDown(container.dispose);

    expect((await _attemptLogin(container)).errorCode, AuthErrorCode.network);
  });

  test(
    'one failed login publishes exactly one error, and never as AsyncError',
    () async {
      final container = _containerThrowing(
        FirebaseAuthException(code: 'invalid-credential'),
      );
      addTearDown(container.dispose);
      await container.read(authViewModelProvider.future);

      final emissions = <AsyncValue<AuthState>>[];
      final sub = container.listen(
        authViewModelProvider,
        (_, next) => emissions.add(next),
      );
      addTearDown(sub.close);

      await container
          .read(authViewModelProvider.notifier)
          .dispatch(
            const LoginWithEmailIntent(email: 'a@b.com', password: 'nope'),
          );

      // Regression: the view model emitted AsyncError *and* then AsyncData with a
      // message, and the splash listener fired on both — two identical snackbars
      // for one failure.
      expect(emissions.any((e) => e.hasError), isFalse);
      expect(emissions.where((e) => e.value?.errorCode != null), hasLength(1));
    },
  );

  test('retrying clears the previous error before the attempt', () async {
    final container = _containerThrowing(
      FirebaseAuthException(code: 'invalid-credential'),
    );
    addTearDown(container.dispose);
    await _attemptLogin(container);

    final emissions = <AsyncValue<AuthState>>[];
    final sub = container.listen(
      authViewModelProvider,
      (_, next) => emissions.add(next),
    );
    addTearDown(sub.close);

    await container
        .read(authViewModelProvider.notifier)
        .dispatch(
          const LoginWithEmailIntent(email: 'a@b.com', password: 'nope2'),
        );

    // The code must drop to null while in flight, otherwise the splash listener
    // cannot tell a fresh failure from the one still sitting in state.
    expect(emissions.any((e) => e.value?.errorCode == null), isTrue);
    expect(
      container.read(authViewModelProvider).value!.errorCode,
      AuthErrorCode.invalidCredential,
    );
  });

  test('cancelling provider sign-in is neither success nor failure', () async {
    final container = ProviderContainer(
      overrides: [
        loginWithGoogleUseCaseProvider.overrideWithValue(
          _CancelledGoogleLoginUseCase(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authViewModelProvider.future);

    await container
        .read(authViewModelProvider.notifier)
        .dispatch(const LoginWithGoogleIntent());

    final state = container.read(authViewModelProvider).value!;
    expect(state.errorCode, isNull);
    expect(state.isGoogleLoading, isFalse);
    expect(analyticsEvents, isEmpty);
  });

  test(
    'a profile setup failure is surfaced as a retryable network error',
    () async {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      final container = ProviderContainer(
        overrides: [
          loginWithEmailUseCaseProvider.overrideWithValue(
            _ResultLoginUseCase(
              AuthLoginResult.profileSetupFailed(error, StackTrace.current),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await _attemptLogin(container);

      expect(state.errorCode, AuthErrorCode.network);
      expect(state.isEmailLoading, isFalse);
      expect(analyticsEvents, hasLength(1));
      expect(analyticsEvents.single.$1, AnalyticsEvent.profileSetupFailed);
      expect(analyticsEvents.single.$2, {
        'method': 'email',
        'stage': 'profile_setup',
        'reason': 'FirebaseException',
        'error_code': 'unavailable',
      });
    },
  );

  test('a completed profile setup logs the reserved login event', () async {
    final container = ProviderContainer(
      overrides: [
        loginWithEmailUseCaseProvider.overrideWithValue(
          _ResultLoginUseCase(const AuthLoginResult.success()),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await _attemptLogin(container);

    expect(state.errorCode, isNull);
    expect(analyticsEvents, hasLength(1));
    expect(analyticsEvents.single.$1, 'login');
    expect(analyticsEvents.single.$2, const <String, Object>{
      'login_method': 'email',
    });
  });

  test(
    'ignores a second login while the first attempt is in progress',
    () async {
      final useCase = _BlockingLoginUseCase();
      final container = ProviderContainer(
        overrides: [loginWithEmailUseCaseProvider.overrideWithValue(useCase)],
      );
      addTearDown(container.dispose);
      await container.read(authViewModelProvider.future);
      final notifier = container.read(authViewModelProvider.notifier);
      const intent = LoginWithEmailIntent(email: 'a@b.com', password: 'secret');

      final firstAttempt = notifier.dispatch(intent);
      await useCase.entered.future;
      await notifier.dispatch(intent);

      expect(useCase.calls, 1);
      useCase.release.complete();
      await firstAttempt;
    },
  );
}
