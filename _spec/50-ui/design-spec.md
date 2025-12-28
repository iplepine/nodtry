# IfTogether – 디자인 컨셉 & 컬러 스펙 (MVP)
## Warm Accountability Design System

---

## 0. 디자인 목표

IfTogether의 디자인은 사용자를 통제하거나 평가하지 않는다.  
대신 **믿고 맡기며, 조용히 응원하는 관계의 톤**을 전달한다.

이 앱은:
- ❌ 강압적인 자기관리 앱이 아니다
- ⭕ 관계 기반 책임(Accountability) 설계 도구다

---

## 1. 디자인 컨셉

### 컨셉 명
**Warm Accountability (따뜻한 책임감)**

### 한 줄 정의
> 압박하지 않고, 신뢰로 맡기며, 조용히 응원하는 디자인

### 사용자가 느껴야 할 감정
- "관리당하고 있다" ❌
- "믿어주고 있네" ⭕
- "혼자가 아니다" ⭕
- "괜히 더 해보고 싶다" ⭕

---

## 2. 심리 기반 디자인 원칙

| 항목 | 원칙 |
|---|---|
| 색상 | 저채도, 따뜻한 색 |
| 대비 | 강하지 않게 |
| 강조 | 포인트 최소화 |
| 실패 표현 | 없음 또는 중립 |
| 성공 표현 | 축하 ❌ / 인정 ⭕ |

디자인의 기본값은 **자극이 아니라 안정**이다.

---

## 3. 멀티 테마 컬러 시스템 (Multi-Theme Color System)

> IfTogether는 여러 테마 팔레트를 지원합니다.  
> 사용자가 상황에 맞는 테마를 선택할 수 있습니다.

---

### 3.1 Theme A — Velvet Wine Plum × Dark Stone

> 컨셉: **"집중하게 만드는 관리자 색"**  
> "따르게 만드는 색"이 아니라 **"집중하게 만드는 관리자 색"**

#### Foundation (Base)

| Role | Name | HEX | 사용처 |
|---|---:|---|---|
| Background | Dark Warm Stone | `#EEEAE6` | 화면 전체 배경 |
| Surface | Soft Dark Stone | `#DFD9D4` | 카드, 바텀시트 |
| Divider | Stone Line | `#D2CBC6` | 구분선 |

#### Primary (관리자 핵심 에너지)

| Role | Name | HEX | 정책 |
|---|---:|---|---|
| Primary | Velvet Wine Plum | `#552A3E` | 주요 CTA, 선택 강조 |
| Primary Pressed | Deep Velvet Wine | `#462232` | Press / Active |
| Primary Soft | Muted Wine Plum | `#6E4156` | 배지·포커스 (제한적) |

⚠️ **Primary Soft는 면적 5% 이하**  
⚠️ 성공/보상 색 아님 → **"수용/확인" 의미만**

#### Secondary & Neutral

| Role | HEX | 사용처 |
|---|---:|---|
| Secondary | `#C9C1BB` | 보조 버튼 |
| Outline | `#CCC4BE` | 버튼 테두리 |
| Disabled | `#B5ADA8` | 비활성 요소 |

#### Text Colors

| Role | HEX | 대비 |
|---|---:|---|
| Text / Primary | `#201A1D` | 본문 |
| Text / Secondary | `#6E6469` | 설명 |
| Text / Disabled | `#A29A9E` | 비활성 |

#### Accent (매혹 포인트 · 선택)

| Role | HEX | 규칙 |
|---|---:|---|
| Accent Wine | `#6A1F2B` | 아이콘·선택 상태, ≤5% |
| Accent Ink Violet | `#3A2A46` | 포커스/전환 순간, ≤400ms |

#### ❌ 금지 규칙 (고정)
- 쨍한 레드 ❌
- 핑크/코랄 ❌
- 그라데이션 ❌
- 상태 색(에러/성공)으로 Wine 사용 ❌

---

### 3.2 Theme B — Deep Olive × Sand

> 컨셉: **단단함 · 책임감 · 안정적인 섹시함**  
> 운동 / 습관 / 실행자에게 특히 잘 맞는 톤

#### Foundation (Base)

| Role | Name | HEX | 사용처 |
|---|---:|---|---|
| Background | Soft Sand | `#F3F1ED` | 화면 전체 배경 |
| Surface | Warm Sand | `#E7E3DC` | 카드, 바텀시트 |
| Divider | Sand Line | `#DED8D0` | 구분선 |

#### Primary

| Role | Name | HEX | 정책 |
|---|---:|---|---|
| Primary | Deep Olive | `#5F6F63` | 주요 CTA |
| Primary Pressed | Dark Olive | `#4E5C52` | Press / Active |

#### Secondary & Neutral

| Role | HEX | 사용처 |
|---|---:|---|
| Secondary | `#D2CCC3` | 보조 버튼 |

#### Text Colors

| Role | HEX | 대비 |
|---|---:|---|
| Text / Primary | `#2E2F2C` | 본문 |
| Text / Secondary | `#767A74` | 설명 |
| Text / Disabled | `#B1B4AE` | 비활성 |

---

### 3.3 테마 선택 가이드

#### Theme A (Velvet Wine Plum) 사용 시기
- 관리자 모드 중심
- 집중과 책임감 강조가 필요한 경우
- "수용/확인" 의미를 전달할 때

#### Theme B (Deep Olive) 사용 시기
- 실행자 모드 중심
- 운동/습관 관리
- 안정적이고 단단한 느낌이 필요할 때

---

### 3.4 Semantic Colors 원칙

