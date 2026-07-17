import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/auth/domain/usecases/login_with_email_use_case.dart';
import 'package:nod_try/features/auth/presentation/auth_state.dart';
import 'package:nod_try/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/utils/ui_error_codes.dart';

class _ThrowingLoginUseCase implements LoginWithEmailUseCase {
  _ThrowingLoginUseCase(this.error);

  final Object error;

  @override
  Future<UserCredential?> execute(String email, String password) async {
    throw error;
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
}
