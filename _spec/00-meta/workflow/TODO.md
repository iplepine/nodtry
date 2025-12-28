# OnMyBehalf MVP - TODO 리스트

## 📊 전체 진행 상황

**완료율: 약 60-70%**

### ✅ 완료된 영역
- UI/UX 구조 및 화면 레이아웃 (90%)
- 디자인 시스템 (85%)
- 스펙 문서화 (95%)

### 🔄 진행 중인 영역
- 데이터 모델링 (20%)
- 비즈니스 로직 설계 (30%)

### ❌ 미완료 영역
- 백엔드 연동 (0%)
- 실제 데이터 처리 (10%)
- 인증 시스템 (10%)

---

## 🎯 우선순위별 TODO

### 🔴 P0 - 핵심 기능 (MVP 필수)

#### 1. 데이터 모델 정의 (Domain Layer)
**상태:** 미시작  
**예상 시간:** 2-3일

- [ ] `Plan` 모델 정의
  - 4주 관리 기간
  - 주 N회 수행
  - 요일 선택
  - 승인 상태
  - 실행자/관리자 정보

- [ ] `Report` 모델 정의
  - 수행 보고
  - 보고 시간
  - 선택적 메모
  - 검증 대기 상태

- [ ] `Verification` 모델 정의
  - 검증 결과 (✅/❌)
  - 검증 시간
  - 선택적 코멘트

- [ ] `Relationship` 모델 정의
  - 연결된 사용자 정보
  - 관계 별칭
  - 현재 관리 기간
  - 1:N 관리 구조 지원

- [ ] `User` 모델 정의
  - 사용자 기본 정보
  - 현재 모드 (실행자/관리자)
  - 연결된 관계 목록

**참고 문서:**
- `_spec/00-meta/mvp-spec.md`
- `_spec/10-domain/role-mode-spec.md`
- `_spec/00-meta/architecture-spec.md`

---

#### 2. 핵심 비즈니스 로직 구현 (UseCase)

**상태:** 미시작  
**예상 시간:** 3-4일

##### 2.1 계획 관리
- [ ] `CreatePlanDraftUseCase`
  - 실행자가 계획 초안 작성
  - 입력: 주 N회, 요일 선택
  - 출력: 계획 초안 생성

- [ ] `ApprovePlanUseCase`
  - 관리자가 계획 승인/반려
  - 입력: 계획 ID, 승인/반려, 코멘트
  - 출력: 계획 상태 변경

- [ ] `UpdatePlanUseCase` (관리자 전용)
  - 승인된 계획 수정
  - 권한 검증 포함

##### 2.2 수행 및 보고
- [ ] `CreateReportUseCase`
  - 실행자가 수행 보고 생성
  - 입력: 계획 ID, 선택적 메모
  - 출력: 보고 생성, 검증 대기 상태

- [ ] `GetCurrentActionUseCase`
  - 지금 탭에서 현재 행동 조회
  - Primary Card 선택 로직
  - 시간 기반 우선순위 계산

##### 2.3 검증 및 확인
- [ ] `VerifyReportUseCase`
  - 관리자가 보고 검증
  - 입력: 보고 ID, 검증 결과 (✅/❌), 코멘트
  - 출력: 검증 완료, 성공/실패 상태

- [ ] `GetPendingVerificationsUseCase`
  - 관리자 모드: 대기 중인 검증 목록
  - Manager Quick Card용

##### 2.4 관계 관리
- [ ] `CreateRelationshipUseCase`
  - 초대 코드 생성/입력
  - 관계 생성

- [ ] `GetRelationshipsUseCase`
  - 연결된 관계 목록 조회
  - 우리 탭용

- [ ] `SwitchModeUseCase`
  - 실행자/관리자 모드 전환
  - UI 권한 변경

**참고 문서:**
- `_spec/00-meta/mvp-spec.md` (4-5장)
- `_spec/10-domain/role-mode-spec.md`

---

#### 3. Repository 인터페이스 정의

**상태:** 미시작  
**예상 시간:** 1일

- [ ] `PlanRepository` 인터페이스
  - `createPlanDraft()`
  - `approvePlan()`
  - `updatePlan()`
  - `getCurrentPlan()`
  - `getPlansByRelationship()`

- [ ] `ReportRepository` 인터페이스
  - `createReport()`
  - `getReportsByPlan()`
  - `getPendingReports()`

- [ ] `VerificationRepository` 인터페이스
  - `verifyReport()`
  - `getVerificationsByReport()`

- [ ] `RelationshipRepository` 인터페이스
  - `createRelationship()`
  - `getRelationships()`
  - `getRelationshipById()`

