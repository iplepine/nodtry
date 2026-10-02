import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';
import '../models/promise_model.dart';
import '../models/proof_photo.dart';
import '../utils/context_free_l10n.dart';
import '../utils/error_reporter.dart';
import 'proof_photo_storage.dart';
import 'record_repository.dart';

import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import '../models/relation_model.dart';

/// HomeCardModel.headerMessage 텍스트를 현재 앱 언어에 맞춰 반환.
/// Why: repository는 BuildContext 밖에서 동작하므로 ARB 문구를
/// [contextFreeL10n]으로 찾는다. 설정에서 고른 언어가 OS 언어보다 우선한다.
///
/// Lines that name the partner use the generic label here; the cards put the
/// nickname in (the repository doesn't know it).
String _headerMessage(String key) {
  final l10n = contextFreeL10n();
  switch (key) {
    case 'allDoneToday':
      return l10n.nowHeaderTodayAllDone;
    case 'gotMessage':
      return l10n.nowHeaderConfirmAndPull(l10n.partnerFallbackLabelStart);
    case 'newPlanProposed':
      return l10n.nowPartnerProposed(l10n.partnerFallbackLabelStart);
    case 'waitingPromiseAccept':
      return l10n.nowHeaderWaitingAccept;
    case 'promiseResult':
      return l10n.nowHeaderPromiseResult;
    case 'partnerRequestedAdjust':
      return l10n.nowHeaderPartnerAskedAdjust;
    case 'promiseProposalArrived':
      return l10n.nowHeaderPromiseProposed;
    case 'settlementNeeded':
      return l10n.nowHeaderSettlementNeeded;
    case 'pokeWaiting':
      return l10n.nowHeaderPokeWaiting;
    case 'todayMissed':
      return l10n.nowHeaderMissedNotice(l10n.partnerFallbackLabel);
    case 'waitingForPromise':
      return l10n.nowHeaderWaiting(l10n.partnerFallbackLabel);
    case 'missedAppeared':
      return l10n.nowHeaderPartnerMissed(l10n.partnerFallbackLabelStart);
    case 'pokeReadyTurn':
      return l10n.nowHeaderPokeTurn;
    default:
      return key;
  }
}

/// Default knock message stored on a plan when the sender passes none. It is
/// read by the *partner*, whose language we don't know, so it stays Korean
/// (the primary market) and partner-to-partner 반말, with no partner label.
const String kDefaultPlanPokeMessage = '똑똑! 오늘 약속 기다리고 있어';

/// Default knock message for a partner who has no promise yet.
const String kDefaultUserPokeMessage = '똑똑! 운동 약속 하나 걸어 줘';

/// `cheers.reactionType` of a one-tap answer to a knock (spec §9). The
/// server pushes it as `poke_reply`; older apps ignore unknown reactions.
const String kPokeReplyReactionType = 'reply';

/// Older app versions stored knock messages that name the retired
/// "실천 메이트" role. Show the current default header instead of those.
@visibleForTesting
String pokeHeaderFor(String? storedMessage) {
  final message = storedMessage?.trim();
  if (message == null || message.isEmpty || message.contains('실천 메이트')) {
    return _headerMessage('pokeWaiting');
  }
  return message;
}

/// Neutral title for a plan without one (it may be a legacy non-workout plan).
String _untitledPlanTitle() => contextFreeL10n().promiseUntitledFallback;

/// `plans.lastUpdatedBy` for a manager assigned because the couple linked
/// (same value as the server's onRelationCreated).
const String kSystemLinkUpdater = 'system_link';

/// `managerId` to stamp on a new action of the plan [planData]: the plan's
/// manager, or null (then the field is left out and the server stamps it).
/// firestore rules accept a stamp only when it equals the plan's stored
/// `managerId`.
@visibleForTesting
String? actionManagerStampFor(Map<String, dynamic>? planData) {
  final managerId = planData?['managerId'];
  return managerId is String && managerId.isNotEmpty ? managerId : null;
}

/// 실제 데이터 저장소 구현체 (Firestore 연동 예정)
///
/// Every read is participant-scoped, so it is allowed by both firestore.rules
/// and the staged firestore.rules.next (docs/operations/SECURITY_RULES.md,
/// "읽기 축소"):
///   - plans: `userId == me`, `managerId == me`, both OR-ed, or a partner's
///     as `userId == partner && managerId == me`;
///   - actions: `userId == me`, or a partner's as `managerId == me` (+
///     `userId` / `planId`); a single action by id;
///   - relations: `executorId == me` / `managerId == me`.
/// A partner's plans I don't manage (and their actions) are not shown.
/// Actions the app creates carry `managerId` = the plan's manager.
class RealRecordRepository implements RecordRepository {
  /// [firestore], [auth] and [proofStorage] are injectable for tests;
  /// production code uses the default Firebase instances. [proofUploadTimeout]
  /// bounds a proof-photo upload before the record is saved without it.
  RealRecordRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ProofPhotoStorage? proofStorage,
    Duration proofUploadTimeout = kProofUploadTimeout,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _proofStorage = proofStorage ?? FirebaseProofPhotoStorage(),
       _proofUploadTimeout = proofUploadTimeout;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ProofPhotoStorage _proofStorage;
  final Duration _proofUploadTimeout;

  /// [userId]'s plans that I may read: all of my own, or — for my partner —
  /// only the ones I manage (`userId == partner && managerId == me`; a query
  /// on the partner's uid alone is denied under firestore.rules.next).
  Query<Map<String, dynamic>> _readablePlansOf(String userId) {
    final plans = _firestore
        .collection('plans')
        .where('userId', isEqualTo: userId);
    final me = _auth.currentUser?.uid;
    if (me == null || me == userId) return plans;
    return plans.where('managerId', isEqualTo: me);
  }

  /// [userId]'s actions that I may list: all of my own, or my partner's that
  /// are shared with me (`userId == partner && managerId == me`), newest
  /// first.
  Query<Map<String, dynamic>> _readableActionsOf(String userId) {
    final me = _auth.currentUser?.uid;
    var actions = _firestore
        .collection('actions')
        .where('userId', isEqualTo: userId);
    if (me != null && me != userId) {
      actions = actions.where('managerId', isEqualTo: me);
    }
    return actions.orderBy('date', descending: true);
  }

