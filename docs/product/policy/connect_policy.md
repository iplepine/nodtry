<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 실천 메이트 연결(Connect) 정책

## 연결 방식
- 초대 코드 입력과 양쪽의 동의를 통한 상호 1:1 실천 메이트 연결
- **1인 실천 메이트 제한**: 사용자당 하나의 활성 연결만 허용
- 연결은 서로의 실천을 확인하고 응원하기 위한 지원 관계이며, 상대를 감시하거나 통제하기 위한 관계가 아니다.

## 연결 흐름

### 코드 입력 연결
1. 실천 메이트의 8자리 초대 코드 입력
2. 유효성 검증:
   - 본인 코드가 아닌지 확인
   - 존재하는 코드인지 조회
   - 이미 연결된 실천 메이트가 있는지 확인
3. `RelationModel` 생성 (양방향 2개, batch)
4. 기존 active 플랜의 `managerId`에 실천 메이트 자동 할당

### 클립보드 자동 감지
- 연결 화면 진입 시 클립보드에서 유효한 코드 감지
- `^[A-Z0-9]{8}$` 패턴 매칭
- 감지 시 붙여넣기 프롬프트 다이얼로그 표시

## 양방향 관계 생성 (2025-03-25 적용)
- `connectWithCode` 호출 시 relation 2개를 batch로 생성:
  - A: 초대자(코드 생성자) = Manager, 참여자(코드 입력자) = Executor
  - B: 참여자 = Manager, 초대자 = Executor
- 결과: 연결 즉시 **상호지지(함께하는 중)** 상태
- 근거: 실천 메이트 연결은 양쪽이 동의하고 서로를 지원하는 상호 관계

## 연결 상태

| 상태 | 설명 |
|------|------|
| `none` | 연결 없음 |
| `pending` | 수락 대기 |
| `active` | 연결 활성 |
| `rejected` | 연결 거절됨 |

- `connectionStatusStreamProvider`를 통한 실시간 업데이트

## 상호 관계 모델 (ConnectedUser)
- `isSupported`: 상대가 나의 Manager 역할 (지지받는 중)
- `isCheering`: 내가 상대의 Manager 역할 (응원하는 중)
- `isMutual`: 양방향 관계 (함께하는 중)

## 연결 해제 (Disconnection)
- `connectRepository.disconnectByUser(targetUserId)`
- 해제 후 플랜의 `managerId`는 자동 업데이트되지 않음 (히스토리에 기존 값 유지)
- 우리 탭에서 확인 다이얼로그 후 실행
- 해제 후 "연결" 프롬프트로 전환