- [ ] `UserRepository` 인터페이스
  - `getCurrentUser()`
  - `updateUserMode()`

**참고 문서:**
- `_spec/00-meta/architecture-spec.md`

---

#### 4. Firebase 백엔드 연동 (Data Layer)

**상태:** 미시작  
**예상 시간:** 4-5일

##### 4.1 Firebase 설정
- [ ] Firebase 프로젝트 생성
- [ ] Flutter 프로젝트에 Firebase 추가
- [ ] `firebase_core`, `cloud_firestore` 패키지 추가

##### 4.2 Firestore 데이터 구조 설계
- [ ] `users` 컬렉션 구조
- [ ] `relationships` 컬렉션 구조
- [ ] `plans` 컬렉션 구조
- [ ] `reports` 컬렉션 구조
- [ ] `verifications` 컬렉션 구조

##### 4.3 RemoteDataSource 구현
- [ ] `PlanRemoteDataSource`
  - Firestore CRUD 연동
  - 실시간 업데이트 리스너

- [ ] `ReportRemoteDataSource`
- [ ] `VerificationRemoteDataSource`
- [ ] `RelationshipRemoteDataSource`
- [ ] `UserRemoteDataSource`

##### 4.4 LocalDataSource 구현 (선택)
- [ ] 로컬 캐싱 전략
- [ ] 오프라인 지원

**참고 문서:**
- `_spec/00-meta/architecture-spec.md`

---

#### 5. 인증 시스템 구현

**상태:** 10% 완료  
**예상 시간:** 2-3일

- [ ] Google 로그인 실제 구현
  - `google_sign_in` 패키지 연동
  - Firebase Authentication 연동
  - 현재: `lib/screens/splash_screen.dart`, `lib/screens/login_screen.dart`에 TODO

- [ ] Apple 로그인 실제 구현
  - `sign_in_with_apple` 패키지 연동
  - iOS 설정
  - 현재: `lib/screens/splash_screen.dart`, `lib/screens/login_screen.dart`에 TODO

- [ ] 자동 로그인 로직
  - 세션 관리
  - 토큰 갱신
  - 현재: `lib/screens/splash_screen.dart`에 TODO

- [ ] 로그아웃 기능

**참고 문서:**
- `_spec/20-feature/01-splash-login.md`

---

### 🟡 P1 - 중요 기능 (MVP 핵심 UX)

#### 6. 지금 탭 데이터 연동

**상태:** UI 완료, 데이터 연동 필요  
**예상 시간:** 2일

**현재 상태:**
- UI 구조 완성 (`lib/screens/tabs/now_tab.dart`)
- 임시 테스트 데이터 사용 중
- TODO 주석 다수 존재

- [ ] 실제 데이터에서 상태 가져오기
  - `_loadHomeState()` 메서드 구현
  - `GetCurrentActionUseCase` 연동

- [ ] Primary Executor Card 데이터 연동
  - `reportNeeded`, `planNeeded` 상태 계산
  - 시간 정보 연동

- [ ] Secondary Executor Card 데이터 연동
  - `waitingForCheck`, `checked`, `quietDay` 상태 계산
  - 과거 시간 표현 계산 (`formatTimePast()`)

- [ ] Manager Quick Card 데이터 연동
  - `checkNeeded` 상태 계산
  - 관리 대상 이름 가져오기
  - 프로필 이미지 연동

- [ ] Quiet 상태 조건 확인
  - 실제 데이터 기반 Quiet 상태 판단

- [ ] 버튼 액션 구현
  - "했어" 버튼 → `CreateReportUseCase` 호출
  - "확인하기" 버튼 → 검증 화면으로 이동
  - "계획 짜기" 버튼 → 계획 생성 플로우 진입

**참고 문서:**
- `_spec/20-feature/03-01-now-tab.md`
- `_spec/20-feature/03-02-now-tab-executor-manager.md`

---

#### 7. 계획 작성/승인 플로우

**상태:** 미시작  
**예상 시간:** 3-4일

- [ ] 계획 작성 화면
  - 주 N회 입력
  - 요일 선택 UI
  - 초안 저장

- [ ] 계획 승인 화면 (관리자)
  - 계획 초안 미리보기
  - 승인/반려 버튼
  - 반려 시 코멘트 입력

- [ ] 계획 수정 화면 (관리자 전용)
  - 승인된 계획 수정
  - 권한 검증

- [ ] 플로우 연결
  - 지금 탭 "계획 짜기" → 계획 작성 화면
  - 우리 탭 "새 계획 시작" → 계획 작성 화면

