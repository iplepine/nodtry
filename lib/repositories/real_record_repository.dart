import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';
import 'record_repository.dart';

import 'package:flutter/foundation.dart';

/// 실제 데이터 저장소 구현체 (Firestore 연동 예정)
class RealRecordRepository implements RecordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<HomeCardModel>> getHomeCardStates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [const HomeCardModel(state: HomeCardState.planNeeded)];
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
                p.state == PlanState.pendingApproval,
          )
          .toList();

      if (plans.isEmpty) {
        return [const HomeCardModel(state: HomeCardState.planNeeded)];
      }

      final now = DateTime.now();
      final todayWeekday = now.weekday; // 1=Mon, 7=Sun
      final nowInMinutes = now.hour * 60 + now.minute;

      // 1. 오늘 해야 할 모든 아이템 수집
      final List<({Plan plan, PlanItem item, int timeInMin})> allTodayItems =
          [];

      for (var plan in plans) {
        if (now.isBefore(plan.startDate) || now.isAfter(plan.endDate)) {
          continue;
        }

        final todayItems = plan.items
            .where((item) => item.days.contains(todayWeekday))
            .toList();

        for (var item in todayItems) {
          final time = item.notificationTime;
          // 알림 시간이 없으면 당일 23:59로 처리
          final timeInMin = time != null
              ? (time.hour * 60 + time.minute)
              : (23 * 60 + 59);

          allTodayItems.add((plan: plan, item: item, timeInMin: timeInMin));
        }
      }

      if (allTodayItems.isEmpty) {
        return [const HomeCardModel(state: HomeCardState.relaxedDay)];
      }

      // 2. 시간 순 정렬
      allTodayItems.sort((a, b) => a.timeInMin.compareTo(b.timeInMin));

      // 3. 상태 결정
      // TODO: 실제 완료 여부(Actions 컬렉션) 연동 필요. 현재는 모두 미완료로 가정.

      final upcomingItems = allTodayItems
          .where((i) => i.timeInMin >= nowInMinutes)
          .toList();
      final pastItems = allTodayItems
          .where((i) => i.timeInMin < nowInMinutes)
          .toList();

      final List<HomeCardModel> finalModels = [];

      // Primary: 현재 이후 가장 가까운 것 1개
      if (upcomingItems.isNotEmpty) {
        final primary = upcomingItems.first;
        finalModels.add(
          HomeCardModel(
            state: HomeCardState.nowAction, // Was reportNeeded
            plan: _createSingleItemPlan(primary.plan, primary.item),
          ),
        );
      }

      // Secondary: 지나간 것들 (격하된 계획) - 최대 3개, 최근 것 우선(역순 정렬)
      final sortedPastItems = pastItems.reversed.take(3).toList();
      for (var past in sortedPastItems) {
        finalModels.add(
          HomeCardModel(
            state: HomeCardState.overdueSelfAction, // Was pastUncompleted
            plan: _createSingleItemPlan(past.plan, past.item),
          ),
        );
      }

      // 만약 Primary도 없고 지남(Secondary)도 없으면 Quiet Day
      if (finalModels.isEmpty) {
        return [
          const HomeCardModel(state: HomeCardState.relaxedDay),
        ]; // Was quietDay
      }

      return finalModels;
    } catch (e) {
      debugPrint('[RealRecordRepository] Error fetching home cards: $e');
      return [const HomeCardModel(state: HomeCardState.planNeeded)];
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
    );
  }

  @override
  Future<List<HistoryItem>> getHistoryItems() async {
    // TODO: Firestore에서 실제 데이터 가져오기
    return [];
  }

  @override
  Future<void> createPlan(Plan plan) async {
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
      } else {
        debugPrint(
          '[RealRecordRepository] Updating document with ID: ${plan.id}',
        );
        await collection.doc(plan.id).set(plan.toMap());
        debugPrint('[RealRecordRepository] Document updated successfully.');
      }
    } catch (e) {
      debugPrint('[RealRecordRepository] Error creating plan: $e');
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
    // TODO: Firestore에서 해당 계획의 상태를 업데이트하고 히스토리에 기록
    // 48시간 제한 로직 포함 필요
  }

  @override
  Future<void> verifyHistoryItem(String historyId) async {
    // TODO: Firestore에서 해당 히스토리 항목의 isVerifiedByMe 필드를 true로 업데이트
  }

  @override
  Future<void> reportCompletion(String planId) async {
    // TODO: Firestore에 실천 기록 생성 및 계획 상태 업데이트
  }

  @override
  Future<void> reconcileHistoryItem(
    String historyId,
    HistoryStatus status,
  ) async {
    // TODO: Firestore에서 해당 HistoryItem 업데이트
  }
}
