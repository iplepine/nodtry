# 약속(Promise) 보상/벌칙 정책

## 개요
플랜 실천에 대한 보상과 벌칙을 파트너 간 합의하여 동기를 부여하는 시스템.

## Promise 모델 구조
- `reward`: 보상 설명 + 달성 기준 일수
- `penalty`: 벌칙 설명 + 발동 기준 일수
- `proposerId`: 제안자
- `status`: 상태

## 상태 흐름

```
proposed (제안됨)
    ↓ 수락
active (양측 합의)
    ↓ 플랜 종료
settled (결과 확정)

proposed → rejected (거절됨)
```

| 상태 | 설명 |
|------|------|
| `proposed` | 한쪽이 제안, 상대 응답 대기 |
| `active` | 양측 동의, 적용 중 |
| `settled` | 플랜 종료, 결과 산정 완료 |
| `rejected` | 상대가 거절 |

## 정산 결과 (Settlement)

| 결과 | 조건 |
|------|------|
| `rewardAchieved` | 보상 기준 일수 달성 |
| `penaltyTriggered` | 벌칙 기준 일수 미달 |
| `bothMet` | 보상/벌칙 조건 모두 충족 |
| `neitherMet` | 어느 조건도 충족하지 않음 |

## 정산 로직
- 플랜 완료(`completed`) 또는 중단(`stopped`) 시 자동 계산
- `completedDates` 대비 전체 플랜 기간으로 산정
- 결과는 양측 모두에게 `promiseSettled` 카드로 표시

## 제안 시점
- 어느 쪽이든 제안 가능
- 똑똑(Poke)과 함께 제안 가능
- 지금 탭에서 카드로 노출

## Active 상태 노출 (Now 탭 카드 내 chip)

수락 직후 ~ 정산 전(`status == active`) 기간 동안, Now 탭의 실행자 카드(`nowAction` / `poked` / `overdue`) **액션 버튼 바로 위**에 한 줄 chip을 노출한다.

### 표시 우선순위 (위에 있을수록 강한 강조)
1. **벌칙 확정** (`success + remaining < penalty.targetDays`): `⚡ 벌칙 발동 확정 — {설명}` (주황 강조)
2. **벌칙 임박** (failureBuffer ≤ 1): `⚡ N번만 더 실패하면 벌칙 — {설명}` (주황 강조)
3. **보상 달성** (`success >= reward.targetDays`): `🏆 보상 달성! — {설명}` (primary 강조)
4. **보상 임박** (rewardNeeded ≤ 2): `🏆 보상까지 N일 더 성공하면 — {설명}` (primary 강조)
5. **양쪽 안전**: `🏆 보상까지 X일 · ⚡ 벌칙까지 Y번 여유` (회색)
6. **한쪽만 존재**: 해당 한쪽만 회색조로 표시

### 계산
- 성공일 = `plan.completedDayCount()`
- 남은 예정일 = `plan.remainingScheduledDayCount()`
- `rewardNeeded = max(0, reward.targetDays - 성공일)` — 보상까지 더 필요한 성공 일수
- `failureBuffer = (성공일 + 남은) - penalty.targetDays` — 더 실패해도 되는 횟수 (음수 = 이미 확정)

### 탭 동작
chip 탭 → 풀 조건 바텀시트:
- 헤더: "약속 조건" + 진행 요약 (성공 X / 실패 Y / 남은 Z)
- 보상/벌칙 각각 카드: 설명 + 진행 바 + 조건 텍스트
- 닫기 버튼

### 의도
"건너뛸게" 옆에 작은 위협 + 작은 보상이 보이도록 하기 위함. **추상적 수치(5/7)가 아니라 "남은 거리 + 구체 결과"** 로 표현해 결정에 영향 미치도록 함.

## 제안 화면 기준
- 제안 화면은 플랜 전체 기간과 보상/벌칙 정산 기준이 되는 실천 예정일 수를 함께 보여준다.
- 보상 달성 일수는 `현재 성공일 + 남은 예정일` 안에서만 조절할 수 있다.
- 벌칙 발동 일수는 `현재 실패일 + 남은 예정일` 안에서만 조절할 수 있다.
- 기본값은 상한에 딱 붙이지 않는다. 보상은 남은 예정일을 전부 성공해야 하는 값보다 낮게, 벌칙은 이미 실패한 날에서 바로 발동되지 않게 여유를 둔다.
- 저장 시에도 `targetDays`가 현재 상태에서 도달 가능한 상한을 넘으면 거부한다.
