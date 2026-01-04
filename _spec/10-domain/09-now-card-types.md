# nod-try – 지금 탭 통합 카드 & 시간 계층 스펙
## 핵심 카드 타입 정의 (Mine & Yours)

## 0. 문서 목적

이 문서는 nod-try 앱의 **지금 탭**에서 사용되는 카드 타입을 **Mine(나의 활동)**과 **Yours(너의 활동)**으로 구분하여 정의하고, 각 카드의 노출 조건, 표시 항목, 인터랙션을 규정한다.

### 📜 카드 타입 요약

#### 1. Mine (나의 활동)
*   **EmptyPlan**: 계획이 아예 없을 때 생성 유도 (CTA)
*   **NowAction**: 지금 바로 해야 할 내 약속 (Executor)
*   **Overdue**: 시간이 조금 지난 내 약속 (Executor - Low Pressure)
*   **TodayComplete**: 오늘의 할 일을 모두 마친 상태 (Completion)
*   **TodayEmpty**: 오늘은 일정이 없는 여유로운 날 (Information)
*   **NextAction**: 지금은 아니지만, 곧 다가오는 일정 안내 (Information)

#### 2. Yours (너의 활동)
*   **PlanCreate**: 파트너의 새로운 약속 제안 (Manager)
*   **PlanModify**: 파트너의 약속 수정/조정 요청 (Manager)
*   **Action**: 파트너의 실천 인증 및 피드백 (Response)

---

## 1. Mine (나의 활동)

### 1-1. EmptyPlan (계획 없음)
**활성 계획이 하나도 없는 상태**

- **노출 조건**: 활성 계획 및 한 달 내 실천 예정 없음
- **메시지**: "지금은 약속이 없어요", "한 가지 약속만 정해볼까요?"
- **행동**: 계획 추가 화면(Plan Rail / CTA)으로 이동
- **성격**: 명확한 진입 유도 (CTA)

### 1-2. NowAction (지금 실천)
**지금 가장 가까운 시일 내 실천해야 할 항목**

- **노출 조건**: 아직 실천하지 않음, 현재 시점 기준 가장 임박한 1개 (Primary)
- **표시 항목**: 제목, 상세 설명, 시간 칩(Vague Time), 상태 메시지
- **인터랙션**:
    - **확장**: 카드 터치 시 액션 영역 확장
    - **액션**: `했어` (완료), `오늘은 넘어가자` (스킵)

### 1-3. Overdue (기한 지남)
**시간이 조금 지났지만 아직 할 수 있는 내 실천**

- **노출 조건**: 실천 시간이 지남 + 아직 처리하지 않음
- **메시지 톤**: "지금 선택해도 괜찮아요", "늦게라도 챙겨볼까요?" (부드러운 독려)
- **액션**: `했어` (뒤늦은 완료), `오늘은 넘어가자` (스킵)

### 1-4. TodayComplete (오늘 완료)
**오늘의 할 일을 모두 마침**

- **노출 조건**: 오늘의 모든 할 일을 완료함
- **메시지**: "오늘 다 했어요 🙌"
- **성격**: 성취감 및 완료 상태 확인

### 1-5. TodayEmpty (오늘 일정 없음)
**계획은 있지만, 오늘은 쉬는 날**

- **노출 조건**: 활성 계획 존재 + 오늘 해당되는 요일/날짜 아님
- **메시지**: "오늘은 여유로운 날이에요"
- **성격**: 안심과 휴식 강조

### 1-6. NextAction (다음 일정)
**지금 당장은 아니지만, 곧 다가오는 일정이 있을 때**

- **노출 조건**: 오늘은 할 일이 없거나 완료했음 + 내일 등 가까운 미래에 계획이 있음
- **메시지**: "내일 일정", "다가오는 약속" 등
- **표시 내용**: 다음 일정의 날짜, 시간, 제목
- **성격**: 흐름이 끊기지 않도록 미리보기 제공

---

## 2. Yours (너의 활동)

### 2-1. PlanCreate (계획 제안)
**파트너가 새로운 약속을 제안함**

- **메시지**: "이런 약속을 제안했어요"
- **표시 내용**: 파트너 프로필, 제안된 계획 요약
- **성격**: 인지 및 확인 (Manager Role)

### 2-2. PlanModify (계획 수정)
**파트너가 약속 내용 변경을 요청하거나 거절함**

- **메시지**: "이번엔 이렇게 하기로 했어요", "조금 조정 중이에요"
- **성격**: 상태 변경 공유

### 2-3. Action (실천 피드백)
**파트너가 실천을 인증하고 반응을 기다림**

- **노출 조건**: 파트너가 실천 기록 생성 + 내가 아직 확인 안 함
- **표시 내용**: **파트너 프로필(필수)**, 실천 요약, 시간, 상태
- **액션 (피드백)**:
    - `그래`: 단순 확인 (Nod)
    - `응원해요`: 긍정적 강화
- **성격**: 관리보다는 **관계와 반응**에 집중 (Response Role)

---

## 3. UI Guidelines (Visual Refinements)
- **Action Button**: `ElevatedButton`의 Vertical Padding을 줄여(12px) 날렵한 느낌 유지.
- **Partner Profile**: Yours 그룹(Type 2-x)의 카드에는 반드시 파트너 프로필 이미지를 노출하여 '누구의 소식'인지 명확히 인지시킴.
- **Alignment**: 모든 텍스트와 콘텐츠는 **좌측 정렬(Left Align)**을 기본으로 하여 일관성 유지.

---

## 4. 카드 노출 및 우선순위 정책 (Display Policy)

### 4-1. Mine Area (나의 활동)
**Primary Slot(1개) + Secondary Slot(n개)** 구조를 가지며, 다음 우선순위와 구성 규칙을 따른다.

**1. Primary Slot 우선순위**
1.  **NowAction** (지금 실천)
2.  **Overdue** (기한 지남)
3.  **TodayComplete / TodayEmpty** (오늘 완료/없음)
4.  **EmptyPlan** (계획 없음)

**2. 가능한 카드 구성 (Scenarios)**
Mine 영역은 다음 4가지 경우의 수로만 구성된다.

*   **Case 0: EmptyPlan**
    *   Primary: `EmptyPlan`
    *   Secondary: 없음
*   **Case 1: NowAction + Overdue**
    *   Primary: `NowAction`
    *   Secondary: `Overdue`
    *   *(NextAction은 이 경우 노출하지 않음)*
*   **Case 2: Overdue + NextAction**
    *   Primary: `Overdue` (NowAction이 없을 때 승격됨)
    *   Secondary: `NextAction`
*   **Case 3: TodayComplete/TodayEmpty + NextAction**
    *   Primary: `TodayComplete` 또는 `TodayEmpty`
    *   Secondary: `NextAction`

### 4-2. Yours Area (너의 활동)
*   **구성**: 파트너의 요청/알림이 있는 만큼 **여러 개 노출 가능**.
*   **순서**: 중요도(Response > Decision) 또는 시간순 정렬.

> **Note**: 내가 제안한 약속(Proposed by Me)은 별도의 승인 대기 카드 없이, 즉시 **Mine Area(NowAction/NextAction)**에 편성되어 바로 실천할 수 있다.
