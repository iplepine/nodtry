import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/connect/domain/invite_code.dart' as invite;
import '../models/relation_model.dart';
import '../utils/error_reporter.dart';
import 'connect_repository.dart';
import 'invite_code_callables.dart';

/// Firestore 기반 실제 연결 데이터 저장소
///
/// Reads are participant-scoped (firestore.rules.next): relations by
/// `executorId == me` / `managerId == me`, never another user's; invite codes
/// are redeemed by the `redeemInviteCode` callable, not by querying users.
class RealConnectRepository implements ConnectRepository {
  RealConnectRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    CallableInvoker? callables,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _callables = callables ?? firebaseCallableInvoker;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CallableInvoker _callables;

  @override
  Future<String> connectWithCode(String code) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    final normalized = invite.normalizeInviteCode(code);
    if (!invite.isValidInviteCode(normalized)) {
      throw const InviteCodeNotFoundException();
    }

    try {
      final data = await _callables(kRedeemInviteCodeCallable, {
        'code': normalized,
      });
      return RedeemedInvite.fromData(data).partnerId;
    } catch (e) {
      switch (inviteCallableFailureOf(e)) {
        case InviteCallableFailure.unavailable:
          // Backend without the callable yet (works under firestore.rules
          // only; by the rules.next flip the callable is deployed).
          return _connectWithCodeDirectly(me, normalized);
        case InviteCallableFailure.notFound:
        case InviteCallableFailure.codeFormat:
          throw const InviteCodeNotFoundException();
        case InviteCallableFailure.selfCode:
          throw const InviteCodeIsMineException();
        case InviteCallableFailure.selfTaken:
          throw const InviteLinkRefusedException('self_taken');
        case InviteCallableFailure.ownerTaken:
          throw const InviteLinkRefusedException('owner_taken');
        case InviteCallableFailure.rateLimited:
        case null:
          rethrow;
      }
    }
  }

  /// The pre-callable path (builds ≤80 did only this): find the code's owner
  /// by querying users, then write both relation docs. The users query is
  /// denied under firestore.rules.next.
  Future<String> _connectWithCodeDirectly(User me, String normalized) async {
    // 1. 코드로 유저 검색
    final userQuery = await _firestore
        .collection('users')
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw const InviteCodeNotFoundException();
    }

    final targetUserId = userQuery.docs.first.id;
    if (targetUserId == me.uid) {
      throw const InviteCodeIsMineException();
    }

    // 2. Relations 생성 (양방향 — 상호지지)
    //
    // Both docs carry who shared the code (`inviterId`) and the code that was
    // used (`inviteCode`). The server's onRelationCreated uses them to pick the
    // inviter for the 연결 push and to undo a link made with a code the owner
    // no longer holds; it also enforces the 1:1 limit. Old clients write
    // neither field, so both are optional on the server side.
    final batch = _firestore.batch();
    final link = <String, Object>{
      'status': 'active',
      'inviterId': targetUserId,
      'inviteCode': normalized,
      'createdAt': FieldValue.serverTimestamp(),
      'connectedAt': FieldValue.serverTimestamp(),
    };

    // A: 초대자(Target) = Manager, 참여자(Me) = Executor
    batch.set(_firestore.collection('relations').doc(), {
      'managerId': targetUserId,
      'executorId': me.uid,
      ...link,
    });

    // B: 참여자(Me) = Manager, 초대자(Target) = Executor
    batch.set(_firestore.collection('relations').doc(), {
      'managerId': me.uid,
      'executorId': targetUserId,
      ...link,
    });

    await batch.commit();

    return targetUserId;
  }

  @override
  Future<String> generateInviteCode() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Easy-to-read alphabet + Random.secure (lib/features/connect/domain).
    final code = invite.generateInviteCode();

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
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'getConnections');
      // Rethrown, not []: "couldn't load" must not read as "no partner" —
      // a plan saved then lost its manager (and the partner their notices).
      rethrow;
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

    // 나와 상대방이 연결된 문서 찾기 (executor or manager). My relations
    // (the participant shape rules.next allows), narrowed to this partner.
    final query = await _firestore
        .collection('relations')
        .where(
          Filter.or(
            Filter('executorId', isEqualTo: me.uid),
            Filter('managerId', isEqualTo: me.uid),
          ),
        )
        .get();

    for (final doc in query.docs) {
      final data = doc.data();
      final withTarget =
          (data['executorId'] == me.uid && data['managerId'] == targetUserId) ||
          (data['executorId'] == targetUserId && data['managerId'] == me.uid);
      if (withTarget) await doc.reference.delete();
    }

    // The nickname I had for this partner must not carry over to the next
    // one. The server clears it too (onRelationDeleted); doing it here makes
    // it immediate and covers a server that isn't deployed yet.
    try {
      await _firestore.collection('users').doc(me.uid).update({
        'partnerNickname': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('[RealConnectRepository] nickname clear skipped: $e');
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
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'getConnectionStatus');
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
