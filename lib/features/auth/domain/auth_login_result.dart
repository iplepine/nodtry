enum AuthLoginOutcome { success, cancelled, profileSetupFailed }

class AuthLoginResult {
  const AuthLoginResult._({required this.outcome, this.error, this.stackTrace});

  const AuthLoginResult.success() : this._(outcome: AuthLoginOutcome.success);

  const AuthLoginResult.cancelled()
    : this._(outcome: AuthLoginOutcome.cancelled);

  const AuthLoginResult.profileSetupFailed(Object error, StackTrace stackTrace)
    : this._(
        outcome: AuthLoginOutcome.profileSetupFailed,
        error: error,
        stackTrace: stackTrace,
      );

  final AuthLoginOutcome outcome;
  final Object? error;
  final StackTrace? stackTrace;
}

class AuthProfileSetupException implements Exception {
  const AuthProfileSetupException(this.cause, this.causeStackTrace);

  final Object cause;
  final StackTrace causeStackTrace;

  @override
  String toString() => 'AuthProfileSetupException(${cause.runtimeType})';
}

Future<AuthLoginResult> completeAuthenticatedLogin(
  Future<void> Function() setupProfile, {
  Future<void> Function()? cleanUpSession,
  int maxAttempts = 2,
  Duration retryDelay = const Duration(milliseconds: 300),
}) async {
  if (maxAttempts < 1) {
    throw ArgumentError.value(maxAttempts, 'maxAttempts', 'must be positive');
  }

  Object? lastError;
  StackTrace? lastStackTrace;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await setupProfile();
      return const AuthLoginResult.success();
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (attempt < maxAttempts) {
        await Future<void>.delayed(retryDelay);
      }
    }
  }

  if (cleanUpSession != null) {
    try {
      await cleanUpSession();
    } catch (_) {
      // Preserve the profile setup error, which explains why login failed.
      // A later auth-state refresh can still clear a stale local session.
    }
  }
  return AuthLoginResult.profileSetupFailed(lastError!, lastStackTrace!);
}
