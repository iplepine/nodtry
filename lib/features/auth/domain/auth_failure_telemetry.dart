import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'apple_sign_in_exception.dart';
import 'auth_login_result.dart';

enum AuthFailureStage {
  provider('provider'),
  profileSetup('profile_setup');

  const AuthFailureStage(this.analyticsValue);

  final String analyticsValue;
}

class AuthFailureTelemetry {
  const AuthFailureTelemetry({
    required this.stage,
    required this.error,
    required this.stackTrace,
    required this.errorCode,
    required this.reason,
  });

  final AuthFailureStage stage;
  final Object error;
  final StackTrace stackTrace;
  final String errorCode;
  final String reason;
}

AuthFailureTelemetry authFailureTelemetry(Object error, StackTrace stackTrace) {
  final isProfileSetup = error is AuthProfileSetupException;
  final rootError = isProfileSetup ? error.cause : error;
  final rootStackTrace = isProfileSetup ? error.causeStackTrace : stackTrace;

  return AuthFailureTelemetry(
    stage: isProfileSetup
        ? AuthFailureStage.profileSetup
        : AuthFailureStage.provider,
    error: rootError,
    stackTrace: rootStackTrace,
    errorCode: _safeErrorCode(rootError),
    reason: rootError.runtimeType.toString(),
  );
}

String _safeErrorCode(Object error) {
  final rawCode = switch (error) {
    FirebaseException() => error.code,
    PlatformException() => error.code,
    SignInWithAppleAuthorizationException() => error.code.name,
    AppleSignInException() => error.code,
    TimeoutException() => 'timeout',
    _ => 'unknown',
  };
  final normalized = rawCode.toLowerCase().replaceAll(
    RegExp('[^a-z0-9_.-]'),
    '_',
  );
  return normalized.length <= 100 ? normalized : normalized.substring(0, 100);
}