**참고 문서:**
- `_spec/00-meta/mvp-spec.md` (4.1장)

---

#### 8. 검증/확인 화면

**상태:** 미시작  
**예상 시간:** 2일

- [ ] 검증 화면 (관리자)
  - 보고 내용 표시
  - ✅ 했다 / ❌ 안 했다 버튼
  - 선택적 코멘트 입력
  - `VerifyReportUseCase` 호출

- [ ] 확인 완료 화면 (실행자)
  - 검증 결과 표시
  - 관리자 코멘트 표시

**참고 문서:**
- `_spec/00-meta/mvp-spec.md` (5.1장)

---

#### 9. Connect 화면 데이터 연동

**상태:** UI 완료, 데이터 연동 필요  
**예상 시간:** 1일

**현재 상태:**
- UI 구조 완성 (`lib/screens/connect_screen.dart`)
- 임시 연결 시뮬레이션 사용 중

- [ ] 초대 코드 생성 로직
  - 고유 코드 생성
  - Firestore에 저장
  - 공유 기능 구현

- [ ] 초대 코드 입력 및 검증
  - 코드 유효성 검증
  - 관계 생성 (`CreateRelationshipUseCase`)

- [ ] 연결 대기 상태
  - 실시간 연결 상태 확인
  - 연결 완료 시 홈 화면으로 이동

**참고 문서:**
- `_spec/20-feature/02-connect.md`

---

#### 10. 기록 탭 데이터 연동

**상태:** UI 완료, 데이터 연동 필요  
**예상 시간:** 1-2일

**현재 상태:**
- UI 구조 완성 (`lib/screens/tabs/history_tab.dart`)
- 임시 데이터 모델 사용 중

- [ ] 기록 데이터 조회
  - 날짜별 기록 목록
  - `GetReportsByPlan()` 연동

- [ ] 기록 항목 표시
  - 날짜 포맷팅 (다국어 지원)
  - 상태 표시 ("했어", "확인됐어요", "이번엔 못 했어")
  - 코멘트 표시

- [ ] 빈 상태 처리
  - 기록이 없을 때 UI

**참고 문서:**
- `_spec/20-feature/03-home.md` (3장)

---

#### 11. 우리 탭 데이터 연동

**상태:** UI 완료, 데이터 연동 필요  
**예상 시간:** 1-2일

**현재 상태:**
- UI 구조 완성 (`lib/screens/tabs/us_tab.dart`)
- 임시 데이터 모델 사용 중

- [ ] 연결된 사람 목록 조회
  - `GetRelationshipsUseCase` 연동
  - 이름, 상태 표시

- [ ] 관계 관리 기능
  - 새 사람 초대 (Connect 화면으로 이동)
  - 연결 해제
  - 관계 설명

- [ ] 계획 요약 표시
  - 현재 4주 계획 상태
  - "새 계획 시작" 버튼 (조건부)

- [ ] 설정 섹션
  - Quiet Header 설정 버튼 연결

**참고 문서:**
- `_spec/20-feature/03-home.md` (4장)

---

#### 12. Quiet Header 데이터 연동

**상태:** UI 완료, 데이터 연동 필요  
**예상 시간:** 0.5일

**현재 상태:**
- UI 구조 완성 (`lib/widgets/quiet_header.dart`)
- 하드코딩된 값 사용 중

- [ ] 관계 정보 표시
  - 현재 선택된 관계 이름
  - 관계 별칭 (있는 경우)

- [ ] 기간 정보 표시
  - "4주 중 · 2주차" 계산
  - 계획 없음 상태
  - 기간 종료 상태

- [ ] 설정 버튼 연결
  - 우리 탭의 설정 섹션으로 이동

**참고 문서:**
- `_spec/20-feature/04-header.md`

---

### 🟢 P2 - 개선 및 최적화

#### 13. 모드 전환 UI 구현

**상태:** 미시작  
**예상 시간:** 1-2일

- [ ] 모드 토글 UI
  - 앱 상단 또는 헤더에 배치
  - "내가 하는 중" / "내가 관리 중" 토글
  - `SwitchModeUseCase` 호출

- [ ] 관리자 모드: 관리 대상 선택 UI
  - 드롭다운 또는 Chip Selector
  - 최근 활동한 대상 기본 선택
  - 관리 대상별 데이터 필터링

**참고 문서:**
- `_spec/10-domain/role-mode-spec.md`

---

#### 14. 시간 계산 및 표시 로직 개선

**상태:** 부분 완료  
**예상 시간:** 1일

