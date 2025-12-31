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
          //.where('state', isEqualTo: 'active') // Index required? Start with client filter if small
          .get();

      final plans = snapshot.docs
          .map((doc) => Plan.fromMap(doc.data(), doc.id))
          .where((p) => p.state == PlanState.active)
          .toList();

      if (plans.isEmpty) {
        return [const HomeCardModel(state: HomeCardState.planNeeded)];
      }

      final models = <HomeCardModel>[];
      final now = DateTime.now();
      final todayWeekday = now.weekday; // 1=Mon, 7=Sun

      for (var plan in plans) {
        // Date Validity Check
        // StartDate: 00:00:00 of the day
        // EndDate: 23:59:59 of the day (usually, or next day 00:00:00)
        // Let's assume startDate and endDate are exact boundaries.
        if (now.isBefore(plan.startDate) || now.isAfter(plan.endDate)) {
          continue;
        }

        // Find items scheduled for today
        // TODO: Check if already completed (Action query)

        // Filter items for today
        final todayItems = plan.items
            .where((item) => item.days.contains(todayWeekday))
            .toList();

        if (todayItems.isNotEmpty) {
          // For MVP, create card for the Plan.
          // Ideally we should differentiate items.
          // Ensure the plan passed to UI has the specific item title?
          // or just pass the whole plan and let UI decide?
          // UI shows "Plan Title"? or "Item Title"?
          // If UI uses plan.items[0].title, we might need to filter items in the passed plan.

          final planForToday = Plan(
            id: plan.id,
            userId: plan.userId,
            managerId: plan.managerId,
            startDate: plan.startDate,
            endDate: plan.endDate,
            state: plan.state,
            items: todayItems, // Only today's items
            createdAt: plan.createdAt,
          );

          models.add(
            HomeCardModel(
              state: HomeCardState.reportNeeded,
              plan: planForToday,
            ),
          );
        }
      }

      if (models.isEmpty) {
        // Plans exist but nothing for today -> Quiet Day
        return [const HomeCardModel(state: HomeCardState.quietDay)];
      }

      return models;
    } catch (e) {
      debugPrint('[RealRecordRepository] Error fetching home cards: $e');
      return [const HomeCardModel(state: HomeCardState.planNeeded)];
    }
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
}
