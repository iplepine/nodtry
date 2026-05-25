import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';
import '../models/promise_model.dart';
import 'record_repository.dart';

import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import '../models/relation_model.dart';

/// 앱 설정에서 사용자가 명시적으로 고른 로케일.
/// main.dart에서 appSettingsProvider를 listen해 매번 set한다.
/// null이면 시스템 로케일(platformDispatcher)을 따른다.
String? _currentAppLocaleCode;

/// 앱 설정 변경 시 호출되어 repository 전체에서 사용할 locale 코드를 갱신.
void setRepositoryLocaleCode(String? code) {
  _currentAppLocaleCode = code;
}

/// HomeCardModel.headerMessage 텍스트를 디바이스 로케일에 맞춰 반환.
/// Why: repository는 BuildContext 밖에서 동작하므로 AppLocalizations 접근 불가.
/// 사용자가 앱 내 설정에서 ko로 고른 경우도 OS 로케일과 무관하게 ko로 반환되도록
/// _currentAppLocaleCode를 우선 본다.
String _headerMessage(String key) {
  final locale = _currentAppLocaleCode ??
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final isKo = locale.startsWith('ko');
  switch (key) {
    case 'allDoneToday':
      return isKo ? '오늘 약속을 다 지켰어요' : 'All today\'s promises kept';
    case 'gotMessage':
      return isKo ? '전달받은 말이 있어요' : 'A message arrived';
    case 'newPlanProposed':
      return isKo ? '새로운 계획 제안이 있어요' : 'New plan proposed';
    case 'waitingPromiseAccept':
      return isKo ? '약속 수락을 기다리고 있어요' : 'Waiting for promise acceptance';
    case 'promiseResult':
      return isKo ? '약속 결과가 나왔어요' : 'Promise result is out';
    case 'partnerRequestedAdjust':
      return isKo ? '파트너가 조율을 요청했어요' : 'Partner requested an adjustment';
    case 'promiseProposalArrived':
      return isKo ? '약속 제안이 도착했어요' : 'Promise proposal arrived';
    case 'settlementNeeded':
      return isKo ? '4주 정산이 필요해요' : '4-week settlement needed';
    case 'pokeWaiting':
      return isKo ? '똑똑! 파트너가 기다리고 있어요.' : 'Knock! Your partner is waiting.';
    case 'todayMissed':
      return isKo
          ? '똑똑! 오늘 약속이 파트너에게 놓친 약속으로 남았어요.'
          : "Knock! Today's promise is now a missed promise for your partner.";
    case 'waitingForPromise':
      return isKo ? '약속을 기다리고 있어요' : 'Waiting for a promise';
    case 'missedAppeared':
      return isKo ? '놓친 약속이 떴어요' : 'A missed promise appeared';
    case 'pokeReadyTurn':
      return isKo ? '똑똑 보낼 차례' : 'Time to send a knock';
    default:
      return key;
  }
}

