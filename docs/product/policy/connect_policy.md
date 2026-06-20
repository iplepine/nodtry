<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `d591e92e08aca84dcec3c09187fb4ab615b1419d` (`main`)
> - 최근 커밋: `d591e92e08ac` chore: bump version to 1.0.53+75 (now-tab timing & carousel swipe)
> - 커밋 일시: `2026-06-16T10:09:48+09:00`
> - 워킹트리: `dirty (64 files)`
> - 문서 갱신: `2026-06-20 22:33:15 +0900`
<!-- COMMIT_STATUS END -->

# 파트너 연결(Connect) 정책

## 연결 방식
- 초대 코드 입력을 통한 1:1 파트너 연결
- **1인 파트너 제한**: 사용자당 하나의 활성 연결만 허용

## 연결 흐름

### 코드 입력 연결
1. 파트너의 8자리 초대 코드 입력
2. 유효성 검증:
   - 본인 코드가 아닌지 확인
   - 존재하는 코드인지 조회
   - 이미 연결된 파트너가 있는지 확인
3. `RelationModel` 생성 (양방향 2개, batch)
4. 기존 active 플랜에 매니저 자동 할당

### 클립보드 자동 감지
- 연결 화면 진입 시 클립보드에서 유효한 코드 감지
- `^[A-Z0-9]{8}$` 패턴 매칭
- 감지 시 붙여넣기 프롬프트 다이얼로그 표시

## 양방향 관계 생성 (2025-03-25 적용)
- `connectWithCode` 호출 시 relation 2개를 batch로 생성:
  - A: 초대자(코드 생성자) = Manager, 참여자(코드 입력자) = Executor
  - B: 참여자 = Manager, 초대자 = Executor
- 결과: 연결 즉시 **상호지지(함께하는 중)** 상태
- 근거: 파트너 연결은 본질적으로 상호 관계

## 연결 상태

| 상태 | 설명 |
|------|------|
| `none` | 연결 없음 |
| `pending` | 수락 대기 |
| `active` | 연결 활성 |
| `rejected` | 연결 거절됨 |

- `connectionStatusStreamProvider`를 통한 실시간 업데이트

## 상호 관계 모델 (ConnectedUser)
- `isSupported`: 상대가 나의 매니저 (지지받는 중)
- `isCheering`: 내가 상대의 매니저 (응원하는 중)
- `isMutual`: 양방향 관계 (함께하는 중)

## 연결 해제 (Disconnection)
- `connectRepository.disconnectByUser(targetUserId)`
- 해제 후 플랜의 매니저는 자동 업데이트되지 않음 (히스토리에 매니저 유지)
- 우리 탭에서 확인 다이얼로그 후 실행
- 해제 후 "연결" 프롬프트로 전환