  @override
  Stream<List<HomeCardModel>> getHomeCardStatesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([
        const HomeCardModel(state: HomeCardState.emptyPlan),
      ]);
    }

    final plansStream = _firestore
        .collection('plans')
        .where(
          Filter.or(
            Filter('userId', isEqualTo: user.uid),
            Filter('managerId', isEqualTo: user.uid),
          ),
        )
        .snapshots(includeMetadataChanges: true);

    final relationsStream = _firestore
        .collection('relations')
        .where(
          Filter.or(
            Filter('executorId', isEqualTo: user.uid),
            Filter('managerId', isEqualTo: user.uid),
          ),
        )
        .snapshots();

    return Rx.combineLatest2(plansStream, relationsStream, (
      QuerySnapshot planSnapshot,
      QuerySnapshot relationSnapshot,
    ) {
      final plans = planSnapshot.docs
          .map(
            (doc) => Plan.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .where(
            (p) =>
                p.state == PlanState.active ||
                p.state == PlanState.pendingApproval ||
                p.state == PlanState.completed ||
                p.state == PlanState.rejected ||
                p.promise?.status == PromiseStatus.settled,
          )
          .toList();

      final relations = relationSnapshot.docs
          .map((doc) => RelationModel.fromFirestore(doc))
          .toList();

      return _processPlans(plans, user.uid, relations: relations);
    }).doOnError((e, s) {
      debugPrint('[RealRecordRepository] Stream Error: $e');
    });
  }

  /// 예정시각이 이 분(minute) 이내로 다가온 항목만 "지금 실천(nowAction)"으로 띄운다.
  /// 그보다 먼 항목은 nextAction(이따)으로 분류해 불필요한 즉시 압박을 줄인다.
  /// 0으로 두면 "예정시각 정각 이후에만 nowAction"이 된다.
  static const int nowActionLeadWindowMinutes = 60;

  /// 오늘 남은(미처리) 항목이 지금(nowAction) 카드로 떠야 하는지 판단한다.
  /// - [hasTime]가 false(시간 미지정)면 항상 false → 오늘 아무 때나(저압력).
  /// - 시간이 있으면 예정시각이 now + lead window 이내일 때만 true(곧/지금).
  @visibleForTesting
  static bool isDueNowItem({
    required bool hasTime,
    required int timeInMin,
    required int nowInMinutes,
    int leadWindowMinutes = nowActionLeadWindowMinutes,
  }) {
    if (!hasTime) return false;
    return timeInMin <= nowInMinutes + leadWindowMinutes;
  }

  /// Extracted logic for processing plans into cards
  List<HomeCardModel> _processPlans(
    List<Plan> plans,
    String myUid, {
    List<RelationModel>? relations,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayWeekday = now.weekday; // 1=Mon, 7=Sun
    final nowInMinutes = now.hour * 60 + now.minute;

    final List<HomeCardModel> mineCards = [];
    final List<HomeCardModel> yoursCards = [];

    // --- Part 1: Partner Actions (Manager Role) -> Yours ---
    final managerPlans = plans.where((p) => p.managerId == myUid).toList();
    final managerPlansByPartnerUid = <String, List<Plan>>{};
    for (final plan in managerPlans) {
      managerPlansByPartnerUid.putIfAbsent(plan.userId, () => []).add(plan);
    }

    final partnersWithAllTodayPlansCompleted = <String>{};
    for (final entry in managerPlansByPartnerUid.entries) {
      final todayActivePlans = entry.value
          .where(
            (plan) =>
                plan.state == PlanState.active &&
                _isPlanActiveOn(plan, today) &&
                _hasScheduledItemOn(plan, todayWeekday),
          )
          .toList();
      if (todayActivePlans.isEmpty) continue;

      final allCompletedToday = todayActivePlans.every(
        (plan) => _containsDate(plan.completedDates, today),
      );
      if (!allCompletedToday) continue;

      final unverifiedCompletedPlans = todayActivePlans
          .where(
            (plan) =>
                _containsDate(plan.completedDates, today) &&
                !_containsDate(plan.verifiedDates, today),
          )
          .toList();
      if (unverifiedCompletedPlans.isEmpty) continue;

      partnersWithAllTodayPlansCompleted.add(entry.key);
      yoursCards.add(
        HomeCardModel(
          state: HomeCardState.partnerTodayComplete,
          plan: unverifiedCompletedPlans.first,
          partnerUid: entry.key,
          headerMessage: _headerMessage('allDoneToday'),
        ),
      );
    }

    for (var plan in managerPlans) {
      if (plan.state == PlanState.rejected) {
        continue;
      }

      final hasCompletedToday = _containsDate(plan.completedDates, today);
      final hasVerifiedToday = _containsDate(plan.verifiedDates, today);

      if (hasCompletedToday &&
          !hasVerifiedToday &&
          !partnersWithAllTodayPlansCompleted.contains(plan.userId)) {
        yoursCards.add(
          HomeCardModel(
            state: HomeCardState.partnerAction,
            plan: plan,
            partnerUid: plan.userId,
            headerMessage: _headerMessage('gotMessage'),
          ),
        );
      }

      if (plan.state == PlanState.pendingApproval) {
        yoursCards.add(
          HomeCardModel(
            state: HomeCardState.partnerPlanCreate, // 계획 제안
            plan: plan,
            partnerUid: plan.userId,
            headerMessage: _headerMessage('newPlanProposed'),
          ),
        );
      }

      // Promise: 내가 제안한 약속이 대기 중
      if (plan.promise != null &&
          plan.promise!.status == PromiseStatus.proposed &&
          plan.promise!.proposerId == myUid) {
        yoursCards.add(
          HomeCardModel(
            state: HomeCardState.partnerPromiseProposed,
            plan: plan,
            partnerUid: plan.userId,
            headerMessage: _headerMessage('waitingPromiseAccept'),
          ),
        );
      }

      // Promise: 정산 결과 (매니저 측). 본인이 이미 확인 처리한 카드는 숨긴다.
      if (plan.promise != null &&
          plan.promise!.status == PromiseStatus.settled &&
          !plan.promise!.isSettlementAcknowledgedBy(myUid)) {
        yoursCards.add(
          HomeCardModel(
            state: HomeCardState.promiseSettled,
            plan: plan,
            partnerUid: plan.userId,
            headerMessage: _headerMessage('promiseResult'),
          ),
        );
      }

      if (plan.state == PlanState.completed) {
        continue;
      }
    }

    // --- Part 2: My Actions (Executor Role) -> Mine ---
    final myPlans = plans.where((p) => p.userId == myUid);
    final List<({Plan plan, PlanItem item, int timeInMin, bool hasTime})>
    allTodayItems = [];
    bool hasAnyPlanToday = false;

    for (var plan in myPlans) {
      // 1. Rejected Check (Top Priority)
      if (plan.state == PlanState.rejected) {
        mineCards.add(
          HomeCardModel(
            state: HomeCardState.rejected,
            plan: plan,
            headerMessage: _headerMessage('partnerRequestedAdjust'),
          ),
        );
        continue; // Skip other checks for this plan
      }

      // Promise: 상대가 나에게 약속을 제안함 (수락/거절 필요)
      if (plan.promise != null &&
          plan.promise!.status == PromiseStatus.proposed &&
          plan.promise!.proposerId != myUid) {
        mineCards.add(
          HomeCardModel(
            state: HomeCardState.promiseProposed,
            plan: plan,
            headerMessage: _headerMessage('promiseProposalArrived'),
          ),
        );
      }

      // Promise: 정산 결과 (실행자 측). 본인이 확인하면 카드가 사라진다.
      if (plan.promise != null &&
          plan.promise!.status == PromiseStatus.settled &&
          !plan.promise!.isSettlementAcknowledgedBy(myUid)) {
        mineCards.add(
          HomeCardModel(
            state: HomeCardState.promiseSettled,
            plan: plan,
            headerMessage: _headerMessage('promiseResult'),
          ),
        );
      }

      if (plan.state == PlanState.completed) {
        if (plan.pilotNextPlanIntent == null) {
          mineCards.add(
            HomeCardModel(
              state: HomeCardState.pilotSettlement,
              plan: plan,
              headerMessage: _headerMessage('settlementNeeded'),
            ),
          );
        }
        continue;
      }

      if (now.isBefore(plan.startDate) || now.isAfter(plan.endDate)) {
        continue;
      }

      final isCompletedToday = plan.completedDates.any(
        (d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day,
      );
      final isSkippedToday = plan.skippedDates.any(
        (d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day,
      );
      final isRestedToday = plan.restedDates.any(
        (d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day,
      );
      final isHandledToday =
          isCompletedToday || isSkippedToday || isRestedToday;

      final todayItems = plan.items
          .where((item) => item.days.contains(todayWeekday))
          .toList();

      if (todayItems.isNotEmpty) {
        hasAnyPlanToday = true;
      }

      final hasActivePoke =
          _isSameDay(plan.lastPokeAt, today) &&
          !_isSameDay(plan.lastPokeAcknowledgedAt, today);
      final hasMissedNotice = _isSameDay(plan.lastMissedNotifiedAt, today);
      if (!isHandledToday && (hasActivePoke || hasMissedNotice)) {
        mineCards.add(
          HomeCardModel(
            state: HomeCardState.poked,
            plan: plan,
            headerMessage: hasActivePoke
                ? pokeHeaderFor(plan.lastPokeMessage)
                : _headerMessage('todayMissed'),
            // Shown because the partner was told about a missed day (no
            // knock): the card words it with the partner's name.
            hasMissedNotice: !hasActivePoke,
          ),
        );
      }

      if (isHandledToday) {
        continue;
      }

      for (var item in todayItems) {
        final time = item.notificationTime;
        // type 'none'(알림 시간 미지정)은 "오늘 아무 때나"로 본다.
        final hasTime = time != null && time.type != 'none';
        final timeInMin = hasTime
            ? (time.hour * 60 + time.minute)
            : (23 * 60 + 59);

        allTodayItems.add((
          plan: plan,
          item: item,
          timeInMin: timeInMin,
          hasTime: hasTime,
        ));
      }
    }

    // My Actions Processing
    if (allTodayItems.isNotEmpty) {
      allTodayItems.sort((a, b) => a.timeInMin.compareTo(b.timeInMin));

      final upcomingItems = allTodayItems
          .where((i) => i.timeInMin >= nowInMinutes)
          .toList();
      final pastItems = allTodayItems
          .where((i) => i.timeInMin < nowInMinutes)
          .toList();

      // 오늘 남은 항목을 시각 기준으로 둘로 나눈다.
      // - 예정시각이 곧(now + lead window 이내)이거나 시간 미지정이 아닌 것 → nowAction(지금 실천)
      // - 그보다 먼 항목 / 시간 미지정 항목 → nextAction(이따·아무 때나)
      // 아직 시간이 한참 남은 항목까지 "지금 실천"으로 띄워 "당장 해야 할 것 같은"
      // 압박을 주던 문제를 줄이기 위함이다.
      for (var upcoming in upcomingItems) {
        final isDue = isDueNowItem(
          hasTime: upcoming.hasTime,
          timeInMin: upcoming.timeInMin,
          nowInMinutes: nowInMinutes,
        );
        if (isDue) {
          final streak = upcoming.plan.currentStreak;
          mineCards.add(
            HomeCardModel(
              state: HomeCardState.nowAction,
              plan: _createSingleItemPlan(upcoming.plan, upcoming.item),
              streakCount: streak >= 2 ? streak : null,
            ),
          );
        } else {
          mineCards.add(
            HomeCardModel(
              state: HomeCardState.nextAction,
              plan: _createSingleItemPlan(upcoming.plan, upcoming.item),
            ),
          );
        }
      }

      // 지난 항목 (overdue): 최신순(가장 최근에 지난 것부터)으로 전체 노출.
      // UI 카드 캐러셀에서 같이 스와이프된다.
      final sortedPastItems = pastItems.reversed.toList();
      for (var past in sortedPastItems) {
        mineCards.add(
          HomeCardModel(
            state: HomeCardState.overdue,
            plan: _createSingleItemPlan(past.plan, past.item),
          ),
        );
      }
    }

    // --- Part 3: Partner No Plan Check / Poke Feature ---
    // 양방향 체크: Manager든 Executor든 파트너의 플랜 상태를 확인
    if (relations != null) {
      // 이미 체크한 파트너 중복 방지
      final checkedPartnerUids = <String>{};

      for (var relation in relations) {
        final String? partnerUid;
        if (relation.managerId == myUid) {
          partnerUid = relation.executorId;
        } else if (relation.executorId == myUid) {
          partnerUid = relation.managerId;
        } else {
          continue;
        }

        // 같은 파트너를 중복 체크하지 않음
        if (checkedPartnerUids.contains(partnerUid)) continue;
        checkedPartnerUids.add(partnerUid);

        final partnerPlans = plans.where((p) => p.userId == partnerUid);

        if (partnerPlans.isEmpty) {
          yoursCards.add(
            HomeCardModel(
              state: HomeCardState.partnerNoPlan,
              partnerUid: partnerUid,
              headerMessage: _headerMessage('waitingForPromise'),
            ),
          );
        } else {
          // Status H: 파트너가 오늘 해야 할 일이 있는데 아직 안 했을 때
          for (var plan in partnerPlans) {
            if (plan.state != PlanState.active) continue;

            final isCompletedToday = plan.completedDates.any(
              (d) =>
                  d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day,
            );
            final isSkippedToday = plan.skippedDates.any(
              (d) =>
                  d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day,
            );
            final isRestedToday = plan.restedDates.any(
              (d) =>
                  d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day,
            );
            final isRescuedToday = plan.rescuedDates.any(
              (d) =>
                  d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day,
            );
            final isHandledToday =
                isCompletedToday ||
                isSkippedToday ||
                isRestedToday ||
                isRescuedToday;
            final hasPokedToday = _isSameDay(plan.lastPokeAt, today);

            if (!isHandledToday && !hasPokedToday) {
              // 약속 시간이 10분 이상 지난 항목이 있어야 똑똑 노출
              // (아침부터 저녁 약속까지 종일 똑똑이 떠 있는 것을 방지)
              const pokeDelayMinutes = 10;
              // The same deadline the server's missed notice uses (the
              // reminder may fire early — alertOffset — or hourly).
              final hasOverdueTodayItem = plan.items.any((item) {
                if (!item.days.contains(todayWeekday)) return false;
                final deadline = item.notificationTime?.deadlineMinutes;
                if (deadline == null) return true;
                return nowInMinutes >= deadline + pokeDelayMinutes;
              });
              if (hasOverdueTodayItem) {
                final hasMissedNotice = _isSameDay(
                  plan.lastMissedNotifiedAt,
                  today,
                );
                // 파트너가 어제도 못 했는지 확인 (실천 인정 가능 여부)
                final yesterday = today.subtract(const Duration(days: 1));
                final missedYesterday =
                    !plan.completedDates.any(
                      (d) =>
                          d.year == yesterday.year &&
                          d.month == yesterday.month &&
                          d.day == yesterday.day,
                    ) &&
                    !plan.rescuedDates.any(
                      (d) =>
                          d.year == yesterday.year &&
                          d.month == yesterday.month &&
                          d.day == yesterday.day,
                    ) &&
                    !plan.restedDates.any(
                      (d) =>
                          d.year == yesterday.year &&
                          d.month == yesterday.month &&
                          d.day == yesterday.day,
                    );
                // 어제가 스케줄 날인 경우에만 rescue 가능
                final yesterdayScheduled = plan.items.any(
                  (item) => item.days.contains(yesterday.weekday),
                );

                yoursCards.add(
                  HomeCardModel(
                    state: HomeCardState.partnerPoke,
                    plan: plan,
                    partnerUid: partnerUid,
                    headerMessage: hasMissedNotice
                        ? _headerMessage('missedAppeared')
                        : _headerMessage('pokeReadyTurn'),
                    hasMissedNotice: hasMissedNotice,
                    canRescue: missedYesterday && yesterdayScheduled,
                  ),
                );
              }
            }
          }
        }
      }
    }

    // Fallback States for Mine
    if (mineCards.isEmpty) {
      if (myPlans.isEmpty) {
        // 아예 계획이 없음 -> EmptyPlan (CTA)
        mineCards.add(const HomeCardModel(state: HomeCardState.emptyPlan));
      } else if (hasAnyPlanToday) {
        // 오늘 계획은 있었는데 모두 완료함 -> TodayComplete
        // 오늘 일정이 있던 모든 플랜 중 완료된 것을 모두 수집해서
        // 체크리스트로 보여줄 수 있도록 completedPlans에 담는다.
        // state는 active 외에 pendingApproval 등도 올 수 있어 제한하지 않는다.
        // (메인 루프가 PlanState.completed/rejected는 이미 걸러냈으므로 안전하다.)
        final completedToday = myPlans
            .where(
              (p) =>
                  _hasScheduledItemOn(p, todayWeekday) &&
                  _isPlanActiveOn(p, today) &&
                  _containsDate(p.completedDates, today),
            )
            .toList();

        // 단일 플랜 케이스 호환: 기존 plan/streak 표시 로직을 유지한다.
        final headlinePlan =
            completedToday.firstOrNull ??
            myPlans.where((p) => p.state == PlanState.active).firstOrNull ??
            myPlans.firstOrNull;
        final streak = headlinePlan?.currentStreak ?? 0;
        mineCards.add(
          HomeCardModel(
            state: HomeCardState.todayComplete,
            plan: headlinePlan,
            streakCount: streak >= 2 ? streak : null,
            completedPlans: completedToday,
          ),
        );
      } else {
        // 오늘 해당되는 요일의 계획이 없음 -> TodayEmpty
        mineCards.add(const HomeCardModel(state: HomeCardState.todayEmpty));
      }
    }

    // Merge: Mine + Yours
    return [...mineCards, ...yoursCards];
  }

  @override
  Future<List<HomeCardModel>> getHomeCardStates() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [const HomeCardModel(state: HomeCardState.emptyPlan)];
    }

    try {
      final snapshot = await _firestore
          .collection('plans')
          .where('userId', isEqualTo: user.uid)
          .get();

      final plans = snapshot.docs
          .map((doc) => Plan.fromMap(doc.data(), doc.id))
          .where(
            (p) =>
                p.state == PlanState.active ||
                p.state == PlanState.pendingApproval ||
                p.state == PlanState.completed ||
                p.promise?.status == PromiseStatus.settled,
          )
          .toList();

      if (plans.isEmpty) {
        return [const HomeCardModel(state: HomeCardState.emptyPlan)];
      }

      return _processPlans(plans, user.uid);
    } catch (e) {
      debugPrint('[RealRecordRepository] Error fetching home cards: $e');
      return [const HomeCardModel(state: HomeCardState.emptyPlan)];
    }
  }

  @override
  Future<List<Plan>> getPlansByUserId(String userId) async {
    try {
      final snapshot = await _readablePlansOf(userId).get();

      return snapshot.docs
          .map((doc) => Plan.fromMap(doc.data(), doc.id))
          .where(
            (p) =>
                p.state == PlanState.active ||
                p.state == PlanState.pendingApproval,
          )
          .toList();
    } catch (e) {
      debugPrint(
        '[RealRecordRepository] Error fetching plans for user $userId: $e',
      );
      return [];
    }
  }

  @override
  Stream<List<Plan>> getPlansByUserIdStream(String userId) {
    return _readablePlansOf(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Plan.fromMap(doc.data(), doc.id))
          .where(
            (p) =>
                p.state == PlanState.active ||
                p.state == PlanState.pendingApproval,
          )
          .toList();
    });
  }

  @override
  Stream<List<Plan>> getAllPlansByUserIdStream(String userId) {
    return _readablePlansOf(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Plan.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// 특정 아이템 하나만 포함된 임시 Plan 객체 생성 (UI 노출용)
  Plan _createSingleItemPlan(Plan original, PlanItem item) {
    return Plan(
      id: original.id,
      userId: original.userId,
      managerId: original.managerId,
      startDate: original.startDate,
      endDate: original.endDate,
      state: original.state,
      items: [item],
      createdAt: original.createdAt,
      completedDates: original.completedDates,
      skippedDates: original.skippedDates,
      verifiedDates: original.verifiedDates,
      rescuedDates: original.rescuedDates,
      restedDates: original.restedDates,
      lastCheerMessage: original.lastCheerMessage,
      lastCheerType: original.lastCheerType,
      lastCheerAt: original.lastCheerAt,
      lastPokeMessage: original.lastPokeMessage,
      lastPokeAt: original.lastPokeAt,
      lastPokeAcknowledgedAt: original.lastPokeAcknowledgedAt,
      lastMissedNotifiedAt: original.lastMissedNotifiedAt,
      lastMissedItemTitle: original.lastMissedItemTitle,
      lastActionNote: original.lastActionNote,
      lastComment: original.lastComment,
      lastUpdatedBy: original.lastUpdatedBy,
      pilotNextPlanIntent: original.pilotNextPlanIntent,
      pilotExitReason: original.pilotExitReason,
      pilotSettledAt: original.pilotSettledAt,
      promise: original.promise,
      lastActionId: original.lastActionId,
      workoutType: original.workoutType,
      lastProofPhotoPath: original.lastProofPhotoPath,
      lastProofAt: original.lastProofAt,
    );
  }

  HistoryItem _mapHistoryItem(
    Map<String, dynamic> data,
    String id,
    String myUid,
  ) {
    final item = HistoryItem.fromMap(data, id);
    final verifiedBy = data['verifiedBy'] as String?;
    final isMine = item.executorId == myUid;

    return item.copyWith(
      isVerifiedByPartner:
          isMine && verifiedBy != null && verifiedBy.isNotEmpty,
      isVerifiedByMe: !isMine && verifiedBy == myUid,
    );
  }

  bool _isSameDay(DateTime? value, DateTime target) {
    if (value == null) return false;

    return value.year == target.year &&
        value.month == target.month &&
        value.day == target.day;
  }

  bool _containsDate(List<DateTime> values, DateTime target) {
    return values.any((value) => _isSameDay(value, target));
  }

  bool _hasScheduledItemOn(Plan plan, int weekday) {
    return plan.items.any((item) => item.days.contains(weekday));
  }

  bool _isPlanActiveOn(Plan plan, DateTime target) {
    final targetDate = DateTime(target.year, target.month, target.day);
    final startDate = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final endDate = DateTime(
      plan.endDate.year,
      plan.endDate.month,
      plan.endDate.day,
    );

    return !targetDate.isBefore(startDate) && !targetDate.isAfter(endDate);
  }

  @override
  Future<List<HistoryItem>> getHistoryItems() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('actions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _mapHistoryItem(doc.data(), doc.id, user.uid))
          .toList();
    } catch (e) {
      debugPrint('[RealRecordRepository] Error fetching history items: $e');
      return [];
    }
  }

  @override
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // One query per person, merged: `userId == me` for mine and
    // `userId == partner && managerId == me` for my partner's (a single
    // `userId in [me, partner]` query is denied under firestore.rules.next).
    final owners = (userIds == null || userIds.isEmpty)
        ? [user.uid]
        : userIds.toSet().toList();
    final perOwner = [
      for (final owner in owners)
        _withoutPartnerFailure(
          _readableActionsOf(owner).snapshots().map(
            (snapshot) => [
              for (final doc in snapshot.docs)
                _mapHistoryItem(doc.data(), doc.id, user.uid),
            ],
          ),
          isPartner: owner != user.uid,
        ),
    ];
    if (perOwner.length == 1) return perOwner.single;
    return Rx.combineLatestList(perOwner).map(_mergeNewestFirst);
  }

  /// A failing partner query (e.g. its composite index still building) must
  /// not take my own records down with it: it is reported and counts as
  /// empty. My own query's errors still reach the screen.
  Stream<List<HistoryItem>> _withoutPartnerFailure(
    Stream<List<HistoryItem>> items, {
    required bool isPartner,
  }) {
    if (!isPartner) return items;
    return items.onErrorReturnWith((Object e, StackTrace s) {
      ErrorReporter.record(e, s, reason: 'partnerHistory');
      return const <HistoryItem>[];
    });
  }

  @override
  Stream<List<HistoryItem>> getHistoryItemsByPlanIdStream(
    String planId, {
    String? ownerId,
  }) {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return Stream.value([]);

    // My plan: `planId == X && userId == me`. My partner's plan:
    // `planId == X && managerId == me` (only while I manage it). A query on
    // planId alone is denied under firestore.rules.next. Without [ownerId]
    // both run and merge (one of them is always empty).
    Stream<List<HistoryItem>> timeline(String field) => _firestore
        .collection('actions')
        .where('planId', isEqualTo: planId)
        .where(field, isEqualTo: myUid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              _mapHistoryItem(doc.data(), doc.id, myUid),
          ],
        );

    if (ownerId == myUid) return timeline('userId');
    if (ownerId != null) return timeline('managerId');
    return Rx.combineLatest2(
      timeline('userId'),
      timeline('managerId'),
      (List<HistoryItem> mine, List<HistoryItem> partners) =>
          _mergeNewestFirst([mine, partners]),
    );
  }

  /// Concatenates per-query results into one feed, newest first.
  static List<HistoryItem> _mergeNewestFirst(List<List<HistoryItem>> lists) {
    final seen = <String>{};
    final merged = [
      for (final list in lists)
        for (final item in list)
          if (seen.add(item.id)) item,
    ];
    merged.sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  @override
  Future<String> createPlan(Plan plan) async {
    debugPrint(
      '[RealRecordRepository] createPlan called. Plan: ${plan.toMap()}',
    );
    final collection = _firestore.collection('plans');
    try {
      if (plan.id == null || plan.id!.isEmpty) {
        final docRef = collection.doc();
        debugPrint(
          '[RealRecordRepository] Creating new document with ID: ${docRef.id}',
        );
        await docRef.set(plan.toMap());
        debugPrint('[RealRecordRepository] Document created successfully.');
        return docRef.id;
      } else {
        // Technically create should be fresh, but if ID provided, treat as create
        debugPrint(
          '[RealRecordRepository] Creating with existing ID: ${plan.id}',
        );
        await collection.doc(plan.id).set(plan.toMap());
        return plan.id!;
      }
    } catch (e) {
      debugPrint('[RealRecordRepository] Error creating plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePlan(Plan plan) async {
    debugPrint('[RealRecordRepository] updatePlan called. Plan ID: ${plan.id}');
    if (plan.id == null) {
      throw ArgumentError('Cannot update plan without ID');
    }
    try {
      await _firestore.collection('plans').doc(plan.id).update(plan.toMap());
      debugPrint('[RealRecordRepository] Plan updated successfully.');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error updating plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePlanItems(String planId, List<PlanItem> items) async {
    final user = _auth.currentUser;
    await _firestore.collection('plans').doc(planId).update({
      'items': items.map((item) => item.toMap()).toList(),
      if (user != null) 'lastUpdatedBy': user.uid,
    });
  }

  @override
  Future<void> deletePlan(String planId) async {
    debugPrint('[RealRecordRepository] deletePlan called. Plan ID: $planId');
    try {
      await _firestore.collection('plans').doc(planId).delete();
      debugPrint('[RealRecordRepository] Plan deleted successfully.');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error deleting plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> pokePartner(String planId, {String? message}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      await _firestore.collection('plans').doc(planId).update({
        'lastPokeAt': Timestamp.fromDate(now),
        'lastPokeMessage': message ?? kDefaultPlanPokeMessage,
        'lastPokeAcknowledgedAt': FieldValue.delete(),
        'lastUpdatedBy': user.uid,
      });
      debugPrint('[RealRecordRepository] Poked partner for plan $planId');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error poking partner: $e');
      rethrow;
    }
  }

  @override
  Future<void> acknowledgePoke(String planId) async {
    try {
      await _firestore.collection('plans').doc(planId).update({
        'lastPokeAcknowledgedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[RealRecordRepository] Acknowledged poke for plan $planId');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error acknowledging poke: $e');
      rethrow;
    }
  }

  @override
  Future<void> stopPlan(String planId) async {
    debugPrint('[RealRecordRepository] stopPlan called. Plan ID: $planId');
    try {
      await _firestore.collection('plans').doc(planId).update({
        'state': PlanState.stopped.toMap(),
      });
      await settlePromise(planId);
      debugPrint('[RealRecordRepository] Plan stopped successfully.');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error stopping plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePlansByUserId(String uid) async {
    try {
      final plans = await _firestore
          .collection('plans')
          .where('userId', isEqualTo: uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in plans.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint(
        '[RealRecordRepository] Deleted ${plans.size} plans for user $uid',
      );
    } catch (e) {
      debugPrint('[RealRecordRepository] Error deleting plans: $e');
      rethrow;
    }
  }

  @override
  Future<void> reconcilePlan(String planId, HistoryStatus status) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 1. Update Plan's completedDates based on status
      if (status == HistoryStatus.done ||
          status == HistoryStatus.actuallyDone) {
        // Add to completedDates
        await _firestore.collection('plans').doc(planId).update({
          'completedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
        });
      } else {
        // Remove from completedDates (Requires reading first or tricky arrayRemove)
        // ArrayRemove requires exact element match. Since we use Timestamp.fromDate(now)
        // which includes time, we might have issues if we don't know the exact time it was added.
        // But for "Today" check, we essentially just need to ensure *some* timestamp for today exists or not.
        // Ideally, completedDates should be normalized to midnight to make removal easy.
        // For now, let's assume we read the plan, filter out today's dates, and update.

        final planDoc = await _firestore.collection('plans').doc(planId).get();
        if (planDoc.exists) {
          final data = planDoc.data();
          final dates = (data?['completedDates'] as List<dynamic>? ?? [])
              .map((t) => (t as Timestamp).toDate())
              .toList();

          // Remove dates that match today
          dates.removeWhere(
            (d) =>
                d.year == today.year &&
                d.month == today.month &&
                d.day == today.day,
          );

          await _firestore.collection('plans').doc(planId).update({
            'completedDates': dates.map((d) => Timestamp.fromDate(d)).toList(),
          });
        }
      }

      // 2. Add History Entry (Correction)
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final planTitle =
          (planDoc.data()?['items'] as List?)?.firstOrNull?['title'] ??
          _untitledPlanTitle();

      String typeStr;
      switch (status) {
        case HistoryStatus.done:
          typeStr = 'done';
          break;
        case HistoryStatus.actuallyDone:
          typeStr = 'done';
          break;
        case HistoryStatus.rested:
          typeStr = 'rested';
          break;
        case HistoryStatus.skipped:
          typeStr = 'skipped';
          break;
        case HistoryStatus.rescued:
          typeStr = 'rescued';
          break;
        default:
          typeStr = 'skipped';
          break;
      }

      await _addAction({
        'userId': user.uid,
        'planId': planId,
        'date': Timestamp.fromDate(now),
        'type': typeStr,
        'title': planTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'isReconciled': true,
      }, managerId: actionManagerStampFor(planDoc.data()));
    } catch (e) {
      debugPrint('[RealRecordRepository] Error reconciling plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyHistoryItem(
    String historyId, {
    String? message,
    String? reaction,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Verify atomically and idempotently. Two managers (or a double-tap)
      // could otherwise race: the old read-then-write could overwrite a
      // different verifier and double-fire the "verified" notification. The
      // transaction reads the action first, bails if it's already verified, and
      // syncs the plan's verifiedDates in the same atomic unit.
      await _firestore.runTransaction((tx) async {
        final actionRef = _firestore.collection('actions').doc(historyId);
        final snap = await tx.get(actionRef);
        if (!snap.exists) return;

        final data = snap.data()!;
        final existingVerifier = data['verifiedBy'] as String?;
        if (existingVerifier != null && existingVerifier.isNotEmpty) {
          return; // already verified — idempotent no-op
        }

        final updateData = <String, dynamic>{
          'verifiedBy': user.uid,
          'verifiedAt': FieldValue.serverTimestamp(),
        };
        if (message != null && message.isNotEmpty) {
          updateData['comment'] = message;
        }
        if (reaction != null && reaction.isNotEmpty) {
          updateData['reaction'] = reaction;
        }
        tx.update(actionRef, updateData);

        // Sync verifiedDates on the plan for real-time Home Card state.
        final planId = data['planId'] as String?;
        final date = (data['date'] as Timestamp?)?.toDate();
        if (planId != null && date != null) {
          final planUpdate = <String, dynamic>{
            'verifiedDates': FieldValue.arrayUnion([Timestamp.fromDate(date)]),
            // onPlanUpdated only sends the "인정" push when the manager is the
            // last writer — without this a 기록-tab 인정 never notified anyone.
            'lastUpdatedBy': user.uid,
          };
          final now = DateTime.now();
          final isToday =
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          final ownerId = data['userId'] as String?;
          if (isToday &&
              ownerId != null &&
              reaction != null &&
              _isReaction(reaction)) {
            // Today's record: the same 인정 as the Now tab's one tap. The
            // owner's card shows today's emoji/한마디 from the plan's
            // lastCheer* fields, and the cheers doc carries the push with the
            // actual emoji and message (onPlanUpdated stays silent because
            // lastCheerAt changes — one 인정, one push). A past day's 인정
            // leaves today's card state alone.
            final hasMessage = message != null && message.isNotEmpty;
            planUpdate.addAll({
              'lastCheerType': reaction,
              'lastCheerAt': Timestamp.fromDate(now),
              'lastCheerMessage': hasMessage ? message : FieldValue.delete(),
              'lastComment': hasMessage ? message : FieldValue.delete(),
            });
            tx.set(_firestore.collection('cheers').doc(), {
              'fromUserId': user.uid,
              'toUserId': ownerId,
              'planId': planId,
              'reactionType': reaction,
              'createdAt': FieldValue.serverTimestamp(),
              if (hasMessage) 'message': message,
            });
          }
          tx.update(_firestore.collection('plans').doc(planId), planUpdate);
        }
      });
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'verifyHistoryItem');
      rethrow;
    }
  }

  @override
  Future<ProofCompletionResult> reportCompletion(
    String planId, {
    String? note,
    ProofPhotoUpload? photo,
  }) async {
    debugPrint('[RealRecordRepository] reportCompletion for $planId');
    final user = _auth.currentUser;
    if (user == null) {
      return ProofCompletionResult(attemptedSource: photo?.source);
    }

    try {
      final now = DateTime.now();
      final planRef = _firestore.collection('plans').doc(planId);
      // Allocate the action id up front so the plan can point at it
      // (lastActionId), the photo can be stored under it, and both documents
      // land in one atomic batch.
      final actionRef = _firestore.collection('actions').doc();

      // Plan title is denormalized onto the action for the history feed.
      final planDoc = await planRef.get();
      final planData = planDoc.data();
      final planTitle =
          (planData?['items'] as List?)?.firstOrNull?['title'] ??
          _untitledPlanTitle();

      // Upload before writing anything, so the partner never gets a record that
      // points at a photo that isn't there. A failed or slow upload (basement
      // gyms are often offline) must not cost the user their record: save it
      // without the photo instead.
      String? photoPath;
      if (photo != null) {
        final path = proofPhotoPathFor(
          ownerUid: user.uid,
          planId: planId,
          actionId: actionRef.id,
        );
        try {
          await _proofStorage.upload(
            path,
            photo.bytes,
            timeout: _proofUploadTimeout,
          );
          photoPath = path;
        } catch (e, s) {
          debugPrint('[RealRecordRepository] proof upload failed: $e');
          ErrorReporter.record(e, s, reason: 'proofUpload');
          // The record is saved without the photo, so nothing will point at
          // an object that may have landed anyway (a late cancel): delete it,
          // best-effort, so the partner can't read a photo the user was told
          // wasn't sent and can't delete.
          unawaited(
            _proofStorage.delete(path).catchError((Object e) {
              debugPrint('[RealRecordRepository] orphan proof cleanup: $e');
            }),
          );
        }
      }

      final proofAt = Timestamp.fromDate(now);
      final managerId = actionManagerStampFor(planData);
      WriteBatch recordBatch({required bool stamped}) {
        final batch = _firestore.batch();
        batch.update(planRef, {
          'completedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
          'lastActionNote': note,
          'lastActionId': actionRef.id,
          // Only the Storage path is stored — never a download URL (the path
          // is useless without passing the Storage rules).
          if (photoPath != null) 'lastProofPhotoPath': photoPath,
          if (photoPath != null) 'lastProofAt': proofAt,
        });
        batch.set(actionRef, {
          'userId': user.uid,
          'planId': planId,
          'date': Timestamp.fromDate(now),
          'type': 'done', // HistoryStatus.done
          'title': planTitle,
          'note': note, // 저장
          'createdAt': FieldValue.serverTimestamp(),
          // Shares the record with the partner right away (rules.next lists
          // a partner's actions through it); the server keeps it in sync.
          if (stamped && managerId != null) 'managerId': managerId,
          if (photoPath != null) 'proofPhotoPath': photoPath,
          if (photoPath != null) 'proofSource': photo!.source.id,
          if (photoPath != null && photo!.takenAt != null)
            'proofTakenAt': Timestamp.fromDate(photo.takenAt!),
        });
        return batch;
      }

      // The write is applied locally right away (the plan stream updates), but
      // `commit()` only resolves on the server's ack — never, in a gym with no
      // signal. Don't hold the user (and today's reminder skip) on it: after a
      // short wait the record counts as queued and syncs on reconnect.
      final queued = await _commitOrQueue(
        recordBatch(stamped: true),
        reason: 'reportCompletionLateCommit',
        unstamped: managerId == null ? null : () => recordBatch(stamped: false),
      );
      debugPrint(
        '[RealRecordRepository] Action added with ID: ${actionRef.id}'
        '${queued ? ' (queued offline)' : ''}',
      );
      return ProofCompletionResult(
        actionId: actionRef.id,
        photoPath: photoPath,
        attemptedSource: photo?.source,
        queued: queued,
      );
    } catch (e) {
      debugPrint('[RealRecordRepository] !!! Error reporting completion: $e');
      rethrow;
    }
  }

  /// How long a record waits for the server's ack before it counts as queued.
  static const Duration kCommitAckTimeout = Duration(seconds: 3);

  /// Commits [batch]; returns true when the server didn't confirm within
  /// [kCommitAckTimeout] (offline — the write is applied locally and syncs
  /// later). A late failure is reported, not thrown.
  ///
  /// [unstamped] rebuilds the batch without the action's `managerId`: when
  /// the rules deny the stamped one (the plan's manager changed after it was
  /// read — e.g. the couple unlinked while this device was offline), the
  /// record is saved without the stamp instead of being lost.
  Future<bool> _commitOrQueue(
    WriteBatch batch, {
    required String reason,
    WriteBatch Function()? unstamped,
  }) async {
    var commit = batch.commit();
    if (unstamped != null) {
      commit = commit.catchError(
        (Object _) => unstamped().commit(),
        test: _isPermissionDenied,
      );
    }
    var queued = false;
    await commit.timeout(
      kCommitAckTimeout,
      onTimeout: () {
        queued = true;
      },
    );
    if (queued) {
      unawaited(
        commit.catchError((Object e, StackTrace s) {
          ErrorReporter.record(e, s, reason: reason);
        }),
      );
    }
    return queued;
  }

  static bool _isPermissionDenied(Object error) =>
      error is FirebaseException && error.code == 'permission-denied';

  /// Adds a new action, stamped with [managerId] (the plan's manager, see
  /// [actionManagerStampFor]) so the partner sees it right away. If the rules
  /// deny the stamp (the plan's manager changed after the plan was read), the
  /// record is saved without it; the server stamps it.
  Future<void> _addAction(
    Map<String, dynamic> data, {
    required String? managerId,
  }) async {
    final actions = _firestore.collection('actions');
    if (managerId == null) {
      await actions.add(data);
      return;
    }
    try {
      await actions.add({...data, 'managerId': managerId});
    } on FirebaseException catch (e) {
      if (!_isPermissionDenied(e)) rethrow;
      debugPrint('[RealRecordRepository] managerId stamp refused, retrying');
      await actions.add(data);
    }
  }

  @override
  Future<HistoryItem?> getHistoryItem(String actionId) async {
    final snap = await _firestore.collection('actions').doc(actionId).get();
    final data = snap.data();
    if (data == null) return null;
    return _mapHistoryItem(data, snap.id, _auth.currentUser?.uid ?? '');
  }

  @override
  Future<Uint8List?> downloadProofPhoto(String path) {
    return _proofStorage.download(path);
  }

  @override
  Future<void> deleteProofPhoto(String photoPath) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final parts = parseProofPhotoPath(photoPath);
    // Only the owner's own photos, and only well-formed proof paths.
    if (parts == null || parts.ownerUid != user.uid) {
      throw ArgumentError.value(photoPath, 'photoPath', 'not your proof photo');
    }

    try {
      // References first, then the object: if the reads or the commit fail,
      // nothing is deleted and the user can retry; the other order left both
      // documents pointing at a photo that was gone (a broken tile for the
      // partner).
      final actionRef = _firestore.collection('actions').doc(parts.actionId);
      final planRef = _firestore.collection('plans').doc(parts.planId);
      final actionSnap = await actionRef.get();
      final planSnap = await planRef.get();

      final batch = _firestore.batch();
      var updates = 0;
      final actionData = actionSnap.data();
      if (actionData != null && actionData['proofPhotoPath'] == photoPath) {
        batch.update(actionRef, {
          'proofPhotoPath': FieldValue.delete(),
          'proofSource': FieldValue.delete(),
          'proofTakenAt': FieldValue.delete(),
        });
        updates++;
      }
      final planData = planSnap.data();
      if (planData != null && planData['lastProofPhotoPath'] == photoPath) {
        batch.update(planRef, {
          'lastProofPhotoPath': FieldValue.delete(),
          'lastProofAt': FieldValue.delete(),
        });
        updates++;
      }
      if (updates > 0) await batch.commit();
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'deleteProofPhoto');
      rethrow;
    }

    // Nothing points at the object any more. A failed delete only leaves an
    // unreferenced object (gone with the account), so it is reported, not
    // thrown — the photo already disappeared from both feeds.
    try {
      await _proofStorage.delete(photoPath);
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'deleteProofPhotoObject');
    }
  }

  /// Whether [action] is a `done` record of [planId] dated on [now]'s day —
  /// the only kind of action a partner's 인정 may be written onto.
  @visibleForTesting
  static bool isTodayDoneAction(
    Map<String, dynamic> action, {
    required String planId,
    required DateTime now,
  }) {
    if (action['type'] != 'done') return false;
    if (action['planId'] != planId) return false;
    final date = (action['date'] as Timestamp?)?.toDate();
    if (date == null) return false;
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Resolves the owner's `done` action for today that a partner's 인정
  /// (cheerPartner / verifyPlan) should land on.
  ///
  /// Prefers the plan's `lastActionId` when that action is today's `done`
  /// record. Otherwise (plans written by older app versions, or a pointer to an
  /// earlier day) falls back to today's actions of the plan that are shared
  /// with me (`managerId == me`, stamped by the app or within seconds by the
  /// server), keeping only `done` records — the old query took whichever
  /// action came first, which could be a skipped or rested record. The type
  /// filter runs in memory so the (planId, managerId, date) index serves the
  /// query; a query on planId alone is denied under firestore.rules.next.
  Future<DocumentReference<Map<String, dynamic>>?> _todayDoneActionRef(
    String planId,
    Map<String, dynamic>? planData,
    DateTime now,
  ) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return null;
    final lastActionId = planData?['lastActionId'] as String?;
    if (lastActionId != null && lastActionId.isNotEmpty) {
      final ref = _firestore.collection('actions').doc(lastActionId);
      try {
        final snap = await ref.get();
        final data = snap.data();
        if (data != null && isTodayDoneAction(data, planId: planId, now: now)) {
          return ref;
        }
      } on FirebaseException catch (e) {
        // A deleted action has no `resource` for the get rule to check, so the
        // read is denied; fall through to the query rather than failing 인정.
        debugPrint('[RealRecordRepository] lastActionId lookup failed: $e');
      }
    }

    final startOfDay = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day),
    );
    final endOfDay = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    final snapshot = await _firestore
        .collection('actions')
        .where('planId', isEqualTo: planId)
        .where('managerId', isEqualTo: myUid)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .orderBy('date', descending: true)
        .get();

    final doneDocs = snapshot.docs
        .where((doc) => isTodayDoneAction(doc.data(), planId: planId, now: now))
        .toList();
    if (doneDocs.isEmpty) return null;
    // Latest completion first, matching what lastActionId would point at.
    doneDocs.sort((a, b) {
      final aDate = (a.data()['date'] as Timestamp).toDate();
      final bDate = (b.data()['date'] as Timestamp).toDate();
      return bDate.compareTo(aDate);
    });
    return doneDocs.first.reference;
  }

  @override
  Future<void> reconcileHistoryItem(
    String historyId,
    HistoryStatus status,
  ) async {
    try {
      // 1. Get History Item to find planId and Date
      final historyDoc = await _firestore
          .collection('actions')
          .doc(historyId)
          .get();
      if (!historyDoc.exists) return;

      final data = historyDoc.data()!;
      final planId = data['planId'] as String;
      final date = (data['date'] as Timestamp).toDate();
      final historyDate = DateTime(date.year, date.month, date.day);

      String typeStr;
      switch (status) {
        case HistoryStatus.done:
          typeStr = 'done';
          break;
        case HistoryStatus.actuallyDone:
          typeStr = 'done';
          break;
        case HistoryStatus.rested:
          typeStr = 'rested';
          break;
        case HistoryStatus.skipped:
          typeStr = 'skipped';
          break;
        case HistoryStatus.rescued:
          typeStr = 'rescued';
          break;
        default:
          typeStr = 'skipped';
          break;
      }

      // 2. Update History Item
      await _firestore.collection('actions').doc(historyId).update({
        'type': typeStr,
        'isReconciled': true,
        'reconciledAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Plan's handled-day fields
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      if (planDoc.exists) {
        final planData = planDoc.data();
        final completedDates =
            (planData?['completedDates'] as List<dynamic>? ?? [])
                .map((t) => (t as Timestamp).toDate())
                .toList();
        final skippedDates = (planData?['skippedDates'] as List<dynamic>? ?? [])
            .map((t) => (t as Timestamp).toDate())
            .toList();
        final rescuedDates = (planData?['rescuedDates'] as List<dynamic>? ?? [])
            .map((t) => (t as Timestamp).toDate())
            .toList();
        final restedDates = (planData?['restedDates'] as List<dynamic>? ?? [])
            .map((t) => (t as Timestamp).toDate())
            .toList();

        bool matchesTargetDate(DateTime value) {
          return value.year == historyDate.year &&
              value.month == historyDate.month &&
              value.day == historyDate.day;
        }

        completedDates.removeWhere(matchesTargetDate);
        skippedDates.removeWhere(matchesTargetDate);
        rescuedDates.removeWhere(matchesTargetDate);
        restedDates.removeWhere(matchesTargetDate);

        switch (status) {
          case HistoryStatus.done:
          case HistoryStatus.actuallyDone:
            completedDates.add(date);
            break;
          case HistoryStatus.rested:
            restedDates.add(date);
            break;
          case HistoryStatus.skipped:
            skippedDates.add(date);
            break;
          case HistoryStatus.rescued:
            rescuedDates.add(date);
            break;
          case HistoryStatus.verified:
            break;
        }

        await _firestore.collection('plans').doc(planId).update({
          'completedDates': completedDates
              .map((d) => Timestamp.fromDate(d))
              .toList(),
          'skippedDates': skippedDates
              .map((d) => Timestamp.fromDate(d))
              .toList(),
          'rescuedDates': rescuedDates
              .map((d) => Timestamp.fromDate(d))
              .toList(),
          'restedDates': restedDates.map((d) => Timestamp.fromDate(d)).toList(),
        });
      }
    } catch (e) {
      debugPrint('[RealRecordRepository] Error reconciling history item: $e');
      rethrow;
    }
  }

  @override
  Future<void> reportSkip(String planId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();

      // Need Plan Title for denormalization
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final planData = planDoc.data();
      final planTitle =
          (planData?['items'] as List?)?.firstOrNull?['title'] ??
          _untitledPlanTitle();

      // 1. Update Plan
      await _firestore.collection('plans').doc(planId).update({
        'skippedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
      });

      // 2. Add to actions
      await _addAction({
        'userId': user.uid,
        'planId': planId,
        'date': Timestamp.fromDate(now),
        'type': 'skipped', // HistoryStatus.skipped
        'title': planTitle,
        'createdAt': FieldValue.serverTimestamp(),
      }, managerId: actionManagerStampFor(planData));
    } catch (e) {
      debugPrint('[RealRecordRepository] Error reporting skip: $e');
      rethrow;
    }
  }

  @override
  Future<void> cheerPartner(
    String planId,
    String reactionType, {
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      // Get Plan to find who to cheer for (the plan owner)
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final toUserId =
          planDoc.data()?['userId'] as String? ?? ''; // Should valid

      final data = <String, dynamic>{
        'fromUserId': user.uid,
        'toUserId': toUserId,
        'planId': planId,
        'reactionType': reactionType,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (message != null && message.isNotEmpty) {
        data['message'] = message;
      }

      // Today's `done` record to mark verified — resolved before anything is
      // written, so the cheer (whose trigger sends the 인정 push) lands in the
      // same atomic batch as the 인정 itself. Writing the cheer first sent the
      // push even when the rest failed, and the retry sent a second one.
      final historyRef = await _todayDoneActionRef(planId, planDoc.data(), now);

      // 1. The cheers doc (push trigger) — same batch.
      final batch = _firestore.batch();
      batch.set(_firestore.collection('cheers').doc(), data);

      // 2. Denormalize to plan (Recent cheer) & Update Action (History)
      final planRef = _firestore.collection('plans').doc(planId);

      batch.update(planRef, {
        if (message != null && message.isNotEmpty) 'lastCheerMessage': message,
        if (message != null && message.isNotEmpty) 'lastComment': message,
        if (message == null || message.isEmpty)
          'lastCheerMessage': FieldValue.delete(),
        if (message == null || message.isEmpty)
          'lastComment': FieldValue.delete(),
        'lastCheerType': reactionType,
        'lastCheerAt': Timestamp.fromDate(now),
        'lastUpdatedBy': user.uid,
        'verifiedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
      });

      // 3. Update Action (HistoryItem) to verify and add message — today's
      // `done` record, never a skipped/rested one.
      if (historyRef != null) {
        final updateData = <String, dynamic>{
          'verifiedBy': user.uid,
          'verifiedAt': FieldValue.serverTimestamp(),
        };
        if (message != null && message.isNotEmpty) {
          updateData['partnerMessage'] = message;
        }
        if (_isReaction(reactionType)) {
          updateData['reaction'] = reactionType;
        }
        batch.update(historyRef, updateData);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[RealRecordRepository] Error cheering partner: $e');
      rethrow;
    }
  }

  /// A reaction emoji, as opposed to the 'poke' marker that shares the
  /// cheers collection.
  static bool _isReaction(String reactionType) {
    return reactionType.isNotEmpty &&
        reactionType != 'poke' &&
        reactionType != 'poke_acked';
  }

  @override
  Future<void> passPlan(String planId) async {
    // Treat pass as 'skipped' for now, or maybe 'rested' if it implies "Not today"
    // Using reportSkip implementation for consistency
    await reportSkip(planId);
  }

  @override
  Future<void> assignManagerToActivePlans(String managerId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('plans')
          .where('userId', isEqualTo: user.uid)
          .where(
            'state',
            whereIn: ['active', 'pending_approval'],
          ) // Filter by active states
          .get();

      // Only plans with no manager get the new partner. The state is left
      // alone: there is no approval step any more (spec §4.3), so a running
      // promise stays running. `lastUpdatedBy: system_link` matches what the
      // server's onRelationCreated writes, so onPlanUpdated sends no push.
      final batch = _firestore.batch();
      var updates = 0;
      for (final doc in querySnapshot.docs) {
        final current = doc.data()['managerId'];
        if (current is String && current.isNotEmpty) continue;
        batch.update(doc.reference, {
          'managerId': managerId,
          'lastUpdatedBy': kSystemLinkUpdater,
        });
        updates++;
      }
      if (updates > 0) await batch.commit();
    } catch (e) {
      debugPrint(
        '[RealRecordRepository] Error assigning manager to active plans: $e',
      );
      rethrow;
    }
  }

  @override
  Future<void> approvePlan(String planId) async {
    debugPrint('[RealRecordRepository] approvePlan called for $planId');
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final planRef = _firestore.collection('plans').doc(planId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(planRef);
        final data = snap.data();
        if (data == null) return;
        final updates = <String, dynamic>{
          'state': 'active', // PlanState.active
          'lastUpdatedBy': user.uid,
        };
        // The 4 weeks start on the day the partner says yes, so days spent
        // waiting for approval no longer count as missed days. Only a pending
        // plan is restarted — a stale card must not reset a running plan.
        // A plan with days already logged keeps its period (the owner could
        // record while it waited): restarting it would drop those days.
        final completed = data['completedDates'];
        final hasLoggedDays = completed is List && completed.isNotEmpty;
        if (data['state'] == PlanState.pendingApproval.toMap() &&
            !hasLoggedDays) {
          final period = Plan.periodStartingOn(DateTime.now());
          updates['startDate'] = Timestamp.fromDate(period.start);
          updates['endDate'] = Timestamp.fromDate(period.end);
        }
        tx.update(planRef, updates);
      });
    } catch (e) {
      debugPrint('[RealRecordRepository] Error approving plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyPlan(String planId) async {
    debugPrint('[RealRecordRepository] verifyPlan called for $planId');
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final planRef = _firestore.collection('plans').doc(planId);
      final planDoc = await planRef.get();

      // Mark today's `done` action as verified (resolved before writing so the
      // plan and the action update together).
      final historyRef = await _todayDoneActionRef(planId, planDoc.data(), now);

      final batch = _firestore.batch();
      // completedDates/verifiedDates are compared by Y-M-D, so the current
      // timestamp marks today.
      batch.update(planRef, {
        'verifiedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
        'lastUpdatedBy': user.uid,
      });
      if (historyRef != null) {
        batch.update(historyRef, {
          'verifiedBy': user.uid,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[RealRecordRepository] Error verifying plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> rejectPlan(String planId, {String? reason}) async {
    debugPrint('[RealRecordRepository] rejectPlan called. Plan ID: $planId');
    try {
      final user = _auth.currentUser;
      final updateData = <String, dynamic>{
        'state': PlanState.rejected.toMap(),
        'lastUpdatedBy': user?.uid,
        'promise': FieldValue.delete(),
      };
      if (reason != null && reason.isNotEmpty) {
        updateData['lastComment'] = reason;
      }

      await _firestore.collection('plans').doc(planId).update(updateData);
      debugPrint('[RealRecordRepository] Plan rejected successfully.');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error rejecting plan: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> completeOverduePlans() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      // 내가 실행자이거나 매니저인 진행/승인 대기 계획 중 종료일이 지난 것들을 찾습니다.
      // The home stream's participant query (`userId == me OR managerId ==
      // me`); the state filter runs in memory. The old `state in [...]`
      // query read every user's plans and is denied under rules.next.
      final runningStates = {
        PlanState.active.toMap(),
        PlanState.pendingApproval.toMap(),
      };
      final snapshot = await _firestore
          .collection('plans')
          .where(
            Filter.or(
              Filter('userId', isEqualTo: user.uid),
              Filter('managerId', isEqualTo: user.uid),
            ),
          )
          .get();

      final batch = _firestore.batch();
      int count = 0;
      final List<String> completedPlanIds = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!runningStates.contains(data['state'])) continue;
        final userId = data['userId'] as String?;
        final managerId = data['managerId'] as String?;

        // 관련이 없는 계획은 건너뜁니다.
        if (userId != user.uid && managerId != user.uid) continue;

        final endDateTimestamp = data['endDate'] as Timestamp?;
        if (endDateTimestamp == null) continue;

        final endDate = endDateTimestamp.toDate();
        final endDay = DateTime(endDate.year, endDate.month, endDate.day);

        // 오늘보다 종료일이 전이면 완료 처리
        if (endDay.isBefore(today)) {
          batch.update(doc.reference, {
            'state': PlanState.completed.toMap(),
            'lastUpdatedBy': 'system_cleanup',
          });
          completedPlanIds.add(doc.id);
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        debugPrint(
          '[RealRecordRepository] Completed $count overdue active/pending plans',
        );
        for (final planId in completedPlanIds) {
          await settlePromise(planId);
        }
      }
      return completedPlanIds;
    } catch (e) {
      debugPrint('[RealRecordRepository] Error completing overdue plans: $e');
      return [];
    }
  }

  @override
  Future<void> pokeUser(String userId, {String? message}) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    try {
      await _firestore.collection('cheers').add({
        'fromUserId': me.uid,
        'toUserId': userId,
        'message': message ?? kDefaultUserPokeMessage,
        'reactionType': 'poke',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[RealRecordRepository] Poked user $userId successfully');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error poking user: $e');
      rethrow;
    }
  }

  @override
  Future<void> replyToPoke(
    String planId, {
    required String toUserId,
    required String message,
  }) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not authenticated');
    await _firestore.collection('cheers').add({
      'fromUserId': me.uid,
      'toUserId': toUserId,
      'planId': planId,
      'reactionType': kPokeReplyReactionType,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendCheer(
    String toUserId, {
    String? planId,
    required String emoji,
    String? message,
  }) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not authenticated');
    await _firestore.collection('cheers').add({
      'fromUserId': me.uid,
      'toUserId': toUserId,
      if (planId != null) 'planId': planId,
      'reactionType': emoji,
      if (message != null) 'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> proposePromise(
    String planId, {
    PromiseReward? reward,
    PromisePenalty? penalty,
  }) async {
    assert(reward != null || penalty != null);
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final doc = await _firestore.collection('plans').doc(planId).get();
      final data = doc.data();
      if (data == null) throw Exception('Plan not found');

      final planState = PlanState.fromMap(data['state'] ?? 'draft');
      if (planState != PlanState.pendingApproval &&
          planState != PlanState.active) {
        throw Exception('Plan is not in a valid state for promise proposal');
      }

      final plan = Plan.fromMap(data, doc.id);
      final now = DateTime.now();
      final rewardDaysLimit = plan.rewardTargetDaysLimit(asOf: now);
      final penaltyDaysLimit = plan.penaltyTargetDaysLimit(asOf: now);
      final invalidReward =
          reward != null &&
          (reward.targetDays < 1 || reward.targetDays > rewardDaysLimit);
      final invalidPenalty =
          penalty != null &&
          (penalty.targetDays < 1 || penalty.targetDays > penaltyDaysLimit);
      if (invalidReward || invalidPenalty) {
        throw Exception(
          'Promise target days exceed the currently reachable limit',
        );
      }

      // 기존 약속이 active/settled이면 제안 불가
      if (data['promise'] != null) {
        final existingStatus = data['promise']['status'] as String?;
        if (existingStatus == 'active' || existingStatus == 'settled') {
          throw Exception('An active or settled promise already exists');
        }
      }

      final promise = {
        'status': PromiseStatus.proposed.toMap(),
        'proposerId': user.uid,
        if (reward != null) 'reward': reward.toMap(),
        if (penalty != null) 'penalty': penalty.toMap(),
        'proposedAt': Timestamp.fromDate(now),
      };

      await _firestore.collection('plans').doc(planId).update({
        'promise': promise,
      });
      debugPrint('[RealRecordRepository] Promise proposed for plan $planId');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error proposing promise: $e');
      rethrow;
    }
  }

  @override
  Future<void> respondPromise(String planId, {required bool accept}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final doc = await _firestore.collection('plans').doc(planId).get();
      final data = doc.data();
      if (data == null) throw Exception('Plan not found');
      if (data['promise'] == null) throw Exception('No promise to respond to');

      final promiseData = data['promise'] as Map<String, dynamic>;
      if (promiseData['status'] != 'proposed') {
        throw Exception('Promise is not in proposed state');
      }
      if (promiseData['proposerId'] == user.uid) {
        throw Exception('Cannot respond to own promise');
      }

      if (accept) {
        await _firestore.collection('plans').doc(planId).update({
          'promise.status': PromiseStatus.active.toMap(),
          'promise.acceptedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        await _firestore.collection('plans').doc(planId).update({
          'promise.status': PromiseStatus.rejected.toMap(),
        });
      }
      debugPrint(
        '[RealRecordRepository] Promise ${accept ? "accepted" : "rejected"} for plan $planId',
      );
    } catch (e) {
      debugPrint('[RealRecordRepository] Error responding to promise: $e');
      rethrow;
    }
  }

  @override
  Future<void> settlePromise(String planId) async {
    try {
      final doc = await _firestore.collection('plans').doc(planId).get();
      final data = doc.data();
      if (data == null) return;
      if (data['promise'] == null) return;

      final promiseData = data['promise'] as Map<String, dynamic>;
      if (promiseData['status'] != 'active') return;

      final plan = Plan.fromMap(data, doc.id);
      final now = DateTime.now();
      final cutoffDate = plan.endDate.isBefore(now) ? plan.endDate : now;
      final cutoff = DateTime(
        cutoffDate.year,
        cutoffDate.month,
        cutoffDate.day,
      );

      // 예정일 계산
      final scheduledDates = <DateTime>[];
      for (
        var d = DateTime(
          plan.startDate.year,
          plan.startDate.month,
          plan.startDate.day,
        );
        !d.isAfter(cutoff);
        d = d.add(const Duration(days: 1))
      ) {
        final weekday = d.weekday;
        if (plan.items.any((item) => item.days.contains(weekday))) {
          scheduledDates.add(d);
        }
      }

      // 성공일 계산
      final successDays = plan.completedDates.where((cd) {
        final c = DateTime(cd.year, cd.month, cd.day);
        return !c.isAfter(cutoff) &&
            !c.isBefore(
              DateTime(
                plan.startDate.year,
                plan.startDate.month,
                plan.startDate.day,
              ),
            );
      }).length;

      var failDays = scheduledDates.length - successDays;
      if (failDays < 0) failDays = 0;

      // 판정
      final reward = promiseData['reward'] != null
          ? PromiseReward.fromMap(promiseData['reward'] as Map<String, dynamic>)
          : null;
      final penalty = promiseData['penalty'] != null
          ? PromisePenalty.fromMap(
              promiseData['penalty'] as Map<String, dynamic>,
            )
          : null;

      final rewardMet = reward != null && successDays >= reward.targetDays;
      final penaltyMet = penalty != null && failDays >= penalty.targetDays;

      SettlementResult result;
      if (rewardMet && penaltyMet) {
        result = SettlementResult.bothMet;
      } else if (rewardMet) {
        result = SettlementResult.rewardAchieved;
      } else if (penaltyMet) {
        result = SettlementResult.penaltyTriggered;
      } else {
        result = SettlementResult.neitherMet;
      }

      await _firestore.collection('plans').doc(planId).update({
        'promise.status': PromiseStatus.settled.toMap(),
        'promise.settledAt': Timestamp.fromDate(now),
        'promise.settledSuccessDays': successDays,
        'promise.settledFailDays': failDays,
        'promise.settlementResult': result.toMap(),
      });
      debugPrint(
        '[RealRecordRepository] Promise settled for plan $planId: $result (success: $successDays, fail: $failDays)',
      );
    } catch (e) {
      debugPrint('[RealRecordRepository] Error settling promise: $e');
    }
  }

  @override
  Future<void> acknowledgePromiseSettlement(
    String planId, {
    String? comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final trimmed = comment?.trim();
      final updates = <String, dynamic>{
        'promise.settlementAcknowledgedBy': FieldValue.arrayUnion([user.uid]),
        'lastUpdatedBy': user.uid,
      };
      if (trimmed != null && trimmed.isNotEmpty) {
        updates['lastComment'] = trimmed;
        updates['lastCheerAt'] = FieldValue.serverTimestamp();
      }
      await _firestore.collection('plans').doc(planId).update(updates);
      debugPrint(
        '[RealRecordRepository] Promise settlement acknowledged for plan $planId',
      );
    } catch (e) {
      debugPrint(
        '[RealRecordRepository] Error acknowledging promise settlement: $e',
      );
      rethrow;
    }
  }

  @override
  Future<void> rescuePlan(String planId, {DateTime? date}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final targetDate =
          date ?? DateTime.now().subtract(const Duration(days: 1));

      // Plan 정보 가져오기
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final planData = planDoc.data();
      final planTitle =
          (planData?['items'] as List?)?.firstOrNull?['title'] ??
          _untitledPlanTitle();

      // 1. rescuedDates에 추가
      await _firestore.collection('plans').doc(planId).update({
        'rescuedDates': FieldValue.arrayUnion([Timestamp.fromDate(targetDate)]),
        'lastUpdatedBy': user.uid,
      });

      // 2. actions에 기록 추가
      await _addAction({
        'userId': planData?['userId'] ?? '',
        'planId': planId,
        'date': Timestamp.fromDate(targetDate),
        'type': 'rescued',
        'title': planTitle,
        'rescuedBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, managerId: actionManagerStampFor(planData));

      debugPrint('[RealRecordRepository] Plan rescued: $planId');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error rescuing plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> reportRest(String planId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();

      // Plan 정보 가져오기
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final planData = planDoc.data();
      final planTitle =
          (planData?['items'] as List?)?.firstOrNull?['title'] ??
          _untitledPlanTitle();

      // 주간 휴식권 사용 확인
      final restedDates = (planData?['restedDates'] as List<dynamic>? ?? [])
          .map((t) => (t as Timestamp).toDate())
          .toList();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final mondayDate = DateTime(monday.year, monday.month, monday.day);
      final sundayDate = mondayDate.add(const Duration(days: 7));
      final usedThisWeek = restedDates.where((d) {
        final date = DateTime(d.year, d.month, d.day);
        return !date.isBefore(mondayDate) && date.isBefore(sundayDate);
      }).length;

      if (usedThisWeek >= 1) {
        throw const RestPassAlreadyUsedException();
      }

      // 1. restedDates에 추가
      await _firestore.collection('plans').doc(planId).update({
        'restedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
        'lastUpdatedBy': user.uid,
      });

      // 2. actions에 기록 추가
      await _addAction({
        'userId': user.uid,
        'planId': planId,
        'date': Timestamp.fromDate(now),
        'type': 'rested',
        'title': planTitle,
        'createdAt': FieldValue.serverTimestamp(),
      }, managerId: actionManagerStampFor(planData));

      debugPrint('[RealRecordRepository] Rest day used: $planId');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error reporting rest: $e');
      rethrow;
    }
  }

  @override
  Future<void> recordPilotSettlement(
    String planId, {
    required String nextPlanIntent,
    String? exitReason,
  }) async {
    final user = _auth.currentUser;

    try {
      final data = <String, dynamic>{
        'pilotNextPlanIntent': nextPlanIntent,
        'pilotSettledAt': FieldValue.serverTimestamp(),
        'lastUpdatedBy': user?.uid ?? 'system_pilot_settlement',
      };
      if (exitReason != null && exitReason.trim().isNotEmpty) {
        data['pilotExitReason'] = exitReason.trim();
      }

      await _firestore.collection('plans').doc(planId).update(data);
      debugPrint('[RealRecordRepository] Pilot settlement recorded: $planId');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error recording pilot settlement: $e');
      rethrow;
    }
  }
}