/// 실제 데이터 저장소 구현체 (Firestore 연동 예정)
class RealRecordRepository implements RecordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Stream<List<HomeCardModel>> getHomeCardStatesStream() {
    final user = FirebaseAuth.instance.currentUser;
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
    final List<({Plan plan, PlanItem item, int timeInMin})> allTodayItems = [];
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
                ? (plan.lastPokeMessage ?? _headerMessage('pokeWaiting'))
                : _headerMessage('todayMissed'),
          ),
        );
      }

      if (isHandledToday) {
        continue;
      }

      for (var item in todayItems) {
        final time = item.notificationTime;
        final timeInMin = time != null
            ? (time.hour * 60 + time.minute)
            : (23 * 60 + 59);

        allTodayItems.add((plan: plan, item: item, timeInMin: timeInMin));
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

      // Primary: 현재 이후 가장 가까운 것 1개
      if (upcomingItems.isNotEmpty) {
        final primary = upcomingItems.first;
        final streak = primary.plan.currentStreak;
        mineCards.add(
          HomeCardModel(
            state: HomeCardState.nowAction,
            plan: _createSingleItemPlan(primary.plan, primary.item),
            streakCount: streak >= 2 ? streak : null,
          ),
        );
      }

      // Secondary: 지나간 것들 (최대 3개)
      final sortedPastItems = pastItems.reversed.take(3).toList();
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
              final hasTodayItem = plan.items.any(
                (item) => item.days.contains(todayWeekday),
              );
              if (hasTodayItem) {
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
                    headerMessage: hasMissedNotice ? _headerMessage('missedAppeared') : _headerMessage('pokeReadyTurn'),
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
        final headlinePlan = completedToday.firstOrNull
            ?? myPlans.where((p) => p.state == PlanState.active).firstOrNull
            ?? myPlans.firstOrNull;
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
    final user = FirebaseAuth.instance.currentUser;
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
      final snapshot = await _firestore
          .collection('plans')
          .where('userId', isEqualTo: userId)
          .get();

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
    return _firestore
        .collection('plans')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
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
    return _firestore
        .collection('plans')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
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
    final user = FirebaseAuth.instance.currentUser;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _firestore.collection('actions');

    if (userIds != null && userIds.isNotEmpty) {
      query = query.where('userId', whereIn: userIds);
    } else {
      query = query.where('userId', isEqualTo: user.uid);
    }

    return query.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => _mapHistoryItem(
              doc.data() as Map<String, dynamic>,
              doc.id,
              user.uid,
            ),
          )
          .toList();
    });
  }

  @override
  Stream<List<HistoryItem>> getHistoryItemsByPlanIdStream(String planId) {
    return _firestore
        .collection('actions')
        .where('planId', isEqualTo: planId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          final currentUser = FirebaseAuth.instance.currentUser;
          final myUid = currentUser?.uid ?? '';

          return snapshot.docs
              .map((doc) => _mapHistoryItem(doc.data(), doc.id, myUid))
              .toList();
        });
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      await _firestore.collection('plans').doc(planId).update({
        'lastPokeAt': Timestamp.fromDate(now),
        'lastPokeMessage': message ?? '똑똑! 파트너가 기다리고 있어요. 지금 약속을 정리해볼까요?',
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
    final user = FirebaseAuth.instance.currentUser;
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
          '알 수 없는 계획';

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

      await _firestore.collection('actions').add({
        'userId': user.uid,
        'planId': planId,
        'date': Timestamp.fromDate(now),
        'type': typeStr,
        'title': planTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'isReconciled': true,
      });
    } catch (e) {
      debugPrint('[RealRecordRepository] Error reconciling plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyHistoryItem(String historyId, {String? message}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Update actions collection
      final updateData = {
        'verifiedBy': user.uid,
        'verifiedAt': FieldValue.serverTimestamp(),
      };
      if (message != null && message.isNotEmpty) {
        updateData['comment'] = message;
      }

      await _firestore.collection('actions').doc(historyId).update(updateData);

      // 2. Synchronize verifiedDates in plans collection for real-time Home Card sync
      final historyDoc = await _firestore
          .collection('actions')
          .doc(historyId)
          .get();
      if (historyDoc.exists) {
        final data = historyDoc.data();
        final planId = data?['planId'] as String?;
        final date = (data?['date'] as Timestamp?)?.toDate();

        if (planId != null && date != null) {
          await _firestore.collection('plans').doc(planId).update({
            'verifiedDates': FieldValue.arrayUnion([Timestamp.fromDate(date)]),
          });
        }
      }
    } catch (e) {
      debugPrint('[RealRecordRepository] Error verifying history item: $e');
      rethrow;
    }
  }

  @override
  @override
  Future<void> reportCompletion(String planId, {String? note}) async {
    debugPrint('[RealRecordRepository] reportCompletion for $planId');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();

      // 1. Update Plan (completedDates & lastActionNote)
      await _firestore.collection('plans').doc(planId).update({
        'completedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
        'lastActionNote': note,
      });
      debugPrint('[RealRecordRepository] Plan updated successfully');

      // 2. Add to actions collection
      // Need Plan Title for denormalization (Optional but recommended)
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final planData = planDoc.data();
      final planTitle =
          (planData?['items'] as List?)?.firstOrNull?['title'] ?? '알 수 없는 계획';

      final actionRef = await _firestore.collection('actions').add({
        'userId': user.uid,
        'planId': planId,
        'date': Timestamp.fromDate(now),
        'type': 'done', // HistoryStatus.done
        'title': planTitle,
        'note': note, // 저장
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
        '[RealRecordRepository] Action added with ID: ${actionRef.id}',
      );
    } catch (e) {
      debugPrint('[RealRecordRepository] !!! Error reporting completion: $e');
      rethrow;
    }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();

      // Need Plan Title for denormalization
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final planData = planDoc.data();
      final planTitle =
          (planData?['items'] as List?)?.firstOrNull?['title'] ?? '알 수 없는 계획';

      // 1. Update Plan
      await _firestore.collection('plans').doc(planId).update({
        'skippedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
      });

      // 2. Add to actions
      await _firestore.collection('actions').add({
        'userId': user.uid,
        'planId': planId,
        'date': Timestamp.fromDate(now),
        'type': 'skipped', // HistoryStatus.skipped
        'title': planTitle,
        'createdAt': FieldValue.serverTimestamp(),
      });
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
    final user = FirebaseAuth.instance.currentUser;
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

      // 1. Add to cheers collection
      await _firestore.collection('cheers').add(data);

      // 2. Denormalize to plan (Recent cheer) & Update Action (History)
      final batch = _firestore.batch();
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

      // 3. Update Action (HistoryItem) to verify and add message
      // Find today's action for this plan
      final startOfDay = Timestamp.fromDate(
        DateTime(now.year, now.month, now.day),
      );
      final endOfDay = Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

      final snapshot = await _firestore
          .collection('actions')
          .where('planId', isEqualTo: planId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final historyRef = snapshot.docs.first.reference;
        final updateData = <String, dynamic>{
          'verifiedBy': user.uid,
          'verifiedAt': FieldValue.serverTimestamp(),
        };
        if (message != null && message.isNotEmpty) {
          updateData['partnerMessage'] = message;
        }
        batch.update(historyRef, updateData);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[RealRecordRepository] Error cheering partner: $e');
      rethrow;
    }
  }

  @override
  Future<void> passPlan(String planId) async {
    // Treat pass as 'skipped' for now, or maybe 'rested' if it implies "Not today"
    // Using reportSkip implementation for consistency
    await reportSkip(planId);
  }

  @override
  Future<void> assignManagerToActivePlans(String managerId) async {
    final user = FirebaseAuth.instance.currentUser;
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

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        // 이미 매니저가 있는 경우는 건너뛰거나, 덮어쓸지 정책 결정 필요.
        // 여기서는 '매니저가 없는 경우'에만 할당하는 것으로 소급 적용.
        final data = doc.data();
        if (data['managerId'] == null ||
            (data['managerId'] as String).isEmpty) {
          batch.update(doc.reference, {
            'managerId': managerId,
            'state': 'pending_approval', // PlanState.pendingApproval
          });
        }
      }
      await batch.commit();
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('plans').doc(planId).update({
        'state': 'active', // PlanState.active
        'lastUpdatedBy': user.uid,
      });
    } catch (e) {
      debugPrint('[RealRecordRepository] Error approving plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyPlan(String planId) async {
    debugPrint('[RealRecordRepository] verifyPlan called for $planId');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();

      // 1. Update Plan's verifiedDates
      // Note: We use arrayUnion with Timestamp.fromDate(now).
      // Since 'completedDates' and 'verifiedDates' are checked by comparing YMD,
      // adding current timestamp works.
      await _firestore.collection('plans').doc(planId).update({
        'verifiedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
        'lastUpdatedBy': user.uid,
      });

      // 2. Find associated history item (action) for today and mark as verified
      // Since we don't know the exact history ID, we query by planId + date range (today)
      final startOfDay = Timestamp.fromDate(
        DateTime(now.year, now.month, now.day),
      );
      final endOfDay = Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

      final snapshot = await _firestore
          .collection('actions')
          .where('planId', isEqualTo: planId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final historyId = snapshot.docs.first.id;
        await _firestore.collection('actions').doc(historyId).update({
          'verifiedBy': user.uid,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[RealRecordRepository] Error verifying plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> rejectPlan(String planId, {String? reason}) async {
    debugPrint('[RealRecordRepository] rejectPlan called. Plan ID: $planId');
    try {
      final user = FirebaseAuth.instance.currentUser;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      // 내가 실행자이거나 매니저인 진행/승인 대기 계획 중 종료일이 지난 것들을 찾습니다.
      final snapshot = await _firestore
          .collection('plans')
          .where(
            'state',
            whereIn: [
              PlanState.active.toMap(),
              PlanState.pendingApproval.toMap(),
            ],
          )
          .get();

      final batch = _firestore.batch();
      int count = 0;
      final List<String> completedPlanIds = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
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
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) throw Exception('Not authenticated');

    try {
      await _firestore.collection('cheers').add({
        'fromUserId': me.uid,
        'toUserId': userId,
        'message': message ?? '똑똑! 약속을 기다리는 사람이 있어요.',
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
  Future<void> proposePromise(
    String planId, {
    PromiseReward? reward,
    PromisePenalty? penalty,
  }) async {
    assert(reward != null || penalty != null);
    final user = FirebaseAuth.instance.currentUser;
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
    final user = FirebaseAuth.instance.currentUser;
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
    final user = FirebaseAuth.instance.currentUser;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final targetDate =
          date ?? DateTime.now().subtract(const Duration(days: 1));

      // Plan 정보 가져오기
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final planData = planDoc.data();
      final planTitle =
          (planData?['items'] as List?)?.firstOrNull?['title'] ?? '알 수 없는 계획';

      // 1. rescuedDates에 추가
      await _firestore.collection('plans').doc(planId).update({
        'rescuedDates': FieldValue.arrayUnion([Timestamp.fromDate(targetDate)]),
        'lastUpdatedBy': user.uid,
      });

      // 2. actions에 기록 추가
      await _firestore.collection('actions').add({
        'userId': planData?['userId'] ?? '',
        'planId': planId,
        'date': Timestamp.fromDate(targetDate),
        'type': 'rescued',
        'title': planTitle,
        'rescuedBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[RealRecordRepository] Plan rescued: $planId');
    } catch (e) {
      debugPrint('[RealRecordRepository] Error rescuing plan: $e');
      rethrow;
    }
  }

  @override
  Future<void> reportRest(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();

      // Plan 정보 가져오기
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final planData = planDoc.data();
      final planTitle =
          (planData?['items'] as List?)?.firstOrNull?['title'] ?? '알 수 없는 계획';

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
        throw Exception('이번 주 휴식권을 이미 사용했습니다.');
      }

      // 1. restedDates에 추가
      await _firestore.collection('plans').doc(planId).update({
        'restedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
        'lastUpdatedBy': user.uid,
      });

      // 2. actions에 기록 추가
      await _firestore.collection('actions').add({
        'userId': user.uid,
        'planId': planId,
        'date': Timestamp.fromDate(now),
        'type': 'rested',
        'title': planTitle,
        'createdAt': FieldValue.serverTimestamp(),
      });

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
    final user = FirebaseAuth.instance.currentUser;

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
