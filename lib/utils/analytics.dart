import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Single seam for product analytics.
///
/// Wraps [FirebaseAnalytics] so call sites never depend on the SDK directly and
/// so a log is always a no-op-safe call (it must never throw into business
/// logic). Mirrors [ErrorReporter] (lib/utils/error_reporter.dart): both are
/// thin static wrappers around a Firebase service installed once at startup.
///
/// Event/param naming follows GA4 rules: names are snake_case, <= 40 chars, and
/// parameter values must be String or num — so [log] sanitizes bools to 1/0 and
/// drops nulls before handing them to the SDK.
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver? _observer;

  /// Configures collection. Call once, after `Firebase.initializeApp()`.
  /// Collection is disabled while debugging to keep the dashboard to real
  /// usage (matches [ErrorReporter.initialize]). Flip the guard temporarily
  /// when verifying events via Firebase DebugView.
  static Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    } catch (e) {
      debugPrint('[Analytics] initialize failed (ignored): $e');
    }
  }

  /// Navigator observer that auto-logs `screen_view` for every GoRoute push.
  /// Memoized so GoRouter always receives the same instance.
  static NavigatorObserver observer() {
    try {
      return _observer ??= FirebaseAnalyticsObserver(analytics: _analytics);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] observer unavailable (ignored): $e');
      }
      return NavigatorObserver();
    }
  }

  /// Logs a custom event. Safe to call anywhere; never throws.
  static void log(String name, [Map<String, Object?>? params]) {
    try {
      _analytics.logEvent(name: name, parameters: _sanitize(params));
    } catch (_) {
      // Reporting must never break the calling flow.
    }
    if (kDebugMode) {
      debugPrint('[Analytics] $name ${params ?? ''}');
    }
  }

  /// Firebase reserved `login` event (shows up under Engagement → Events).
  static void logLogin(String method) {
    try {
      _analytics.logLogin(loginMethod: method);
    } catch (_) {
      /* never throw */
    }
    if (kDebugMode) debugPrint('[Analytics] login method=$method');
  }

  /// Firebase reserved `purchase` event with monetary value.
  static void logPurchase({
    required double value,
    required String currency,
    String? itemId,
  }) {
    try {
      _analytics.logPurchase(
        value: value,
        currency: currency,
        items: itemId == null
            ? null
            : [AnalyticsEventItem(itemId: itemId, itemName: itemId)],
      );
    } catch (_) {
      /* never throw */
    }
    if (kDebugMode) debugPrint('[Analytics] purchase $itemId $value $currency');
  }

  /// Associates subsequent events with a user (uid only, no other PII).
  static void setUserId(String? uid) {
    try {
      _analytics.setUserId(id: uid);
    } catch (_) {
      /* never throw */
    }
  }

  /// Sets a user property used as a segmentation dimension in the console.
  static void setUserProperty(String name, String? value) {
    try {
      _analytics.setUserProperty(name: name, value: value);
    } catch (_) {
      /* never throw */
    }
  }

  /// GA4 params accept only String/num. Convert bools to 1/0 and drop nulls.
  static Map<String, Object>? _sanitize(Map<String, Object?>? params) {
    if (params == null || params.isEmpty) return null;
    final out = <String, Object>{};
    params.forEach((key, value) {
      if (value == null) return;
      if (value is bool) {
        out[key] = value ? 1 : 0;
      } else if (value is String || value is num) {
        out[key] = value;
      } else {
        out[key] = value.toString();
      }
    });
    return out.isEmpty ? null : out;
  }
}

/// Custom event names. Reserved events (`login`, `purchase`, `screen_view`) are
/// emitted via their dedicated SDK helpers and are intentionally absent here.
class AnalyticsEvent {
  AnalyticsEvent._();

  // Auth / account
  static const loginFailed = 'login_failed';
  static const logout = 'logout';
  static const accountDeleted = 'account_deleted';

  // Activation — partner connect
  static const inviteCodeShared = 'invite_code_shared';
  static const connectCodeSubmitted = 'connect_code_submitted';
  static const partnerConnected = 'partner_connected';
  static const connectFailed = 'connect_failed';
  static const partnerDisconnected = 'partner_disconnected';

  // Plan lifecycle
  static const planCreated = 'plan_created';
  static const planApproved = 'plan_approved';
  static const planRejected = 'plan_rejected';

  // Daily practice loop (Now tab)
  static const planCompleted = 'plan_completed';
  static const planSkipped = 'plan_skipped';
  static const planPassed = 'plan_passed';
  static const planRestUsed = 'plan_rest_used';
  static const planRescued = 'plan_rescued';
  static const partnerChecked = 'partner_checked';
  static const partnerCheered = 'partner_cheered';
  static const partnerVerified = 'partner_verified';
  static const pokeSent = 'poke_sent';
  static const pokeAcknowledged = 'poke_acknowledged';
  static const promiseProposed = 'promise_proposed';
  static const promiseResponded = 'promise_responded';
  static const promiseSettlementAcknowledged =
      'promise_settlement_acknowledged';
  static const pilotSettlementRecorded = 'pilot_settlement_recorded';

  // Focus timer
  static const focusTimerStarted = 'focus_timer_started';
  static const focusTimerCompleted = 'focus_timer_completed';
  static const focusTimerCancelled = 'focus_timer_cancelled';

  // Monetization (donation IAP)
  static const donationInitiated = 'donation_initiated';
  static const purchaseFailed = 'purchase_failed';

  // Settings / re-engagement
  static const themeChanged = 'theme_changed';
  static const localeChanged = 'locale_changed';
  static const notificationPermissionResult = 'notification_permission_result';
  static const notificationOpened = 'notification_opened';
  static const notificationBannerShown = 'notification_banner_shown';
  static const notificationBannerTapped = 'notification_banner_tapped';
}

/// User property names (segmentation dimensions).
class AnalyticsUserProperty {
  AnalyticsUserProperty._();

  static const loginMethod = 'login_method';
  static const hasPartner = 'has_partner';
  static const appTheme = 'app_theme';
  static const appLocale = 'app_locale';
}
