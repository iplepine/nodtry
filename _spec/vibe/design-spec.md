# OnMyBehalf – 디자인 컨셉 & 컬러 스펙 (MVP)
## Warm Accountability Design System

---

## 0. 디자인 목표

OnMyBehalf의 디자인은 사용자를 통제하거나 평가하지 않는다.  
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

## 3. Material 3 컬러 시스템 (Color System)

> 컨셉: **Warm Neutral · Emotional Safety · Soft Accountability**  
> 목적: 커플 일정/계획 "따뜻한 책임감"을 **강압 없이** 전달하는 컬러 시스템

---

### 3.1 Primary — Apricot (살구)

> CTA / 주요 인터랙션 / 핵심 강조

| Tone | HEX | 권장 사용처 |
|---:|---|---|
| 0 | #2A1208 | 다크 모드 깊은 텍스트/아이콘(선택) |
| 10 | #3F1D10 | 다크 모드 텍스트/아이콘(선택) |
| 20 | #5A2A1A | 다크 모드 서브 텍스트(선택) |
| 30 | #7A3D28 | 다크 모드 보조 강조(선택) |
| 40 | #9A533D | 강조 텍스트/아이콘(선택) |
| 50 | #BC6E56 | 강조 상태(선택) |
| 60 | #D4876D | 버튼 pressed/hover 후보 |
| 70 | **#E9A38A** | **CTA 기본(추천)** |
| 80 | #F6C1A1 | 보조 강조, 선택 영역(연한 강조) |
| 90 | #FBE7DA | 카드 배경/섹션 배경 |
| 95 | #FFF3EC | 스플래시/엔트리 배경 하이라이트 |
| 99 | #FFFBF8 | 최상위 배경(크림톤) |
| 100 | #FFFFFF | 표준 화이트 |

