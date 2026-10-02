import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/notification_service.dart'
    show NotificationOpenRequest;

/// Where an opened notification takes the user.
enum NotificationOpenTarget {
  /// The Now tab, focused on the promise with the check-in choices
  /// (📸 인증샷 찍기 / 사진 없이 했어 / 오늘은 쉴게).
  nowCheckIn,

  /// The Now tab (the partner's card, a reply, a 인정 …).
  now,

  /// The 기록 tab (yesterday's records waiting for 인정).
  history,

  /// The 우리 tab (a new partner — the nickname sheet follows from there).
  us,

  /// Code entry, with why the link didn't hold.
  connect,

  /// Unknown type: just bring the app up.
  none,
}

/// The screen for a notification of [type] (`data.type`, or the local
/// reminder type). Unknown and future types do nothing, so old builds stay
/// safe with new server types.
NotificationOpenTarget notificationOpenTargetFor(String type) {
  switch (type) {
    case NotificationOpenRequest.reminderType:
    case 'poke':
      return NotificationOpenTarget.nowCheckIn;
    case 'poke_reply':
    case 'action_completed':
    case 'action_missed':
    case 'action_verified':
    case 'cheer':
    case 'plan_proposed':
    case 'plan_approved':
    case 'plan_rejected':
    case 'plan_updated':
      return NotificationOpenTarget.now;
    case 'verify_reminder':
      return NotificationOpenTarget.history;
    case 'partner_connected':
      return NotificationOpenTarget.us;
    case 'partner_connect_failed':
      return NotificationOpenTarget.connect;
    default:
      return NotificationOpenTarget.none;
  }
}

/// A request to focus a promise on the Now tab with its check-in choices.
class NowCheckInRequest {
  const NowCheckInRequest({required this.planId, required this.at});

  /// The promise; null focuses the first card that asks for a check-in.
  final String? planId;

  /// When it was asked: a request that waits too long (the card never
  /// showed up) is dropped instead of popping up later.
  final DateTime at;
}

/// Set by the home screen when a reminder or a knock is opened; the Now tab
/// handles it once its cards are loaded and clears it.
class NowCheckInRequestNotifier extends Notifier<NowCheckInRequest?> {
  @override
  NowCheckInRequest? build() => null;

  void request(String? planId) =>
      state = NowCheckInRequest(planId: planId, at: DateTime.now());

  void clear() => state = null;
}

final nowCheckInRequestProvider =
    NotifierProvider<NowCheckInRequestNotifier, NowCheckInRequest?>(
      NowCheckInRequestNotifier.new,
    );
