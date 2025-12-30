import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';
import 'record_repository.dart';

import 'package:flutter/foundation.dart';

/// 실제 데이터 저장소 구현체 (Firestore 연동 예정)
class RealRecordRepository implements RecordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<HomeCardState>> getHomeCardStates() async {
    // TODO: Firestore에서 실제 데이터 가져오기
    return [];
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
}
