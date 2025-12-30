// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/relation_model.dart';
import 'connect_repository.dart';

/// Firestore 기반 실제 연결 데이터 저장소
class RealConnectRepository implements ConnectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<void> connectWithCode(String code) async {
    // TODO: implement connectWithCode
    // 1. 코드로 유저 검색 (users collection where inviteCode == code)
    // 2. 해당 유저가 존재하면 relations 생성
    throw UnimplementedError();
  }

  @override
  Future<String> generateInviteCode() async {
    // TODO: implement generateInviteCode
    // 1. 랜덤 코드 생성
    // 2. users 컬렉션 내 정보 업데이트
    throw UnimplementedError();
  }

  @override
  Future<String?> getMyInviteCode() async {
    // TODO: implement getMyInviteCode
    // 내 정보에서 inviteCode 필드 조회
    return null;
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
    // TODO: implement watchConnectionStatus
    // relations 컬렉션에서 내가 포함된 문서 감지
    return Stream.value(ConnectionStatus.none);
  }

  @override
  Future<ConnectionStatus> getConnectionStatus() async {
    // TODO: Implement
    return ConnectionStatus.none;
  }
}
