import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  /// 앱 시작/로그인 시 사용자 데이터 동기화 (없으면 생성)
  Future<void> initializeUser(User user);

  /// 내 프로필 조회
  Future<UserModel?> getMyProfile();

  /// 내 프로필 실시간 감지 (Stream)
  Stream<UserModel?> watchMyProfile();

  /// 여러 사용자 프로필 조회. uid마다 문서 하나씩 병렬로 읽는다 (users 목록
  /// 쿼리는 firestore.rules.next에서 거부). 없거나 못 읽은 프로필은 빠진다.
  Future<List<UserModel>> getUsersByIds(List<String> uids);

  /// 초대 코드 주인 조회 (`resolveInviteCode` callable; 확인 시트에 보일
  /// uid·이름·사진만 채워진다). 형식이 틀리거나 주인이 없으면 null, 내
  /// 코드면 InviteCodeIsMineException. 그 밖의 실패(오프라인, 요청 제한)는
  /// 그대로 던진다.
  Future<UserModel?> getUserByInviteCode(String code);

  /// 프로필 업데이트 (이름, 상태 메시지, 이미지)
  /// null 파라미터는 업데이트하지 않음을 의미 (일부 필드만 수정 가능)
  Future<void> updateProfile({
    String? name,
    String? statusMessage,
    String? imagePath,
  });

  /// 회원 탈퇴 (데이터 삭제)
  Future<void> deleteUser(String uid);

  /// FCM 토큰 업데이트
  Future<void> updateFcmToken(String uid, String token);

  /// FCM 토큰 제거 (알림 권한 거부/철회 시, 죽은 토큰으로의 전송 방지)
  Future<void> clearFcmToken(String uid);

  /// 내가 짝꿍을 부르는 애칭(`users/{me}.partnerNickname`)을 저장한다.
  /// null이나 빈 값이면 필드를 지운다. 10자를 넘으면 잘라서 저장한다.
  Future<void> updatePartnerNickname(String? nickname);

  /// 기존 사용자 1회 공지를 봤다고 기록한다(`users/{me}.pivotNoticeSeen`).
  /// 베스트 에포트 — 기기 플래그가 우선이다.
  Future<void> markPivotNoticeSeen();

  /// Records that I agreed to the terms of use (`users/{me}.termsAcceptedAt`,
  /// `termsVersion`) when connecting with a partner or sending an invite.
  /// Best-effort; never throws.
  Future<void> markTermsAccepted();
}
