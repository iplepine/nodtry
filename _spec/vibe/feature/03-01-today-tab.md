# OnMyBehalf – 오늘 탭 카드 계층 스펙
## Primary Action + Secondary Upcoming Cards

---

## 0. 문서 목적

이 문서는 OnMyBehalf 앱의 **오늘 탭**에서
- 오늘 중 카드들을 어떤 "우선순위 계층"으로 보여줄지
- 각 카드가 어떤 역할과 크기를 가져야 하는지를
정의하는 단일 기준 문서다.

---

## 1. 오늘 탭 카드 계층 개념

오늘 탭의 카드들은 **중요도 기준으로 계층화**된다.

오늘의 카드 구조는 다음 질문에 답한다.

- 지금 당장 필요한 행동은 무엇인가?
- 조금 뒤에 신경 쓰면 될 건 무엇인가?

이 두 질문의 답을 **크기와 위치**로 표현한다.

---

## 2. 카드 계층 구조 (고정)

오늘 탭에는 아래 두 계층의 카드만 존재한다.

```
[ Today Primary Card ] ← 크게, 1개
[ Today Secondary Cards ] ← 작게, 1~3개
[ This Week Preview ] ← 가로 스크롤 (선택)
```

---

## 3. Today Primary Card (지금 당장 카드)

### 목적
- 지금 이 순간 **반드시 필요한 단 하나의 행동**을 제시한다.

### 규칙
- 오늘 탭에 **항상 최대 1개**
- 버튼은 이 카드에만 허용
- 사용자가 즉시 행동할 수 있어야 함

### 크기
- Height: Large
- Padding: 24
- Radius: 16

### 예시 카드 문구
- "오늘 할 일이 있어요" [했어]
- "전달받은 말이 있어요" [확인하기]
- "이번 달 계획이 아직 없어요" [계획 짜기]

---

## 4. Today Secondary Cards (조금 뒤 카드)

### 목적
- 오늘 안에 발생할 수 있는 **후속 맥락**을 미리 보여준다.
- 행동을 요구하지 않는다.

### 규칙
- 1~3개까지 허용
- 버튼 없음
- 클릭 없음
- 단순 정보 전달만 가능

### 크기
- Height: Small
- Padding: 12~16
- Radius: 12

### 예시 카드 문구
- "전달했어요. 확인을 기다리고 있어요"
- "확인됐어요. 고마워요"
- "오늘은 조용한 하루예요"

---

## 5. 카드 타입 배치 규칙

### Primary Card로 올 수 있는 타입
- Action Card (보고 필요)
- Response Card (확인 필요)
- Plan Needed Card (계획 필요)

### Secondary Card로만 올 수 있는 타입
- Waiting Card (확인 대기)
- Acknowledged Card (확인 완료)
- Quiet Card (정보용)

> 동일한 타입의 카드는 중복 노출하지 않는다.

---

## 6. 카드 선택 및 배치 로직

### Step 1. Primary Card 결정
아래 우선순위로 **1개 선택**한다.

1. Response Card (확인 필요)
2. Action Card (보고 필요)
3. Plan Needed Card (계획 없음)

---

### Step 2. Secondary Cards 구성
Primary Card에 포함되지 않은 상태 중,
의미 있는 상태를 **최대 3개까지** 선택한다.

선택 기준:
- 오늘 안에 상태 변화 가능성 있음
- 사용자에게 안심 또는 맥락 제공

---

## 7. 디자인 가이드

### 시각적 위계
1. Today Primary Card (가장 큼)
2. Today Secondary Cards (작음)
3. This Week Preview (가장 약함)

### 컬러
- Primary Card:
  - Background: Theme A Surface (Soft Dark Stone #DFD9D4)
- Secondary Cards:
  - Background: Theme A Surface (Opacity 0.6~0.7)
- Manager Quick Card:
  - Background: Theme A Surface (Opacity 0.6, 실천자보다 약함)
  - 프로필 아이콘: Theme A Primary (Velvet Wine Plum #552A3E)
- 버튼:
  - Theme A Primary (Velvet Wine Plum #552A3E)
  - Pressed: Theme A Primary Pressed (Deep Velvet Wine #462232)

### 애니메이션
- Primary Card 전환: Fade + Scale (200ms)
- Secondary Card 전환: Fade (150ms)

---

## 8. 오늘 탭 금지 규칙 (중요)

- Primary Card 2개 이상 ❌
- Secondary Card에 버튼 ❌
- Secondary Card 클릭 ❌
- 카드 리스트 스크롤 과다 ❌

오늘 탭은 **우선순위를 보여주는 화면**이지  
할 일을 쌓아두는 화면이 아니다.

---

## 9. 오늘 탭 한 문장 정의 (최종)

> **오늘 탭은  
> 지금 당장 필요한 행동 하나를 크게 보여주고,  
> 조금 뒤에 신경 쓰면 될 것들을 작게 곁들여 보여주는 화면이다.**

---