**가이드**
- CTA: `Primary 70` (#E9A38A)
- CTA Pressed: `Primary 60` (#D4876D) 또는 `Primary 70`을 6~8% 어둡게
- 강조 배경: `Primary 90~95`
- 전체 배경: `Primary 99` 또는 `Neutral 99`

---

### 3.2 Secondary — Warm Sand (웜 샌드)

> 보조 액션 / 보조 강조 / 상태 표현

| Tone | HEX | 권장 사용처 |
|---:|---|---|
| 10 | #2E241E | 다크 모드 텍스트 |
| 20 | #46362C | 다크 모드 서브 텍스트 |
| 30 | #5E4A3D | 다크 모드 보조 |
| 40 | #776151 | 강조 텍스트 |
| 50 | #91796A | 보조 강조 |
| 60 | #AA9384 | 보조 버튼 배경 |
| 70 | #C4AD9F | 보조 버튼 기본 |
| 80 | #DFC8BB | 보조 버튼 연한 |
| 90 | #F5E4D8 | 서브 영역 배경 |

**가이드**
- 보조 버튼(Secondary): `Secondary 70~80`
- 서브 영역 배경: `Secondary 90`
- 카드 배경: `Secondary 90` 또는 `Primary 90`

---

### 3.3 Tertiary — Soft Coral (소프트 코랄)

> 감정 포인트 / 작은 피드백 / 하이라이트(과하지 않게)

| Tone | HEX | 권장 사용처 |
|---:|---|---|
| 10 | #3A1C18 | 다크 모드 텍스트 |
| 20 | #562B25 | 다크 모드 서브 |
| 30 | #733B32 | 다크 모드 보조 |
| 40 | #914D42 | 강조 텍스트 |
| 50 | #AF6659 | 보조 강조 |
| 60 | #C97F70 | 뱃지/아이콘 포인트 |
| 70 | #E39A89 | 뱃지/아이콘 포인트 |
| 80 | #F3B6A7 | 작은 강조 배경 |
| 90 | #FCE0D8 | 작은 강조 배경 |

**가이드**
- 뱃지/아이콘 포인트: `Tertiary 60~70`
- 작은 강조 배경: `Tertiary 90`
- 하단 네비게이션 활성 상태: `Tertiary 70`

---

### 3.4 Neutral — Cream & Warm Gray (뉴트럴)

> 배경/텍스트/구분선/비활성

| Tone | HEX | 권장 사용처 |
|---:|---|---|
| 0 | #000000 | 블랙 (사용 최소화) |
| 10 | **#1C1B1A** | **메인 텍스트(추천)** |
| 20 | #31302E | 본문 텍스트 |
| 30 | #494846 | 서브 텍스트 |
| 40 | #62615F | 설명/힌트 |
| 50 | #7B7976 | 비활성 텍스트 |
| 60 | #95938F | 디바이더/보더 |
| 70 | #B0ADA9 | 구분선/비활성 라인 |
| 80 | #CCC8C3 | 카드 경계/라이트 디바이더 |
| 90 | #E8E4DF | 섹션 배경 |
| 95 | #F5F1EC | 배경 보정 |
| 99 | **#FFFBF6** | **앱 기본 배경(추천)** |
| 100 | #FFFFFF | 카드/서피스 |

**가이드**
- 메인 텍스트: `Neutral 10` (#1C1B1A)
- 본문 텍스트: `Neutral 20` (#31302E)
- 서브 텍스트: `Neutral 30~40`
- 비활성 텍스트: `Neutral 50`
- 디바이더: `Neutral 60~80`
- 앱 기본 배경: `Neutral 99` (#FFFBF6)
- 카드/서피스: `Neutral 100` (#FFFFFF)

---

### 3.5 Semantic Colors (톤 맞춘 상태 컬러)

#### Error (Soft Red — 공격성 최소화)
- Error 40: `#B3261E` (에러 텍스트)
- Error 80: `#F2B8B5` (에러 배경 연한)
- Error 90: `#F9DEDC` (에러 배경 매우 연한)

**가이드**
- 에러는 최소한으로 표현
- 강한 빨강 사용 금지
- 부드러운 톤으로만 표시

#### Success (Warm Green)
- Success 40: `#4F7A61` (성공 텍스트)
- Success 80: `#B8D8C7` (성공 배경 연한)
- Success 90: `#E6F3EC` (성공 배경 매우 연한)

**가이드**
- "Did it" 버튼: `Success 80~90` 배경
- 확인 완료 상태: `Success 90` 배경
- 강한 초록 사용 금지

---

### 3.6 상태 표현 컬러 매핑

강한 색 대비를 사용하지 않는다.  
상태는 톤 차이로만 표현한다.

| 상태 | 컬러 | HEX |
|---|---|---|
| 미보고 | Neutral 70 | `#B0ADA9` |
| 보고됨 (대기) | Tertiary 80 | `#F3B6A7` |
| 확인 완료 | Success 90 | `#E6F3EC` |

❌ 빨강 / 초록 대비 금지  
⭕ 따뜻한 톤 내에서만 변화

---

## 4. UI 요소별 컬러 매핑

### 4.1 Splash & Login (Entry Point)

| UI 요소 | 컬러 | HEX |
|---|---|---|
| 전체 배경 | Neutral 99 | `#FFFBF6` |
| 로고 배경/하이라이트 | Primary 95 | `#FFF3EC` |
| 메인 헤드라인 텍스트 | Neutral 10 | `#1C1B1A` |
| 서브 카피 텍스트 | Neutral 40 | `#62615F` |
| CTA 버튼 배경 (Google/Apple) | Primary 70 | `#E9A38A` |
| CTA 버튼 텍스트 | Neutral 100 | `#FFFFFF` |
| 하단 프라이버시 문구 | Neutral 50 | `#7B7976` |
| 디바이더/얇은 라인 | Neutral 80 | `#CCC8C3` |

---

### 4.2 홈 화면 (Home Screen)

| UI 요소 | 컬러 | HEX |
|---|---|---|
| 배경 | Neutral 99 | `#FFFBF6` |
| 카드 배경 | Secondary 90 또는 Primary 90 | `#F5E4D8` / `#FBE7DA` |
| 메인 텍스트 | Neutral 10 | `#1C1B1A` |
| 서브 텍스트 | Neutral 30~40 | `#494846` / `#62615F` |
| 모드 토글 활성 | Primary 95 | `#FFF3EC` |
| 모드 토글 비활성 | 투명 | - |
| 하단 네비게이션 활성 | Tertiary 70 | `#E39A89` |
| 하단 네비게이션 비활성 | Neutral 50 | `#7B7976` |

---

### 4.3 검증 카드 (Verification Card)

| UI 요소 | 컬러 | HEX |
|---|---|---|
| 카드 배경 | Secondary 90 | `#F5E4D8` |
| 프로필 배경 | Primary 90 | `#FBE7DA` |
| 이름 텍스트 | Neutral 10 | `#1C1B1A` |
| 시간 텍스트 | Neutral 40 | `#62615F` |
| 따옴표 아이콘 | Tertiary 70 | `#E39A89` |
| 작업 설명 텍스트 | Neutral 20 | `#31302E` |
| "Didn't do it" 버튼 배경 | Neutral 100 | `#FFFFFF` |
| "Did it" 버튼 배경 | Success 90 | `#E6F3EC` |
| 버튼 텍스트 | Neutral 10 | `#1C1B1A` |

---

## 5. 컬러 사용 규칙 (중요)

### 반드시 지킬 것
- ❌ 빨강 계열 사용 금지
- ❌ 경고/에러 색상 강조 금지
- ❌ 성공/실패 이분법 표현 금지

### 권장 규칙
- 상태 변화는 명도/채도 차이로 표현
- 애니메이션은 짧고 부드럽게 (150~200ms)
- 그림자 최소화 (Elevation ≤ 2)
- Material 3 Tone 시스템 준수

---

## 6. 버튼 & 인터랙션 가이드

### 6.1 Primary Button

**상태별 컬러**
- Default: `Primary 70` (#E9A38A)
- Pressed: `Primary 60` (#D4876D) 또는 Default보다 6~8% darker
- Disabled: 배경 `Primary 90` (#FBE7DA), 텍스트 `Neutral 50` (#7B7976)
- 텍스트: `Neutral 100` (#FFFFFF)

**문구 가이드**
- ❌ 완료
- ⭕ 했어
- ⭕ 시작해볼까요?

---

### 6.2 Secondary Button

**상태별 컬러**
- Default: 배경 없음 또는 `Secondary 70` (#C4AD9F)
- Pressed: `Secondary 60` (#AA9384)
- 텍스트: `Neutral 10` (#1C1B1A)

**문구는 대화형**
- "조금 수정할게"
- "이번엔 패스할게"
- "나중에 할게"

> 명령형 문구 사용 금지.

---

### 6.3 액션 버튼 쌍 (Didn't do it / Did it)

**"Didn't do it" 버튼**
- 배경: `Neutral 100` (#FFFFFF) 또는 `Neutral 99` (#FFFBF6)
- 텍스트: `Neutral 10` (#1C1B1A)
- 아이콘: Error 40 (#B3261E) - 부드럽게
- Border: `Neutral 80` (#CCC8C3) (선택적)

**"Did it" 버튼**
- 배경: `Success 90` (#E6F3EC)
- 텍스트: `Neutral 10` (#1C1B1A)
- 아이콘: Success 40 (#4F7A61)
- 강조되지만 부드러운 느낌

두 버튼은 나란히 배치, 동일한 높이, 균등한 너비

---

### 6.4 텍스트 대비 규칙

**라이트 배경 위 텍스트**
- 메인 텍스트: `Neutral 10` (#1C1B1A)
- 본문 텍스트: `Neutral 20` (#31302E)
- 서브 텍스트: `Neutral 30~40`

**버튼(살구) 위 텍스트**
- CTA 버튼: `Neutral 100` (#FFFFFF)
- Primary 70 배경 위에는 항상 흰색 텍스트

**카드 배경 위 텍스트**
- Secondary 90 또는 Primary 90 배경 위: `Neutral 10~20`

---

## 7. Flutter Material 3 적용 가이드

### 7.1 ColorScheme 생성

```dart
// Material 3: Seed 기반 자동 스킴 생성
final colorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFE9A38A), // Primary 70 (Apricot)
  brightness: Brightness.light,
);

// 다크모드도 동일 seed로 생성 가능
final darkScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFE9A38A),
  brightness: Brightness.dark,
);
```

### 7.2 커스텀 컬러 정의

```dart
class AppColors {
  // Primary (Apricot)
  static const Color primary70 = Color(0xFFE9A38A);
  static const Color primary90 = Color(0xFFFBE7DA);
  static const Color primary95 = Color(0xFFFFF3EC);
  
  // Secondary (Warm Sand)
  static const Color secondary70 = Color(0xFFC4AD9F);
  static const Color secondary90 = Color(0xFFF5E4D8);
  
  // Tertiary (Soft Coral)
  static const Color tertiary70 = Color(0xFFE39A89);
  
  // Neutral
  static const Color neutral10 = Color(0xFF1C1B1A);
  static const Color neutral20 = Color(0xFF31302E);
  static const Color neutral40 = Color(0xFF62615F);
  static const Color neutral50 = Color(0xFF7B7976);
  static const Color neutral80 = Color(0xFFCCC8C3);
  static const Color neutral99 = Color(0xFFFFFBF6);
  static const Color neutral100 = Color(0xFFFFFFFF);
  
  // Semantic
  static const Color success40 = Color(0xFF4F7A61);
  static const Color success90 = Color(0xFFE6F3EC);
  static const Color error40 = Color(0xFFB3261E);
  static const Color error90 = Color(0xFFF9DEDC);
}
```

### 7.3 ThemeData 설정

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: colorScheme,
  scaffoldBackgroundColor: AppColors.neutral99,
  cardTheme: CardThemeData(
    color: AppColors.secondary90,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  // ... 기타 테마 설정
)
```

---

## 8. UI 스타일 가이드

### 8.1 기본 스타일
- **Radius**: 12~16
- 카드 기반 레이아웃
- 여백 넉넉하게
- 정보 밀도 낮게
- 그림자 최소화

앱이 명령하는 느낌이 아닌, 말을 거는 느낌을 유지한다.

---

### 8.2 헤더 & 네비게이션

#### 상단 헤더 구조
- **모드 토글**: 화면 상단 중앙
  - Manager / Executor 토글 버튼
  - 활성 모드: Primary 95 (`#FFF3EC`) 배경 + Neutral 10 텍스트
  - 비활성 모드: 투명 배경 + Neutral 50 텍스트
  - 둥근 모서리 (Radius: 8~12)
  
- **프로필 아이콘**: 우측 상단
  - 원형 아이콘
  - 배경: Secondary 90 또는 투명

- **제목 영역**: 헤더 하단
  - 화면 제목 (Primary Text, Bold)
  - 배지 (선택적): Warm Coral 배경 + Primary Text
  - 예: "Pending Verifications" + "3 New" 배지

---

### 8.3 카드 디자인

#### 검증 대기 카드 (Verification Card)
- **배경**: Secondary 90 (`#F5E4D8`) 또는 Primary 90 (`#FBE7DA`)
- **Radius**: 16px
- **여백**: 상하좌우 16px
- **구성 요소**:
  1. **프로필 영역** (상단)
     - 원형 프로필 이미지 (48~56px)
     - 이름 (Primary Text, Medium)
     - 시간 정보 (Secondary Text, Small)
  
  2. **작업 설명** (중앙)
     - 큰 따옴표 아이콘 (Warm Coral)
     - 작업 설명 텍스트 (Primary Text)
     - 줄바꿈 가능
  
  3. **증거 이미지** (선택적)
     - 썸네일 카드 (작은 사각형)
     - "Tap to view" 라벨
     - 배경: Warm Off White
  
  4. **액션 버튼** (하단)
     - 두 개의 버튼 나란히 배치
     - "X Didn't do it": 흰색 배경 + Primary Text + 빨간 X 아이콘
     - "Did it": Soft Sage Green 배경 + Primary Text + 초록 체크 아이콘
     - 버튼 Radius: 12px

---

### 8.4 하단 네비게이션 바

#### 구성
- 고정 하단 네비게이션
- 4개 메뉴: Inbox, Partners, History, Settings
- 아이콘 + 텍스트 레이블
- 활성 상태: Warm Coral 색상
- 비활성 상태: Secondary Text 색상
- 배경: Warm Off White 또는 Light Sand

---

### 8.5 빈 상태 (Empty State)

#### 디자인
- 중앙 정렬
- 큰 아이콘 (Thumbs-up, 64~80px)
- 아이콘 색상: Warm Coral 또는 Soft Sage Green
- 메시지: "That's all for now!" (Secondary Text)
- 여백 넉넉하게

---

### 8.6 버튼 스타일 상세

#### 액션 버튼 쌍 (Didn't do it / Did it)
- **"Didn't do it" 버튼**:
  - 배경: 흰색 또는 Warm Off White
  - 텍스트: Primary Text
  - 아이콘: X (빨간색 계열, 하지만 강하지 않게)
  - Border: Soft Gray (선택적)
  
- **"Did it" 버튼**:
  - 배경: Soft Sage Green (`#8FAE9E`)
  - 텍스트: Primary Text
  - 아이콘: 체크마크 (Primary Text)
  - 강조되지만 부드러운 느낌

두 버튼은 나란히 배치, 동일한 높이, 균등한 너비

---

## 9. 레이아웃 패턴

### 8.1 화면 구조 (일반적)
```
┌─────────────────────────┐
│ [Status Bar]            │
├─────────────────────────┤
│ [Mode Toggle] [Profile] │
│ [Title] [Badge]         │
├─────────────────────────┤
│                         │
│   [Content Cards]       │
│   (Scrollable)          │
│                         │
│   [Empty State]         │
│   (if no content)       │
│                         │
├─────────────────────────┤
│ [Bottom Navigation]     │
└─────────────────────────┘
```

### 8.2 카드 레이아웃 패턴
```
┌─────────────────────────┐
│ [Profile] Name          │
│          Time           │
├─────────────────────────┤
│ " Task Description     │
│   with quote icon"      │
├─────────────────────────┤
│ [Evidence Thumbnail]   │
│ (optional)              │
├─────────────────────────┤
│ [X Didn't] [✓ Did it]   │
└─────────────────────────┘
```

---

## 10. 감정 키워드 매핑

| 감정 | 디자인 요소 |
|---|---|
| 신뢰 | 저채도 컬러 |
| 안정 | 따뜻한 배경 |
| 응원 | 코랄 포인트 |
| 관계 | 둥근 형태 |
| 지속 | 세이지 그린 |
| 편안함 | 넉넉한 여백 |
| 명확함 | 카드 기반 구조 |

---

## 10. 타이포그래피 가이드

### 10.1 폰트 크기
- **Large Title**: 28~32px (화면 제목)
- **Headline**: 20~24px (카드 제목)
- **Body**: 16px (본문 텍스트)
- **Caption**: 12~14px (보조 정보, 시간)
- **Small**: 10~12px (배지, 라벨)

### 10.2 폰트 굵기
- **Bold**: 제목, 강조 텍스트
- **Medium**: 버튼 텍스트, 이름
- **Regular**: 본문, 설명
- **Light**: 보조 정보

### 10.3 줄 간격
- 넉넉한 줄 간격 (1.5~1.8)
- 읽기 편안함 우선

---

## 12. 아이콘 가이드

### 11.1 아이콘 스타일
- **Outline 스타일** 권장 (채워진 아이콘보다 부드러움)
- **크기**: 20~24px (일반), 48~56px (프로필)
- **색상**: Primary Text 또는 Warm Coral

### 11.2 주요 아이콘
- 따옴표 아이콘: Warm Coral
- 체크마크: Soft Sage Green 또는 Primary Text
- X 아이콘: 부드러운 빨간색 계열 (강하지 않게)
- Thumbs-up: Warm Coral

---

## 13. 애니메이션 가이드

### 12.1 전환 애니메이션
- **화면 전환**: Fade (200ms)
- **카드 등장**: Fade + Slide Up (300ms)
- **버튼 탭**: Scale (150ms)

### 12.2 피드백 애니메이션
- **버튼 탭**: 약간의 Scale (0.95 → 1.0)
- **로딩**: 부드러운 Circular Progress
- **성공/완료**: Fade + Scale (200ms)

모든 애니메이션은 **부드럽고 자연스럽게**

---

## 14. 한 문장 디자인 철학

> **OnMyBehalf는  
> 나를 통제하는 앱이 아니라,  
> 나를 믿어주는 사람의 얼굴을 닮아야 한다.**

---

## 15. 디자인 체크리스트

### 반드시 확인할 것
- ✅ 따뜻한 색상 팔레트 사용
- ✅ 넉넉한 여백과 둥근 모서리
- ✅ 명령형 문구 없음
- ✅ 강한 대비 색상 없음
- ✅ 카드 기반 레이아웃
- ✅ 부드러운 애니메이션
- ✅ 명확한 정보 계층 구조

### 절대 하지 말 것
- ❌ 빨강/초록 강한 대비
- ❌ 경고/에러 강조 색상
- ❌ 명령형 문구
- ❌ 과도한 그림자
- ❌ 복잡한 레이아웃
- ❌ 급격한 애니메이션

---


