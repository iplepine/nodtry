# 플랜(Plan) 정책

## 플랜 구조

### Plan 모델
- `id`: 고유 식별자
- `userId`: 생성자/실천자
- `managerId`: 응원 파트너 (선택)
- `startDate`, `endDate`: 기간
- `state`: 현재 상태
- `items`: PlanItem 목록
- `promise`: 보상/벌칙 약속 (선택)
- `completedDates`, `verifiedDates`: 완료/확인 날짜 추적
- `lastMissedNotifiedAt`, `lastMissedItemTitle`: 놓친 약속 자동 전달 메타데이터
- `pilotNextPlanIntent`, `pilotExitReason`, `pilotSettledAt`: 4주 파일럿 정산 응답

### PlanItem 구조
- `title`: 실천 내용 (예: "30분 운동하기")
- `days`: 요일 선택 [1-7] (1=월, 7=일, 복수 선택 가능)
- `count`: 반복 목표 횟수
- `notificationTime`: 알림 설정
- `description`: 부가 설명 (선택)

## 플랜 상태 (State)

| 상태 | 설명 |
|------|------|
| `draft` | 생성됨, 아직 미활성 |
| `pending_approval` | 제출됨, 매니저 승인 대기 |
| `active` | 승인 완료, 진행 중 |
| `completed` | 기간 종료, 성공적 완료 |
| `rejected` | 매니저가 거절 (수정 필요) |
| `stopped` | 사용자가 조기 중단 |

## 플랜 생성 흐름 (3단계 위자드)

1. **행동 단계**: 공부/운동/직접 입력 카테고리와 추천 약속 또는 직접 입력
2. **설명 단계**: 파트너가 확인할 수 있는 선택 메모
3. **요일/알림 단계**: 주 3일/평일/매일 등 추천 빈도, 요일 직접 선택, 파트너에게 보일 시간, 파트너 프리뷰

## 플랜 승인 흐름

```
사용자: 플랜 생성 → pending_approval
    ↓
매니저: "승인" 탭 → active (실천 시작)
    또는
매니저: "조율" 탭 → rejected (수정 요청)
    ↓
사용자: 수정 후 재저장 → pending_approval (재승인 대기)
```

## 플랜 완료 정책

### 자동 완료
- 종료일(`endDate`)이 지난 `active`/`pending_approval` 플랜은 `completeOverduePlans()`에 의해 자동 완료
- 상태: `active` → `completed`, `pending_approval` → `completed`
- 완료된 파일럿 플랜은 Now 탭에서 4주 정산 카드로 노출하며, 다음 4주 의향 또는 종료 사유를 기록한다.

### 수동 중단
- 사용자가 직접 플랜 조기 중단 가능
- 상태: `active` → `stopped`

## 플랜 편집 정책
- 우리 탭에서 플랜 탭 → 생성 화면에 `planToEdit` 파라미터로 진입
- 편집 가능 항목: 제목, 요일, 알림 시간, 설명
- 저장 시 pending/rejected 상태는 `pending_approval`로 재전환

## 비즈니스 규칙
- 파트너 플랜은 읽기 전용 (승인/확인만 가능, 편집 불가)
- 매니저 연결 시 기존 active 플랜에 매니저 자동 할당 (`assignManagerToActivePlans()`)
- 일일 추적: 실천 요일마다 히스토리 항목 생성
