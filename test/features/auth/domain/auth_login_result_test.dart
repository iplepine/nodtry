import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/auth/domain/apple_sign_in_exception.dart';
import 'package:nod_try/features/auth/domain/auth_failure_telemetry.dart';
import 'package:nod_try/features/auth/domain/auth_login_result.dart';

void main() {
  test('profile setup retries once and then succeeds', () async {
    var attempts = 0;

    final result = await completeAuthenticatedLogin(() async {
      attempts++;
      if (attempts == 1) throw StateError('transient');
    }, retryDelay: Duration.zero);

    expect(result.outcome, AuthLoginOutcome.success);
    expect(attempts, 2);
  });

  test('profile setup preserves the final Firebase error and stage', () async {
    final firebaseError = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );

    final result = await completeAuthenticatedLogin(
      () async => throw firebaseError,
      retryDelay: Duration.zero,
    );

    expect(result.outcome, AuthLoginOutcome.profileSetupFailed);
    expect(result.error, same(firebaseError));

    final wrapped = AuthProfileSetupException(
      result.error!,
      result.stackTrace!,
    );
    final telemetry = authFailureTelemetry(wrapped, StackTrace.current);
    expect(telemetry.stage, AuthFailureStage.profileSetup);
    expect(telemetry.errorCode, 'permission-denied');
    expect(telemetry.reason, 'FirebaseException');
  });

  test('profile setup failure cleans up the authenticated session', () async {
    var cleanedUp = false;

    final result = await completeAuthenticatedLogin(
      () async => throw StateError('profile setup failed'),
      cleanUpSession: () async => cleanedUp = true,
      retryDelay: Duration.zero,
    );

    expect(result.outcome, AuthLoginOutcome.profileSetupFailed);
    expect(cleanedUp, isTrue);
  });

  test('provider timeout keeps a safe non-PII error code', () {
    final telemetry = authFailureTelemetry(
      TimeoutException('private details must not be logged'),
      StackTrace.current,
    );

    expect(telemetry.stage, AuthFailureStage.provider);
    expect(telemetry.errorCode, 'timeout');
    expect(telemetry.reason, 'TimeoutException');
  });

  test('app-defined Apple failures keep a stable diagnostic code', () {
    final telemetry = authFailureTelemetry(
      const AppleSignInException(
        code: 'missing-identity-token',
        message: 'localized user-facing copy',
      ),
      StackTrace.current,
    );

    expect(telemetry.stage, AuthFailureStage.provider);
    expect(telemetry.errorCode, 'missing-identity-token');
    expect(telemetry.reason, 'AppleSignInException');
  });
}
