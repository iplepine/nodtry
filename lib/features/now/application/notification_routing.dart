import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/history_item.dart';
import '../../../models/home_state.dart';
import '../../../services/notification_quick_actions.dart';
import '../../../services/notification_service.dart'
    show NotificationOpenRequest;
import '../../history/presentation/history_state.dart';
import '../presentation/now_tab_state.dart';

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

/// Where [request] lands: [notificationOpenTargetFor] its type, except that
/// a record of an earlier day (`actionDate`) is on the 기록 tab — today's
/// cards only show today.
NotificationOpenTarget notificationOpenTargetForRequest(
  NotificationOpenRequest request, {
  DateTime? now,
}) {
  final target = notificationOpenTargetFor(request.type);
  final day = request.actionDate;
  if (target == NotificationOpenTarget.now &&
      day != null &&
      !_isSameDay(day, now ?? DateTime.now())) {
    return NotificationOpenTarget.history;
  }
  return target;
}

/// How long an opened notification waits for its promise to show up. A
/// request that waits longer (the card never came) is dropped instead of
/// jumping or popping up minutes later.
const Duration notificationFocusTimeout = Duration(seconds: 30);

/// How long a tab waits, once it has data, for a promise that isn't there:
/// the first snapshot can come from the cache, before the server's.
const Duration notificationFocusGrace = Duration(seconds: 3);

/// A request to bring the promise an opened notification is about into view
/// (and, for a reminder or a knock, offer its check-in choices).
@immutable
class NotificationFocusRequest {
  const NotificationFocusRequest({
    required this.planId,
    required this.at,
    this.actionId,
    this.day,
    this.checkIn = false,
    this.quickAction,
  });

  /// The promise; null (check-in only) focuses the first card that asks
  /// for a check-in.
  final String? planId;

  /// The record (`actions/{id}`), when the notification is about one.
  final String? actionId;

  /// The day of that record, when known.
  final DateTime? day;

  /// Offer the check-in choices (📸 인증샷 찍기 / 사진 없이 했어 / 오늘은 쉴게).
  final bool checkIn;

  /// The push's button the user answered with: run on the card instead of
  /// just showing it (and instead of the check-in choices).
  final NotificationQuickAction? quickAction;

  /// When it was asked (see [notificationFocusTimeout]).
  final DateTime at;

  bool isExpired(DateTime now) => now.difference(at) > notificationFocusTimeout;
}

/// Set by the home screen when a notification is opened; the tab handles it
/// once its data is in and clears it.
class NotificationFocusNotifier extends Notifier<NotificationFocusRequest?> {
  @override
  NotificationFocusRequest? build() => null;

  void request(
    String? planId, {
    String? actionId,
    DateTime? day,
    bool checkIn = false,
    NotificationQuickAction? quickAction,
  }) => state = NotificationFocusRequest(
    planId: planId,
    actionId: actionId,
    day: day,
    checkIn: checkIn,
    quickAction: quickAction,
    at: DateTime.now(),
  );

  void clear() => state = null;
}

/// A promise to focus on the Now tab.
final nowFocusRequestProvider =
    NotifierProvider<NotificationFocusNotifier, NotificationFocusRequest?>(
      NotificationFocusNotifier.new,
    );

/// A promise (or record) to focus on the 기록 tab. The home screen switches to
/// the tab when one is set — also by the Now tab, for a promise that isn't on
/// today's cards.
final historyFocusRequestProvider =
    NotifierProvider<NotificationFocusNotifier, NotificationFocusRequest?>(
      NotificationFocusNotifier.new,
    );

/// Where a card shows on the Now tab.
enum NowCardArea { carousel, primary, secondary, manager }

typedef NowCardSpot = ({NowCardArea area, int index});

/// Whether [card] is about [planId] (a 오늘 완료 card lists every plan done
/// today).
bool nowCardShowsPlan(HomeCardModel card, String planId) =>
    card.plan?.id == planId ||
    card.completedPlans.any((plan) => plan.id == planId);

/// The visible card of [planId] on the Now tab, or null when it isn't on
/// today's cards (some cards are kept off the screen, see
/// [HomeCardStatePriority]).
NowCardSpot? locateNowCard(NowTabState state, String planId) {
  final carousel = state.primaryCarouselCards;
  for (var i = 0; i < carousel.length; i++) {
    if (nowCardShowsPlan(carousel[i], planId)) {
      return (area: NowCardArea.carousel, index: i);
    }
  }
  final primary = state.primaryCard;
  if (carousel.isEmpty &&
      primary != null &&
      nowCardShowsPlan(primary, planId)) {
    return (area: NowCardArea.primary, index: 0);
  }
  for (var i = 0; i < state.secondaryCards.length; i++) {
    if (nowCardShowsPlan(state.secondaryCards[i], planId)) {
      return (area: NowCardArea.secondary, index: i);
    }
  }
  for (var i = 0; i < state.managerCards.length; i++) {
    if (nowCardShowsPlan(state.managerCards[i], planId)) {
      return (area: NowCardArea.manager, index: i);
    }
  }
  return null;
}

/// The card at [spot] in [state].
HomeCardModel? nowCardAt(NowTabState state, NowCardSpot spot) {
  final list = switch (spot.area) {
    NowCardArea.carousel => state.primaryCarouselCards,
    NowCardArea.primary => [?state.primaryCard],
    NowCardArea.secondary => state.secondaryCards,
    NowCardArea.manager => state.managerCards,
  };
  return spot.index < list.length ? list[spot.index] : null;
}

/// Whether [action] can run on a card in [area]: 인정 and 응원 are answers to
/// the partner's card; a knock reply is about my own promise.
bool quickActionFitsArea(NotificationQuickAction action, NowCardArea area) =>
    switch (action) {
      NotificationQuickAction.props ||
      NotificationQuickAction.cheer => area == NowCardArea.manager,
      NotificationQuickAction.pokeComing ||
      NotificationQuickAction.pokePass => area != NowCardArea.manager,
    };

/// What to focus on the 기록 tab: a record's id, or [historySummaryKey] of an
/// ended promise's summary; null when [request] has nothing there.
///
/// The record itself when its id is known; else the promise's record of
/// [NotificationFocusRequest.day]; else its latest record; else, for an
/// ended promise, its summary.
String? locateHistoryItem(
  HistoryState state,
  NotificationFocusRequest request,
) {
  final actionId = request.actionId;
  if (actionId != null) {
    for (final item in state.activeItems) {
      if (item.id == actionId) return item.id;
    }
  }
  final planId = request.planId;
  if (planId == null) return null;
  final records = state.activeItems.where((item) => item.planId == planId);
  final day = request.day;
  if (day != null) {
    for (final item in records) {
      if (_isSameDay(item.date, day)) return item.id;
    }
  }
  HistoryItem? latest;
  for (final item in records) {
    if (latest == null || item.date.isAfter(latest.date)) latest = item;
  }
  if (latest != null) return latest.id;
  for (final summary in state.finishedPlanSummaries) {
    if (summary.planId == planId) return historySummaryKey(planId);
  }
  return null;
}

/// The [locateHistoryItem] id of an ended promise's summary card.
String historySummaryKey(String planId) => 'summary:$planId';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