**현재 상태:**
- `TimeFormatter` 유틸리티 클래스 존재 (`lib/utils/time_formatter.dart`)
- `formatTimePast()` 메서드 추가됨
- 일부 로직은 임시 데이터 사용

- [ ] 실제 시간 데이터 연동
  - 계획 일정 기반 시간 계산
  - 보고 시간 기반 경과 시간 계산
  - 확인 시간 기반 경과 시간 계산

- [ ] Time Chip 로직 개선
  - NOW, UPCOMING, SOON, PAST 타입 정확한 판단
  - 시간 표현 정확도 향상

**참고 문서:**
- `_spec/20-feature/03-01-now-tab.md` (11장)

---

#### 15. 애니메이션 및 전환 효과 개선

**상태:** 기본 완료  
**예상 시간:** 1일

- [ ] 카드 전환 애니메이션 최적화
  - 현재: 기본 Fade/Scale 애니메이션
  - 더 부드러운 전환 효과

- [ ] 화면 전환 애니메이션
  - 계획 작성 → 승인 플로우
  - 보고 → 검증 플로우

---

#### 16. 에러 처리 및 예외 상황

**상태:** 미시작  
**예상 시간:** 2일

- [ ] 네트워크 에러 처리
  - 오프라인 상태 감지
  - 재시도 로직

- [ ] 데이터 검증
  - 입력값 유효성 검사
  - 권한 검증

- [ ] 사용자 피드백
  - 에러 메시지 표시
  - 로딩 상태 표시

---

#### 17. 테마 시스템 확장

**상태:** 기본 완료  
**예상 시간:** 0.5일

- [ ] Theme B (Deep Olive × Sand) 완전 구현
  - 현재: 색상 정의만 존재
  - 실제 적용 및 테스트

- [ ] 테마 선택 기능 (선택)
  - 사용자가 테마 선택 가능하도록

**참고 문서:**
- `_spec/50-ui/design-spec.md`

---

### 🔵 P3 - 추가 기능 (MVP 이후)

#### 18. 푸시 알림

**상태:** 미시작

- [ ] Firebase Cloud Messaging 설정
- [ ] 알림 타입 정의
  - 보고 알림 (관리자)
  - 검증 완료 알림 (실행자)
  - 계획 승인 알림 (실행자)

---

#### 19. 통계 및 분석 (MVP 제외)

**참고:** MVP 스펙에 명시적으로 제외됨
- 포인트, 랭킹, 게임화 요소
- 통계/대시보드

**참고 문서:**
- `_spec/00-meta/mvp-spec.md` (7장)

---

## 📝 코드베이스 TODO 현황

### 파일별 TODO 개수

1. **`lib/screens/tabs/now_tab.dart`** - 15개 TODO
   - 가장 많은 TODO
   - 데이터 연동 전반

2. **`lib/screens/splash_screen.dart`** - 8개 TODO
   - 인증 로직 전반

3. **`lib/screens/connect_screen.dart`** - 3개 TODO
   - 연결 로직

4. **`lib/screens/tabs/history_tab.dart`** - 3개 TODO
   - 기록 데이터 연동

5. **`lib/screens/tabs/us_tab.dart`** - 3개 TODO
   - 관계 데이터 연동

6. **`lib/widgets/quiet_header.dart`** - 1개 TODO
   - 헤더 데이터 연동

7. **`lib/screens/login_screen.dart`** - 2개 TODO
   - 인증 로직

8. **`lib/theme/app_colors.dart`** - 2개 TODO
   - 다크 모드 색상

---

## 🎯 다음 스프린트 제안

### Sprint 1 (1주)
1. 데이터 모델 정의 (Domain Layer)
2. Repository 인터페이스 정의
3. 핵심 UseCase 구현 (계획, 보고, 검증)

### Sprint 2 (1주)
1. Firebase 설정 및 연동
2. RemoteDataSource 구현
3. 인증 시스템 구현

### Sprint 3 (1주)
1. 지금 탭 데이터 연동
2. 계획 작성/승인 플로우
3. 검증/확인 화면

### Sprint 4 (1주)
1. Connect 화면 데이터 연동
2. 기록 탭 데이터 연동
3. 우리 탭 데이터 연동
4. 모드 전환 UI

---

## 📚 참고 문서

- [MVP 스펙](../mvp-spec.md)
- [역할 모드 스펙](../../10-domain/role-mode-spec.md)
- [디자인 스펙](../../50-ui/design-spec.md)
- [아키텍쳐 스펙](../architecture-spec.md)
- [화면 스펙](../../20-feature/)

---

**마지막 업데이트:** 2025-01-XX  
**다음 리뷰:** 매주 월요일

