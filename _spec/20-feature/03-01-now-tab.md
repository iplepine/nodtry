
---

### 5.2 Manager Pending Card

#### 목적
관리 대기 상태 안내 (정보용)

#### 규칙
- 버튼 없음
- 클릭 없음

#### 예시
- “○○의 확인을 기다리고 있어요”

---

## 6. 카드 타입별 배치 규칙

### Primary Card 가능 타입
- Action Card (실천 필요)
- Response Card (확인 필요)
- Plan Needed Card (계획 없음)

### Secondary Card 전용
- Waiting Card
- Acknowledged Card
- Quiet Card

> 동일 타입 중복 노출 ❌

---

## 7. Primary Card 선택 로직

### 7.1 시간 기준
1. 오늘 미완료 실천 행동
2. 오늘 확인이 필요한 관리자 행동
3. 가까운 미래 행동 (D-1, 시간 단위)
4. 아무 것도 없을 경우 Quiet 상태

### 7.2 타입 우선순위
1. Response Card
2. Action Card
3. Plan Needed Card

---

## 8. Quiet 상태 정의

아래 조건을 **모두 만족**할 때만 표시:

- 미완료 실천 행동 없음
- 확인 필요 관리자 행동 없음
- 가까운 미래 행동 없음

#### 문구 예시
- “지금은 잠시 쉬어도 돼요”
- “당분간 신경 쓸 일은 없어요”

---

## 9. Time Chip 스펙 (시간 = 상태)

### 9.1 정의
> 시간은 메시지가 아니다  
> 시간은 **상태(state)**다

---

### 9.2 기본 형태
- Shape: Pill
- Padding: 6~10 (Horizontal)
- Radius: Full
- 클릭 불가

---

### 9.3 타입

#### NOW
- 문구: `지금`
- Background: Warm Coral `#F28B82`

#### UPCOMING
- 문구: `D-1`, `3시간 남음`
- Background: Light Sand (80%)

#### SOON
- 문구: `곧`
- Background: Light Sand (60%)

---

### 9.4 위치 규칙
- Executor Card: 카드 내부 상단
- Manager Card: 프로필 아이콘 근처

---

## 10. 디자인 & 애니메이션

### 크기
- Primary: Large / Padding 24 / Radius 16
- Secondary & Manager: Small / Padding 12~16 / Radius 12

### 애니메이션
- Primary 전환: Fade + Scale (200ms)
- Secondary 전환: Fade (150ms)

---

## 11. 금지 규칙 (중요)

- Primary Card 2개 이상 ❌
- Secondary Card 버튼 ❌
- Secondary Card 클릭 ❌
- 관리자 카드가 실천자 카드보다 강조 ❌
- 날짜/요일 사용 ❌
- 카운트다운 실시간 감소 ❌

---

## 12. 지금 탭 최종 정의

> **지금 탭은  
> 지금 당장 필요한 행동 하나를 크게 보여주고,  
> 조금 뒤에 신경 쓰면 될 것들을 작게 곁들여 보여주는 화면이다.**

---

## 13. Time Chip 최종 정의

> **지금 탭에서  
> 시간은 읽는 정보가 아니라,  
> 보는 순간 느껴지는 상태다.**
