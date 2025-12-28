# OnMyBehalf – 계획 진입점 고정 UI 스펙 (항상 같은 위치)
## Persistent Plan Entry + Add New Plan While Active

---

## 0. 문서 목적

이 문서는 OnMyBehalf에서
- 계획이 없어도,
- 계획이 있어도,

사용자가 항상 같은 위치에서
계획(약속)을 새로 제안/생성할 수 있도록 하는
고정 진입점 UI를 정의한다.

---

## 1. 최종 결론

- '지금' 탭에는 항상 동일한 위치에 **Plan Rail(고정 바)** 를 둔다.
- Plan Rail은 "계획 생성"이 아니라 "새 약속 제안" 진입점이다.
- 계획이 없는 경우에는 Plan Rail이 **강조 상태**가 된다.
- 계획이 있는 경우에도 Plan Rail로 **새 약속을 추가 제안**할 수 있다.

---

## 2. 배치 위치 (항상 동일)

'지금' 탭에서 Plan Rail은 다음 위치에 고정한다.

권장 위치:
- Header 바로 아래 (상단 고정)
또는
- Executor Primary Card 바로 아래 (세로 흐름 유지)

MVP 권장:
- Header 바로 아래 (항상 보이도록)

---

## 3. Plan Rail 컴포넌트 정의

### 3.1 형태

- 얇은 가로 바 형태 (카드보다 가벼움)
- Radius: 14
- Height: 44~52
- Padding: 12~16
- 좌: 현재 약속 요약
- 우: "+ 새 약속" 버튼(칩)

---

### 3.2 기본 콘텐츠

#### Left (Summary)
- 현재 약속 상태에 따라 변함

#### Right (Action)
- "+ 새 약속" (항상 표시)
- 탭 시: 계획 생성 플로우 진입

---

## 4. 상태별 UI (중요)

Plan Rail은 3가지 상태를 가진다.

---

### 4.1 상태 A – 약속 없음 (No Active Plan)

조건:
- currentPlanId 없음
- 또는 4주 종료 + 다음 계획 없음

UI:
- Summary Text: "이번 달 약속이 아직 없어요"
- Supporting Text(선택): "한 가지 약속만 정해볼까요?"
- Action Chip: "+ 새 약속" (강조)

디자인:
- Background: Light Sand (Opacity 100%)
- Action Chip 강조 색 사용 가능

---

### 4.2 상태 B – 약속 있음 (Active Plan Exists)

조건:
- currentPlanId 존재 + APPROVED

UI:
- Summary Text: "이번 달 약속"
- Value: "운동 · 주 3회" (+ 요일이면 '월/수/금' 등)
- Action Chip: "+ 새 약속" (기본)

디자인:
- Background: Light Sand (Opacity 70~80%)
- Action Chip은 강조 낮춤

---

### 4.3 상태 C – 제안/승인 대기 (Pending Approval)

조건:
- approvalStatus = PENDING_APPROVAL

UI:
- Summary Text: "새 약속을 제안했어요"
- Value: "상대가 보고 있어요"
- Action Chip: "+ 새 약속" (표시하되, 탭 시 확인 모달)

탭 정책:
- "+ 새 약속" 탭 시
  - 모달: "이미 제안한 약속이 있어요. 또 제안할까요?"
  - 선택:
    - "이번 건 기다릴래요" (닫기)
    - "새로 제안할래요" (플로우 진입)

---

## 5. 새 약속 생성 정책 (계획이 있어도 가능)

### 5.1 여러 계획 지원 방식 (MVP 현실적 결정)

MVP에서는 "동시에 여러 활성 Plan"을 운영하지 않는다.

- APPROVED 상태의 currentPlan은 1개만 활성
- 새 약속을 제안하면:
  - 새 Plan은 DRAFT → PENDING_APPROVAL
  - 승인되면 기존 currentPlan을 ARCHIVED 처리하고 교체
  - 또는 병렬 활성은 v2에서 지원

> 사용자에게는 "추가"처럼 보이지만,
> MVP에서는 "교체 제안"으로 구현해도 사용성에 문제 없음.

---

## 6. Plan Needed 카드와의 관계

- Plan Rail: 항상 존재하는 고정 진입점
- Plan Needed Primary Card: 약속이 없을 때만 나타나는 강한 안내

즉:
- 평상시: Plan Rail로 가볍게 제안
- 비어있을 때: Plan Needed 카드로 강하게 시작 유도

---

## 7. 금지 패턴

- 하단 탭 중앙 FAB(+)로 계획 생성 고정 ❌ (투두 앱 느낌)
- '계획 만들기' 라벨을 상시 노출 ❌ (압박)
- "새 계획 추가"를 메인 카드로 상시 노출 ❌

---

## 8. 최종 정의 문장

계획 진입점은  
필요할 때만 나타나는 버튼이 아니라,  
항상 같은 위치에서  
'새 약속을 제안'할 수 있는 가벼운 레일이다.

---

