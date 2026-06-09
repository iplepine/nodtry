import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Single seam for crash + non-fatal error reporting.
///
/// Wraps [FirebaseCrashlytics] so call sites never depend on the SDK directly
/// and so a report is always a no-op-safe call (it must never throw into
/// business logic). Previously the app had no crash reporting at all and most
/// repository errors were swallowed with a `debugPrint`, so production failures
/// were invisible.
class ErrorReporter {
  ErrorReporter._();

  static FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  /// Installs global Flutter + async error handlers and configures collection.
  /// Call once, after `Firebase.initializeApp()`.
  static Future<void> initialize() async {
    try {
      // Don't upload while debugging — keeps the dashboard to real-device noise.
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      final previousOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        previousOnError?.call(details);
        _crashlytics.recordFlutterError(details);
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('[ErrorReporter] initialize failed (ignored): $e');
    }
  }

  /// Associates subsequent reports with a user (no PII beyond the uid).
  static void setUser(String? uid) {
    try {
      _crashlytics.setUserIdentifier(uid ?? '');
    } catch (_) {/* never throw */}
  }

  /// Records a caught (non-fatal by default) error. Safe to call anywhere,
  /// including before Crashlytics is initialized.
  static void record(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    try {
      _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);
    } catch (_) {
      // Reporting must never break the calling flow.
    }
    if (kDebugMode) {
      debugPrint('[ErrorReporter] ${reason ?? ''} $error');
    }
  }
}
