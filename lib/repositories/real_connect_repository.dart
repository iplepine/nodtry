// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/relation_model.dart';
import 'connect_repository.dart';

/// Firestore 기반 실제 연결 데이터 저장소
class RealConnectRepository implements ConnectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<String> connectWithCode(String code) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    // 1. 코드로 유저 검색
    final userQuery = await _firestore
        .collection('users')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('User not found');
    }

    final targetUserDoc = userQuery.docs.first;
    final targetUserId = targetUserDoc.id;

    // 2. 이미 연결되어 있는지 확인 (옵션)
    // (MVP에서는 일단 중복 체크 없이 생성하거나, 클라이언트에서 필터링)

    // 3. Relations 생성 (양방향 — 상호지지)
    final batch = _firestore.batch();

    // A: 초대자(Target) = Manager, 참여자(Me) = Executor
    batch.set(_firestore.collection('relations').doc(), {
      'managerId': targetUserId,
      'executorId': me.uid,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'connectedAt': FieldValue.serverTimestamp(),
    });

    // B: 참여자(Me) = Manager, 초대자(Target) = Executor
    batch.set(_firestore.collection('relations').doc(), {
      'managerId': me.uid,
      'executorId': targetUserId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'connectedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return targetUserId;
  }

  @override
  Future<String> generateInviteCode() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Simple 8-char random code (UPPERCASE + DIGITS)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final code = List.generate(
      8,
      (index) => chars[rnd.nextInt(chars.length)],
    ).join();
    // Ideally use Random.secure() but simple logic for now

    // Check uniqueness omitted for MVP (Low collision probability for small scale)

    await _firestore.collection('users').doc(user.uid).update({
      'inviteCode': code,
    });

    return code;
  }

  @override
  Future<String?> getMyInviteCode() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['inviteCode'] as String?;
  }

  @override
  Future<List<RelationModel>> getConnections() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // 1. 내가 executor인 경우 (내가 지지받음)
      final executorQuery = await _firestore
          .collection('relations')
          .where('executorId', isEqualTo: user.uid)
          .get();

      // 2. 내가 manager인 경우 (내가 응원함)
      final managerQuery = await _firestore
          .collection('relations')
          .where('managerId', isEqualTo: user.uid)
          .get();

      final list = <RelationModel>[];
      list.addAll(
        executorQuery.docs.map((doc) => RelationModel.fromFirestore(doc)),
      );
      list.addAll(
        managerQuery.docs.map((doc) => RelationModel.fromFirestore(doc)),
      );

      return list;
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(ConnectionStatus.none);

    return _firestore
        .collection('relations')
        .where(
          Filter.or(
            Filter('executorId', isEqualTo: user.uid),
            Filter('managerId', isEqualTo: user.uid),
          ),
        )
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            // 하나라도 연결되면 active로 간주 (MVP)
            // 실제로는 status 필드 체크 필요 (pending vs active)
            return ConnectionStatus.active;
          }
          return ConnectionStatus.none;
        });
  }

  @override
  Future<void> disconnectByUser(String targetUserId) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    // 나와 상대방이 연결된 문서 찾기 (executor or manager)
    final query = await _firestore
        .collection('relations')
        .where(
          Filter.or(
            Filter.and(
              Filter('executorId', isEqualTo: me.uid),
              Filter('managerId', isEqualTo: targetUserId),
            ),
            Filter.and(
              Filter('executorId', isEqualTo: targetUserId),
              Filter('managerId', isEqualTo: me.uid),
            ),
          ),
        )
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<ConnectionStatus> getConnectionStatus() async {
    final user = _auth.currentUser;
    if (user == null) return ConnectionStatus.none;

    try {
      final query = await _firestore
          .collection('relations')
          .where(
            Filter.or(
              Filter('executorId', isEqualTo: user.uid),
              Filter('managerId', isEqualTo: user.uid),
            ),
          )
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return ConnectionStatus.active;
      }
      return ConnectionStatus.none;
    } catch (e) {
      return ConnectionStatus.none;
    }
  }

  @override
  Future<void> deleteAllRelationsByUserId(String uid) async {
    try {
      final query = await _firestore
          .collection('relations')
          .where(
            Filter.or(
              Filter('executorId', isEqualTo: uid),
              Filter('managerId', isEqualTo: uid),
            ),
          )
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      // debugPrint('[RealConnectRepository] Deleted ${query.size} relations for user $uid');
    } catch (e) {
      // debugPrint('[RealConnectRepository] Error deleting relations: $e');
      rethrow;
    }
  }
}
