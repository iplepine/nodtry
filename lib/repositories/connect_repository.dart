import '../models/relation_model.dart';

/// 연결 상태
enum ConnectionStatus {
  none, // 연결 없음
  pending, // 연결 대기 중 (내가 보냈거나 받음)
  active, // 연결됨
  rejected, // 거절됨 (옵션)
}

/// No user holds the code that was entered.
class InviteCodeNotFoundException implements Exception {
  const InviteCodeNotFoundException();
  @override
  String toString() => 'InviteCodeNotFoundException';
}

/// The code that was entered is the user's own.
class InviteCodeIsMineException implements Exception {
  const InviteCodeIsMineException();
  @override
  String toString() => 'InviteCodeIsMineException';
}

/// The server refused the link because one of us already has a partner.
/// [reason] is the server's `self_taken` (I do) or `owner_taken` (the code's
/// owner does) — the same values a `partner_connect_failed` push carries.
class InviteLinkRefusedException implements Exception {
  const InviteLinkRefusedException(this.reason);
  final String reason;
  @override
  String toString() => 'InviteLinkRefusedException($reason)';
}

/// 1:1 짝꿍 연결 관련 데이터 저장소 인터페이스
abstract class ConnectRepository {
  /// 초대 코드 생성
  ///
  /// 8자리 코드(0/O/1/I/L 없는 알파벳, Random.secure)를 만들어 내 정보(users)에
  /// 저장하고 반환합니다.
  Future<String> generateInviteCode();

  /// 초대 코드로 연결하고 연결된 상대방(코드 주인)의 UID를 반환합니다.
  ///
  /// 코드는 정규화(공백·하이픈 제거, 대문자)해서 찾습니다. 코드 주인이 없으면
  /// [InviteCodeNotFoundException], 내 코드면 [InviteCodeIsMineException],
  /// 둘 중 누가 이미 짝꿍이 있으면 [InviteLinkRefusedException].
  /// 서버 callable `redeemInviteCode`가 양방향 relations 문서 두 개
  /// (`inviterId`·`inviteCode` 포함)를 씁니다. callable이 아직 배포되지 않은
  /// 백엔드에서는 예전처럼 users를 코드로 찾아 앱이 직접 씁니다(rules.next
  /// 전환 전에만 동작). 1:1 제한은 서버(onRelationCreated)가 강제합니다.
  Future<String> connectWithCode(String code);

  /// 내 초대 코드 조회
  Future<String?> getMyInviteCode();

  /// 연결 목록 조회
  ///
  /// 나와 관련된 모든 활성/대기 연결을 조회합니다.
  Future<List<RelationModel>> getConnections();

  /// 연결 해제. 내가 정한 짝꿍 애칭(`users/{me}.partnerNickname`)도 지운다.
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
