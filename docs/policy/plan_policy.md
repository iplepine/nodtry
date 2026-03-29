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

## 플랜 생성 흐름 (4단계 위자드)

1. **행동 단계**: 실천할 행동 입력 (필수, 빈 값 불가)
2. **요일 선택 단계**: 월~일 중 실천 요일 선택
3. **알림 설정 단계**: 알림 시간 설정 (프리셋/커스텀/없음)
4. **설명 단계** (선택): 추가 메모 작성

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
- 종료일(`endDate`)이 지난 active 플랜은 `completeOverduePlans()`에 의해 자동 완료
- 상태: `active` → `completed`

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
