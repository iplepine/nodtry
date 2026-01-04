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
  Stream<List<HomeCardModel>> getHomeCardStatesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([
        const HomeCardModel(state: HomeCardState.emptyPlan),
      ]);
    }

    // Firestore `snapshots()` for offline-first updates
    return _firestore
        .collection('plans')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map(_mapSnapshotToModels)
        .handleError((error) {
          debugPrint('[RealRecordRepository] Error in stream: $error');
          return [const HomeCardModel(state: HomeCardState.emptyPlan)];
        });
  }

  /// Helper to convert Firestore snapshot to HomeCardModels
  List<HomeCardModel> _mapSnapshotToModels(QuerySnapshot snapshot) {
    try {
      final plans = snapshot.docs
          .map(
            (doc) => Plan.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .where(
            (p) =>
                p.state == PlanState.active ||
                p.state == PlanState.pendingApproval,
          )
          .toList();

      if (plans.isEmpty) {
        return [const HomeCardModel(state: HomeCardState.emptyPlan)];
      }
      return _processPlans(plans);
    } catch (e) {
      debugPrint('[RealRecordRepository] Error mapping snapshot: $e');
      return [const HomeCardModel(state: HomeCardState.emptyPlan)];
    }
  }

  /// Extracted logic for processing plans into cards
  List<HomeCardModel> _processPlans(List<Plan> plans) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayWeekday = now.weekday; // 1=Mon, 7=Sun
    final nowInMinutes = now.hour * 60 + now.minute;

    // 1. 오늘 해야 할 모든 아이템 수집
    final List<({Plan plan, PlanItem item, int timeInMin})> allTodayItems = [];

    for (var plan in plans) {
      if (now.isBefore(plan.startDate) || now.isAfter(plan.endDate)) {
        continue;
      }

      // Check if completed for today (ignore time component)
      final isCompletedToday = plan.completedDates.any(
        (d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day,
      );

      if (isCompletedToday) {
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
      return [const HomeCardModel(state: HomeCardState.todayComplete)];
    }

    // 2. 시간 순 정렬
    allTodayItems.sort((a, b) => a.timeInMin.compareTo(b.timeInMin));

    // 3. 상태 결정
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
          state: HomeCardState.overdue, // Was pastUncompleted
          plan: _createSingleItemPlan(past.plan, past.item),
        ),
      );
    }

    // 만약 Primary도 없고 지남(Secondary)도 없으면 Quiet Day
    if (finalModels.isEmpty) {
      return [const HomeCardModel(state: HomeCardState.todayEmpty)];
    }

    return finalModels;
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
                p.state == PlanState.pendingApproval,
          )
          .toList();

      if (plans.isEmpty) {
        return [const HomeCardModel(state: HomeCardState.emptyPlan)];
      }

      return _processPlans(plans);
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
        })
        .handleError((error) {
          debugPrint(
            '[RealRecordRepository] Error in plans stream for user $userId: $error',
          );
          return <Plan>[];
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
    );
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
          .map((doc) => HistoryItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[RealRecordRepository] Error fetching history items: $e');
      return [];
    }
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
        // Technically create should be fresh, but if ID provided, treat as create
        debugPrint(
          '[RealRecordRepository] Creating with existing ID: ${plan.id}',
        );
        await collection.doc(plan.id).set(plan.toMap());
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
  Future<void> verifyHistoryItem(String historyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('actions').doc(historyId).update({
        'verifiedBy': user.uid,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[RealRecordRepository] Error verifying history item: $e');
      rethrow;
    }
  }

  @override
  Future<void> reportCompletion(String planId) async {
    debugPrint('[RealRecordRepository] reportCompletion for $planId');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();

      // 1. Update Plan (completedDates)
      await _firestore.collection('plans').doc(planId).update({
        'completedDates': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
      });

      // 2. Add to actions collection
      // Need Plan Title for denormalization (Optional but recommended)
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final planData = planDoc.data();
      final planTitle =
          (planData?['items'] as List?)?.firstOrNull?['title'] ?? '알 수 없는 계획';

      await _firestore.collection('actions').add({
        'userId': user.uid,
        'planId': planId,
        'date': Timestamp.fromDate(now),
        'type': 'done', // HistoryStatus.done
        'title': planTitle,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[RealRecordRepository] Error reporting completion: $e');
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

      // 3. Update Plan's completedDates
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      if (planDoc.exists) {
        final planData = planDoc.data();
        final completedDates =
            (planData?['completedDates'] as List<dynamic>? ?? [])
                .map((t) => (t as Timestamp).toDate())
                .toList();

        final isDoneStatus =
            (status == HistoryStatus.done ||
            status == HistoryStatus.actuallyDone);

        bool changed = false;
        if (isDoneStatus) {
          // Add if not present for that day
          final hasDate = completedDates.any(
            (d) =>
                d.year == historyDate.year &&
                d.month == historyDate.month &&
                d.day == historyDate.day,
          );
          if (!hasDate) {
            completedDates.add(date); // Use history item's date timestamp
            changed = true;
          }
        } else {
          // Remove if present for that day
          final initialLen = completedDates.length;
          completedDates.removeWhere(
            (d) =>
                d.year == historyDate.year &&
                d.month == historyDate.month &&
                d.day == historyDate.day,
          );
          if (completedDates.length != initialLen) {
            changed = true;
          }
        }

        if (changed) {
          await _firestore.collection('plans').doc(planId).update({
            'completedDates': completedDates
                .map((d) => Timestamp.fromDate(d))
                .toList(),
          });
        }
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
  Future<void> cheerPartner(String planId, String reactionType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get Plan to find who to cheer for (the plan owner)
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      final toUserId =
          planDoc.data()?['userId'] as String? ?? ''; // Should valid

      await _firestore.collection('cheers').add({
        'fromUserId': user.uid,
        'toUserId': toUserId,
        'planId': planId,
        'reactionType': reactionType,
        'createdAt': FieldValue.serverTimestamp(),
      });
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
}
