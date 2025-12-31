# IfTogether – 지금 탭 통합 카드 & 시간 계층 스펙
## Executor-First · Primary-Secondary · Time-as-State

## 0. 문서 목적

이 문서는 IfTogether 앱의 **지금 탭**에서

- 사용자가 **지금 인지해야 할 단 하나의 행동**
- 곧 이어질 **다음 맥락**
- 실천자(Executor)와 관리자(Manager)의 **에너지 흐름 우선순위**
- 날짜가 아닌 **상태로서의 시간 표현(Time Chip)**

을 정의하는 **단일 기준 문서(Single Source of Truth)**다.

---

## 1. 지금 탭의 시간 개념

### 1.1 지금 ≠ 오늘

‘지금’은 날짜 개념이 아니다.

> 지금이란  
> 현재 시점에서  
> 사용자가 가장 먼저 인지해야 할  
> 가장 임박한 행동 또는 상태다.

### 1.2 지금 탭에 포함 가능한 시간 범위
- 오늘 남아 있는 행동
- 오늘이 끝난 경우, 가장 가까운 다음 행동  
  (내일 / 모레 / 특정 시각까지 남은 시간)

### 1.3 시간 표현 원칙
- 날짜 사용 금지
- 상대적 시간 표현만 허용

허용: `D-1`, `3시간 남음`, `곧`  
금지: `2025.01.03`, `월요일`, `오늘`

---

## 2. 카드 계층 구조

```
[ Executor Area ]
 ├─ Now Primary Card (1)
 ├─ Now Secondary Cards (0~3)

[ Manager Area ]
 ├─ Manager Quick Card (0~1)
 └─ Manager Pending Card (0~1)
```

---

## 3. Executor Area (실천자 영역)

### 3.1 Now Primary Card
- 지금 당장 필요한 행동 1개
- 버튼 허용
- 가장 큰 카드

### 3.2 Now Secondary Cards
- 다음 맥락 미리보기
- 버튼/클릭 없음
- 최대 3개

---

## 4. Manager Area (관리자 영역)

### 4.1 Manager Quick Card
- 즉시 처리할 확인 행동
- 작은 카드 + 버튼 1개

### 4.2 Manager Pending Card
- 대기 상태 안내
- 정보용

---

## 5. 카드 선택 로직 요약

1. 미완료 실천 행동
2. 확인 필요한 관리자 행동
3. 가까운 미래 행동
4. Quiet 상태

---

## 6. Time Chip 스펙

- 시간은 메시지가 아니라 상태
- Pill 형태, 클릭 불가
- NOW / UPCOMING / SOON 타입

---

## 7. 금지 규칙

- Primary Card 2개 이상 ❌
- 날짜/요일 노출 ❌
- Secondary 카드 버튼 ❌

---

## 8. 최종 정의

> 지금 탭은  
> 지금 당장 필요한 행동 하나를 중심에 두고  
> 나머지는 배경으로 정리하는 화면이다.
