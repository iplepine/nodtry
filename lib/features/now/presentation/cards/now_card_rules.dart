import '../../../../l10n/app_localizations.dart';
import '../../../../models/home_state.dart';
import '../../../../models/plan_model.dart';
import '../../../../widgets/time_chip.dart';

/// Display rules for Now-tab cards, decided from [HomeCardState] alone.
///
/// Why this exists: the cards used to branch on *translated* strings — the
/// repository's `headerMessage` ('조정 중', '함께하는 중', 'Working together')
/// picked the header and hid the approve buttons, and the time chip type was
/// guessed from substrings like '지남' / 'ago' / 'left'. Any copy edit silently
/// changed behaviour. Nothing here reads display text.

/// Which header line a partner-side (manager) card shows.
enum ManagerCardHeader {
  /// The partner finished every plan scheduled today.
  partnerTodayComplete,

  /// The partner reported one plan done and it waits for 인정.
  partnerAction,

  /// The partner proposed a new plan that waits for approval.
  planProposed,

  /// The partner changed a plan and the change waits for approval.
  planAdjusting,

  /// The partner has no plan yet.
  partnerNoPlan,

  /// I proposed a promise (bet) and wait for the partner to accept.
  waitingPromiseAccept,

  /// A promise (bet) was settled.
  promiseResult,

  /// Anything else: show the card's own header text.
  fallback,
}

/// The header kind for a manager card in [state].
ManagerCardHeader managerCardHeaderFor(HomeCardState state) {
  switch (state) {
    case HomeCardState.partnerTodayComplete:
      return ManagerCardHeader.partnerTodayComplete;
    case HomeCardState.partnerAction:
      return ManagerCardHeader.partnerAction;
    case HomeCardState.partnerPlanCreate:
      return ManagerCardHeader.planProposed;
    case HomeCardState.partnerPlanModify:
      return ManagerCardHeader.planAdjusting;
    case HomeCardState.partnerNoPlan:
      return ManagerCardHeader.partnerNoPlan;
    case HomeCardState.partnerPromiseProposed:
      return ManagerCardHeader.waitingPromiseAccept;
    case HomeCardState.promiseSettled:
      return ManagerCardHeader.promiseResult;
    default:
      return ManagerCardHeader.fallback;
  }
}

/// Whether a manager card shows the 조정하기 / 승인 buttons.
///
/// The repository only emits these states for a plan that waits for the
/// partner's approval, so the state alone decides it.
bool showsPlanApprovalActions(HomeCardState state) {
  return state == HomeCardState.partnerPlanCreate ||
      state == HomeCardState.partnerPlanModify;
}

/// The colour treatment of a card's time chip.
///
/// An overdue card is always [TimeChipType.past]; any other card that shows a
/// chip is [TimeChipType.upcoming]. [hasChipText] is false when the card shows
/// no chip at all (then there is no type either).
TimeChipType? timeChipTypeFor(
  HomeCardState state, {
  required bool hasChipText,
}) {
  if (state == HomeCardState.overdue) return TimeChipType.past;
  if (!hasChipText) return null;
  return TimeChipType.upcoming;
}

/// Whether a card of mine shows the "오늘 {운동} 했어?" check-in hero (with
/// 📸 인증샷 찍기 / 사진 없이 했어 / 오늘은 쉴게).
///
/// It is shown all day for a promise scheduled today that has no record yet —
/// a 22:00 promise asks from the morning on. This is deliberately separate
/// from `RealRecordRepository.isDueNowItem`, which still decides nowAction vs
/// nextAction (time chip, ordering, notification targeting): a nextAction card
/// shows the hero too.
///
/// - nowAction / nextAction / overdue: the plan has an item scheduled on
///   [now]'s weekday and nothing (done, skipped, rested) recorded today.
/// - poked: a knock asks about today regardless of the schedule, as long as
///   nothing is recorded yet.
bool showsTodayCheckInHero(
  HomeCardState state,
  Plan? plan, {
  required DateTime now,
}) {
  if (plan == null || plan.id == null) return false;
  switch (state) {
    case HomeCardState.nowAction:
    case HomeCardState.nextAction:
    case HomeCardState.overdue:
      if (!plan.items.any((item) => item.days.contains(now.weekday))) {
        return false;
      }
      return !_isRecordedOn(plan, now);
    case HomeCardState.poked:
      return !_isRecordedOn(plan, now);
    default:
      return false;
  }
}

bool _isRecordedOn(Plan plan, DateTime day) {
  bool has(List<DateTime> dates) => dates.any(
    (d) => d.year == day.year && d.month == day.month && d.day == day.day,
  );
  return has(plan.completedDates) ||
      has(plan.skippedDates) ||
      has(plan.restedDates);
}

bool _isSameDay(DateTime? a, DateTime b) =>
    a != null && a.year == b.year && a.month == b.month && a.day == b.day;

/// Whether [plan]'s owner was already knocked (똑똑) today. One knock per
/// promise per day: the button is disabled after it (the server rate-limits
/// too).
bool knockedToday(Plan? plan, {required DateTime now}) =>
    _isSameDay(plan?.lastPokeAt, now);

/// Whether my card for [plan] offers the one-tap replies to a knock
/// (지금 간다 🏃 / 오늘은 봐줘 🙏): my partner knocked today, there is a partner
/// to answer, and nothing is recorded today yet. Stays after the knock is
/// auto-acknowledged; the caller hides it once a reply was sent.
bool showsPokeReplies(Plan? plan, {required DateTime now}) {
  if (plan == null || plan.id == null || plan.managerId == null) return false;
  if (!knockedToday(plan, now: now)) return false;
  return !_isRecordedOn(plan, now);
}

/// Whether a partner card leads with 응원 보내기 and keeps 똑똑 second: the
/// partner's missed workout was auto-forwarded to me (spec §4.6).
bool leadsWithCheer(HomeCardState state, {required bool hasMissedNotice}) =>
    state == HomeCardState.partnerPoke && hasMissedNotice;

/// The time chip of an overdue card: how late it really is ("40분 지남",
/// "15시간 지남") — the hero stays up all day, so a fixed "조금 전" was wrong
/// by evening. Without a deadline: "지나갔어요".
String overdueTimeChipText(
  AppLocalizations l10n,
  Plan? plan, {
  required DateTime now,
}) {
  for (final item in plan?.items ?? const <PlanItem>[]) {
    final nt = item.notificationTime;
    if (nt == null || nt.type == 'none') continue;
    final due = DateTime(now.year, now.month, now.day, nt.hour, nt.minute);
    final late = now.difference(due);
    if (late.isNegative) return l10n.timeChipPassed;
    if (late.inMinutes < 60) {
      return l10n.timeChipMinutesAgo(late.inMinutes < 1 ? 1 : late.inMinutes);
    }
    return l10n.timeChipHoursAgo(late.inHours);
  }
  return l10n.timeChipPassed;
}
