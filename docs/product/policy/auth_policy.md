<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 인증(Auth) 정책

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

### 삭제 순서 (Cascade)
1. 사용자의 모든 플랜 삭제 (`recordRepository.deletePlansByUserId()`)
2. 모든 관계/연결 삭제 (`connectRepository.deleteAllRelationsByUserId()`)
3. Firestore 사용자 문서 삭제
4. 로컬 캐시 초기화
5. Firebase Auth 계정 삭제

### 주의사항
- 설정 화면에서 확인 다이얼로그 후 실행
- 모든 데이터 완전 삭제 (복구 불가)
- 탈퇴 후 스플래시 화면으로 리다이렉트
