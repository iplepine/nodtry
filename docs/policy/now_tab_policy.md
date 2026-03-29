# 지금 탭(Now Tab) 정책

## 개요
현재 실천 상황과 파트너 피드백을 실시간으로 보여주는 카드 기반 UI.

## 카드 유형

### 내 카드 (CardRole.mine)

| 상태 | 설명 |
|------|------|
| `nowAction` | 오늘 예정된 실천 항목 |
| `emptyPlan` | 활성 플랜 없음 (생성 유도 CTA) |
| `nextAction` | 다음 예정된 실천 정보 |
| `todayEmpty` | 오늘은 실천 항목 없음 (안내) |
| `todayComplete` | 오늘 모든 실천 완료 |
| `overdue` | 플랜 기간 종료됨 |
| `poked` | 파트너에게 똑똑 받음 |
| `rejected` | 플랜 거절됨, 수정 필요 |
| `promiseProposed` | 보상/벌칙 제안 받음 |
| `promiseSettled` | 보상/벌칙 결과 확인 |

### 파트너 카드 (CardRole.yours)

| 상태 | 설명 |
|------|------|
| `partnerPlanCreate` | 파트너가 새 플랜 제안 |
| `partnerPlanModify` | 파트너가 플랜 수정 |
| `partnerAction` | 파트너가 실천 완료 보고 |
| `partnerNoPlan` | 파트너에게 활성 플랜 없음 |
| `partnerPoke` | 파트너가 아직 미실천 (똑똑 유도) |
| `partnerPromiseProposed` | 내가 파트너에게 보상/벌칙 제안함 |

## 카드 우선순위 (Primary Card)

내 카드 우선순위:
1. **Tier 0 (긴급)**: rejected / poked / promiseProposed / promiseSettled
2. **Tier 1 (현재)**: nowAction
3. **Tier 2 (지연)**: overdue
4. **Tier 4 (완료)**: todayComplete / todayEmpty
5. **Tier 5 (유도)**: emptyPlan

Secondary 카드: Primary가 nowAction일 때 overdue, nextAction 노출

## 사용자 인터랙션

### 내 실천 액션
| 버튼 | 동작 | 결과 |
|------|------|------|
| "했어" | 오늘 실천 완료 보고 | 노트 입력 다이얼로그 → 히스토리 `done` 생성 |
| "건너뛸게" | 오늘 건너뜀 | 히스토리 `skipped` 생성 |

### 파트너 액션
| 버튼 | 동작 | 결과 |
|------|------|------|
| "시작 응원" | 파트너 플랜 승인 | pending_approval → active |
| "실천 확인" | 파트너 실천 검증 | status → `verified` |
| "응원하기" | 리액션 보내기 | 이모지 선택 + 메시지 (선택) |
| "똑똑! 하기" | 파트너에게 알림 | 메시지 + 약속 제안 (선택) |

### 거절 응답 (rejected 상태)
- 다이얼로그 옵션:
  - "횟수 줄이기"
  - "시간 변경"
  - "직접 수정" (플랜 생성 화면 이동)

### 리액션 유형
- fire, heart, thumbs_up, muscle

## 헤더 정보
- 파트너 이름 표시
- 기간 상태: inProgress (활성 플랜 있음) / noPlan (없음)
- 주차 추적: 현재 주 / 전체 주

## 애니메이션
- 카드 로드: Fade + Scale (300ms, easeOutBack)
- 완료 시: Scale up 1.05 → 축소 (카드 제거)
- 카드 전환: Smooth fade