#### Error (공격성 최소화)
- 에러는 최소한으로 표현
- 강한 빨강 사용 금지
- 부드러운 톤으로만 표시

#### Success (상태 표현)
- 성공/보상 색 아님
- "수용/확인" 의미만
- 강한 초록 사용 금지

---

### 3.5 상태 표현 원칙

강한 색 대비를 사용하지 않는다.  
상태는 톤 차이로만 표현한다.

❌ 빨강 / 초록 대비 금지  
❌ 상태 색으로 Wine 사용 금지  
⭕ 따뜻한 톤 내에서만 변화

---

## 4. 컬러 사용 규칙 (중요)

### 반드시 지킬 것 (Theme A 기준)
- ❌ 쨍한 레드 사용 금지
- ❌ 핑크/코랄 사용 금지
- ❌ 그라데이션 사용 금지
- ❌ 상태 색(에러/성공)으로 Wine 사용 금지
- ❌ 경고/에러 색상 강조 금지
- ❌ 성공/실패 이분법 표현 금지
- ⚠️ Primary Soft는 면적 5% 이하
- ⚠️ Accent 색상은 제한적 사용 (≤5%, ≤400ms)

### 권장 규칙
- 상태 변화는 명도/채도 차이로 표현
- 애니메이션은 짧고 부드럽게 (150~200ms)
- 그림자 최소화 (Elevation = 0)
- Primary는 "수용/확인" 의미만 (성공/보상 아님)

---

## 5. UI 스타일 가이드

### 5.1 기본 스타일
- **Radius**: 12~16
- 카드 기반 레이아웃
- 여백 넉넉하게
- 정보 밀도 낮게
- 그림자 최소화

앱이 명령하는 느낌이 아닌, 말을 거는 느낌을 유지한다.

---

## 6. 감정 키워드 매핑

| 감정 | 디자인 요소 |
|---|---|
| 신뢰 | 저채도 컬러 |
| 안정 | 따뜻한 배경 (Dark Warm Stone) |
| 집중 | Velvet Wine Plum (관리자 색) |
| 관계 | 둥근 형태 |
| 지속 | Primary Soft (제한적) |
| 편안함 | 넉넉한 여백 |
| 명확함 | 카드 기반 구조 |

---

## 7. 타이포그래피 가이드

### 7.1 폰트 크기
- **Large Title**: 28~32px (화면 제목)
- **Headline**: 20~24px (카드 제목)
- **Body**: 16px (본문 텍스트)
- **Caption**: 12~14px (보조 정보, 시간)
- **Small**: 10~12px (배지, 라벨)

### 7.2 폰트 굵기
- **Bold**: 제목, 강조 텍스트
- **Medium**: 버튼 텍스트, 이름
- **Regular**: 본문, 설명
- **Light**: 보조 정보

### 7.3 줄 간격
- 넉넉한 줄 간격 (1.5~1.8)
- 읽기 편안함 우선

---

## 8. 아이콘 가이드

### 8.1 아이콘 스타일
- **Outline 스타일** 권장 (채워진 아이콘보다 부드러움)
- **크기**: 20~24px (일반), 48~56px (프로필)
- **색상**: Text Primary 또는 Primary

### 8.2 아이콘 사용 원칙
- 부드럽고 강하지 않은 느낌
- Accent 색상은 제한적 사용 (≤5%)
- 포커스/전환 아이콘은 짧은 시간만 사용 (≤400ms)

---

## 9. 애니메이션 가이드

### 9.1 전환 애니메이션
- **화면 전환**: Fade (200ms)
- **카드 등장**: Fade + Slide Up (300ms)
- **버튼 탭**: Scale (150ms)

### 9.2 피드백 애니메이션
- **버튼 탭**: 약간의 Scale (0.95 → 1.0)
- **로딩**: 부드러운 Circular Progress
- **성공/완료**: Fade + Scale (200ms)

모든 애니메이션은 **부드럽고 자연스럽게**

---

## 10. 한 문장 디자인 철학

### Theme A (Velvet Wine Plum × Dark Stone)
> **Velvet Wine Plum × Dark Stone은  
> "따르게 만드는 색"이 아니라  
> "집중하게 만드는 관리자 색"이다.**

### Theme B (Deep Olive × Sand)
> **단단함 · 책임감 · 안정적인 섹시함  
> 운동 / 습관 / 실행자에게 특히 잘 맞는 톤**

### 공통 철학
> **OnMyBehalf는  
> 나를 통제하는 앱이 아니라,  
> 나를 믿어주는 사람의 얼굴을 닮아야 한다.**

---

## 11. 디자인 체크리스트

### 반드시 확인할 것
- ✅ Velvet Wine Plum × Dark Stone 팔레트 사용 (Theme A)
- ✅ 넉넉한 여백과 둥근 모서리
- ✅ 명령형 문구 없음
- ✅ 강한 대비 색상 없음
- ✅ 카드 기반 레이아웃 (그림자 없음)
- ✅ 부드러운 애니메이션
- ✅ 명확한 정보 계층 구조
- ✅ Primary Soft, Accent 색상 제한적 사용 (≤5%)

### 절대 하지 말 것
- ❌ 쨍한 레드 사용
- ❌ 핑크/코랄 사용
- ❌ 그라데이션 사용
- ❌ 상태 색으로 Wine 사용
- ❌ 경고/에러 강조 색상
- ❌ 명령형 문구
- ❌ 그림자 사용 (Elevation = 0)
- ❌ 복잡한 레이아웃
- ❌ 급격한 애니메이션

---


