<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 인증(Auth) 정책

마지막 갱신: 2026-10-03 (1.1.0+81) · 로그인 화면은 앱 이름 `둘운완`(32px) 아래 대외 문구를 보여 준다. `이메일로 계속하기`는 게스트 링크 아래 작은 텍스트 버튼으로 내려갔다. Apple 로그인(iOS)도 지원한다(`LoginType.apple`). 첫 실행 튜토리얼과 초대 단계는 [connect_policy.md](./connect_policy.md).

## 로그인 방식

### 1. 게스트 로그인 (Anonymous)
- Firebase `signInAnonymously()` 사용
- `isAnonymous = true` 상태로 표시
- 우리 탭에서 게스트 경고 배너 노출 → 계정 연동 유도
- 앱 탐색은 가능하지만, 계정 분실 시 데이터 복구 불가

### 2. Google 로그인
- **Android 전용** (UI에서 플랫폼 필터링)
- Google OAuth → Firebase Auth credential 생성
- `loginType`: `LoginType.google`

### 3. 이메일 로그인/회원가입
- 이메일 + 비밀번호 방식
- 이메일 유효성 검사: `@` 포함 필수
- 로그인/회원가입 모드 토글 지원
- `loginType`: `LoginType.email`

### 4. 자동 로그인
- 앱 실행 시 Firebase Auth 상태 확인
- 이전 인증 세션 존재 시 자동 로그인 + 캐시된 프로필 로드

## 계정 연동 (Account Linking)

### Google 연동
- 게스트/이메일 계정에 Google 계정 연결 가능
- `loginType` 업데이트 + Firestore 문서 동기화
- 에러 처리:
  - `credential-already-in-use`: 이미 다른 계정에 연결됨
  - `invalid-credential`: 유효하지 않은 인증 정보

### 이메일 연동
- 게스트 계정에 이메일/비밀번호 연결 가능
- 우리 탭에서 게스트 사용자가 연동 액션 트리거

## 회원 탈퇴 (Withdrawal)

### 앱 쪽 삭제 순서 (Cascade, `WithdrawUseCase`)
0. 모든 로컬 알림 취소
1. 내 약속 삭제 (`recordRepository.deletePlansByUserId()`)
2. 모든 관계 삭제 (`connectRepository.deleteAllRelationsByUserId()`) → 서버 `onRelationDeleted`가 짝꿍 쪽 약속의 `managerId` 해제·진행 중 내기 rejected·짝꿍 새 초대 코드
3. Firestore 사용자 문서 삭제
4. 로컬 캐시 초기화
5. Firebase Auth 계정 삭제 (`account_deleted` 기록)

### 서버 정리 (`onAuthUserDeleted`, 1.1.0 functions 신규)
Auth 계정이 지워지면 서버가 앱이 못 지운 데이터까지 정리한다. 단계마다 격리돼 하나가 실패해도 나머지는 계속한다.
- 내가 짝꿍인 타인 약속의 `managerId` 해제(해제와 같은 업데이트)
- 내 relations, 내 plans, 내 actions
- 내가 보내고 받은 cheers
- Storage `proofs/{uid}/`(인증샷 전부)와 `users/{uid}/`(프로필 이미지)
- 사용자 문서

개인정보처리방침의 "회원 탈퇴 시 인증샷 포함 모든 데이터 삭제"는 이 서버 정리를 전제로 한다. functions 배포 전에는 Storage·actions·cheers가 남을 수 있다.

### 주의사항
- 설정 화면에서 확인 다이얼로그 후 실행
- 모든 데이터 완전 삭제 (복구 불가)
- 탈퇴 후 스플래시 화면으로 리다이렉트
