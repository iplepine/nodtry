import 'dart:async';
import 'dart:math';

import '../models/relation_model.dart';
import 'connect_repository.dart';

/// Mock 연결 데이터 저장소
class MockConnectRepository implements ConnectRepository {
  // 모의 데이터 메모리 저장소
  String? _myInviteCode;
  ConnectionStatus _status = ConnectionStatus.none;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final List<RelationModel> _mockRelations = [];

  MockConnectRepository() {
    // 초기 상태 emit
    _statusController.add(_status);
  }

  @override
  Future<String> generateInviteCode() async {
    // 0.5초 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    // 랜덤 6자리 코드 생성 (영대문자 + 숫자)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final code = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    _myInviteCode = code;
    return code;
  }

  @override
  Future<void> connectWithCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (code == 'ERROR') {
      throw Exception('Invalid code');
    }

    // 연결 성공 시뮬레이션
    // 실제로는 'pending' 상태가 되어야 하지만,
    // Mock에서는 편의상 바로 active가 되거나,
    // User B가 되어 연결 요청을 보낸 상황이라면 pending이 됨.
    // 여기서는 "연결 요청을 보냄 -> pending"으로 설정
    _status = ConnectionStatus.pending;
    _statusController.add(_status);

    // 3초 후 연결 완료 시뮬레이션 (선택적)
    Future.delayed(const Duration(seconds: 3), () {
      _status = ConnectionStatus.active;
      _statusController.add(_status);
    });
  }

  @override
  Future<String?> getMyInviteCode() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _myInviteCode;
  }

  @override
  Future<List<RelationModel>> getConnections() async {
    return []; // 일단 빈 리스트 반환
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() async* {
    yield _status;
    yield* _statusController.stream;
  }

  @override
  Future<void> disconnectByUser(String targetUserId) async {
    // 목업: 해당 유저와의 관계 삭제 시뮬레이션
    _mockRelations.removeWhere(
      (r) =>
          r.executorId == targetUserId && r.managerId == 'current_user_id' ||
          r.managerId == targetUserId && r.executorId == 'current_user_id',
    );
  }

  @override
  Future<ConnectionStatus> getConnectionStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _status;
  }

  @override
  Future<void> deleteAllRelationsByUserId(String uid) async {
    // Mock: 딜레이만
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
