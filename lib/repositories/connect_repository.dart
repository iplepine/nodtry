import '../models/relation_model.dart';

/// 연결 상태
enum ConnectionStatus {
  none, // 연결 없음
  pending, // 연결 대기 중 (내가 보냈거나 받음)
  active, // 연결됨
  rejected, // 거절됨 (옵션)
}

/// 커플 연결 관련 데이터 저장소 인터페이스
abstract class ConnectRepository {
  /// 초대 코드 생성
  ///
  /// 6자리 영문/숫자 조합 코드를 생성하여 반환합니다.
  /// 내 정보(users)에 저장됩니다.
  Future<String> generateInviteCode();

  /// 코드로 연결 요청
  ///
  /// 상대방의 코드를 입력하여 연결을 요청합니다.
  /// relations 컬렉션에 문서를 생성합니다.
  Future<void> connectWithCode(String code);

  /// 내 초대 코드 조회
  Future<String?> getMyInviteCode();

  /// 연결 목록 조회
  ///
  /// 나와 관련된 모든 활성/대기 연결을 조회합니다.
  Future<List<RelationModel>> getConnections();

  /// 연결 해제
  Future<void> disconnectByUser(String targetUserId);

  /// 연결 상태 스트림
  ///
  /// relations 컬렉션의 변화를 감지하여 연결 상태를 반환합니다.
  Stream<ConnectionStatus> watchConnectionStatus();

  /// 현재 연결 상태 조회 (단발성)
  Future<ConnectionStatus> getConnectionStatus();

  /// 특정 유저의 모든 연결(Relations)을 삭제합니다. (회원 탈퇴 처리용)
  Future<void> deleteAllRelationsByUserId(String uid);
}
