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
