<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 남은 개선 작업 (실행 계획)

P0/P1/P2 개선 스윕에서 **안전하게 완결·검증된 항목은 코드로 반영**했고, 아래 3개는
라이브 파일럿 앱에 대한 위험(데이터 유실·시각 검증 불가·제품 결정 필요)이 커서 별도
실행 단위로 분리한다. 각 항목은 바로 착수할 수 있도록 구체화했다.

> 이미 반영된 것: 보안 규칙(`firestore.rules`/`storage.rules`), Crashlytics+전역 에러 핸들러,
> 알림 권한 거부 처리 + 무효 FCM 토큰 정리, 미확인 실천 리마인드 함수, 하드코딩 한국어
> 에러 메시지 l10n화, 검증 트랜잭션(멱등), 테스트 스위트 전체 그린 복구.

---

## 1. (P1 #4) 콜드스타트 — 실천 메이트 대기/재참여 설계

### 현재 상태
- 솔로 사용은 이미 가능하다: 실천 메이트(`managerId`)가 없으면 플랜은 `pendingApproval`이 아니라
  즉시 `active`로 생성된다 (`plan_create_viewmodel.dart` 187–191).
- 알림 권한 상태를 조회할 수 있는 훅을 추가해 두었다:
  `NotificationService.hasPermission()` (`lib/core/services/notification_service.dart`).

### 남은 갭과 제품 결정 필요 사항
- **초대 후 미연결 재참여**: 현재 초대는 사용자가 코드를 직접 공유하는 방식이라
  "초대를 보냈지만 상대가 설치/입력하지 않은" 상태를 시스템이 알 수 없다. 재참여 알림을
  만들려면 초대 발급/전달을 추적하는 **새 데이터 흐름**이 필요하다. → 제품 결정 필요
  (딥링크 초대 + `invites` 컬렉션 도입 여부).
- **알림 OFF 배너**: 코어 루프가 FCM에 의존하므로, 권한이 꺼져 있으면 홈/우리 탭 상단에
  "알림을 켜야 실천 메이트의 확인 신호를 받을 수 있어요 · 켜기" 배너를 노출. `hasPermission()` +
  `requestPermissionAndRegister()`로 구현 가능하나, 노출 위치가 `now_tab_screen.dart`
  (대형 파일)이라 2번 리팩토링과 함께 진행 권장.

### 실행 순서 (착수 가능)
1. `lib/widgets/notification_permission_banner.dart` 신규: `hasPermission()` 감시 →
   꺼져 있으면 배너 + 켜기 버튼(`requestPermissionAndRegister()`).
2. 홈/우리 탭 상단에 배치 (2번 god-file 정리 후가 안전).
3. (제품 승인 후) 딥링크 초대 + `invites` 컬렉션 → `notifyPendingInvites` 스케줄 함수.

---

## 2. (P2 #7) `now_tab_screen.dart` (4,558줄) 분해

### 원칙
테스트 커버리지가 얕은 대형 stateful 위젯의 빅뱅 리팩토링은 회귀 위험이 크다.
**동작 보존 + 테스트로 검증되는 단위로만** 점진 추출한다.

### 안전한 1차 슬라이스 — ✅ 완료
- `PromiseProposalSheet`(+`_PromiseProposalSheetState`, 409줄)를
  `lib/features/now/presentation/widgets/promise_proposal_sheet.dart`로 **순수 이동**.
  외부 file-level 참조가 없어 자기완결적이었고, `test/widgets/promise_proposal_sheet_test.dart`
  import만 갱신해 그대로 통과(동작 보존 검증). `now_tab_screen.dart` 4,558 → 4,149줄.

### 이후 슬라이스
- 애니메이션 로직 → mixin 추출.
- 알림 스트림 구독(`StreamSubscription`) → 별도 controller.
- 카드 빌더들(`_PrimaryCard`/`_SecondaryCard`/매니저 카드) → 위젯 파일 분리.
- 각 추출마다 위젯 테스트를 먼저 추가해 동작을 고정한 뒤 이동.

---

## 3. (P2 #9) `plans` 무제한 배열 → `actions` 정규화 (라이브 데이터 마이그레이션)

### 문제
`plans` 문서에 `completedDates`/`skippedDates`/`restedDates`/`rescuedDates`/`verifiedDates`
배열이 누적된다. 장기적으로 문서 1MB 한도와 쓰기 비용 위험.

### 왜 별도 단위인가
운영 중인 Firestore 데이터를 옮기는 작업이라 **유실 위험**이 있고, 단순 코드 변경이 아니라
백필 + 듀얼 라이트 기간이 필요하다. 파일럿 데이터에 즉시 강행하지 않는다.

### 안전한 마이그레이션 절차
1. **읽기 경로를 `actions` 우선으로**: 홈 카드 상태 계산이 plan 배열 대신 `actions`를
   집계하도록 점진 전환(현재도 `actions` 문서는 생성되고 있음 — 사실상 이중 기록 상태).
2. **듀얼 라이트 유지**: 전환 기간 동안 plan 배열 + actions 둘 다 기록.
3. **백필 1회성 함수**: 기존 plan 배열 → 누락된 `actions` 문서 생성(멱등; 같은 날짜 중복 방지).
4. **검증**: 표본 사용자에 대해 두 소스의 집계 결과 일치 확인.
5. **plan 배열 쓰기 중단** → 일정 후 필드 제거(읽기 경로가 완전히 actions 기반인지 확인 후).
6. 보안 규칙의 `actions` read를 `managerId` 비정규화 + cross-user 쿼리 재작성으로 좁힐 수
   있게 된다(`docs/operations/SECURITY_RULES.md`의 잔여 리스크와 연결).

각 단계는 별도 PR로, 단계 사이에 운영 데이터로 검증 후 진행한다.

---

## 4. (P2) Pretendard 경량 폰트 자산 복구 — 코드 완료, 기기 지표 확인 대기

### 현재 상태 (2026-11-09)
- `assets/fonts/Pretendard-{Regular,Medium,Bold}.otf`를 실제 CFF OpenType **서브셋**으로
  교체했다(각 약 340KB — 기존 HTML 파일 298KB와 비슷하고 원본 1.6MB의 약 21%).
  원본은 git `438b7f7`의 Pretendard 1.301이고, 생성 스크립트는 `tool/fonts/subset_pretendard.py`.
- 포함 글리프(cmap 2,746개): ASCII·Latin-1·General Punctuation·화살표·①~⑳·CJK 괄호·
  자주 쓰는 UI 기호, 한글 호환 자모, KS X 1001 완성형 2,350자, 그리고 `lib/`·`tool/`의
  모든 `.dart`/`.arb` 문자(ARB 문구·Dart 문자열 리터럴·스토어 스크린샷 fixture).
- 일부러 뺀 것: Emoji 속성 코드포인트(❤ ☀ ♥ ✨ 등 — 넣으면 "❤️"가 컬러 이모지 대신
  단색 Pretendard 글리프로 그려진다), ZWJ·변이 선택자 등 서식 문자, BMP 밖 문자.
  이 문자들과 KS X 1001 밖의 드문 음절은 Flutter의 글리프 단위 시스템 폰트 fallback으로
  그려진다(테마에 `fontFamilyFallback`은 지정하지 않는다).
- 레이아웃 기능은 kern·mark·mkmk·ccmp·locl·tnum·case만 남기고, 힌팅을 제거하고,
  AFDKO로 CFF를 다시 서브루틴화했다(TTF 변환은 약 460KB로 더 커서 OTF 유지).
- 테마: `ThemeData(fontFamily: 'Pretendard')`가 textTheme/primaryTextTheme 전체에 적용된다.
  미사용이던 `darkTheme`에도 같은 패밀리를 지정했다.
- 라이선스: `assets/fonts/LICENSE`(SIL OFL 1.1). 폰트 name 테이블의 저작권·라이선스 필드는 유지했다.
- 테스트: `test/theme/pretendard_font_assets_test.dart`가 OTTO 시그니처·크기 상한(420KB)·
  weight class·ARB 한글/Latin 문자 커버리지·이모지 제외·테마 적용을 검사한다. ARB에
  KS X 1001 밖 음절을 넣으면 이 테스트가 실패하므로, 스크립트를 다시 돌려 서브셋을 갱신한다.
- 스토어 스크린샷 생성기는 이제 번들 Pretendard를 그대로 쓴다. 서브셋 밖 한글은
  Apple SD Gothic Neo(`ScreenshotHangulFallback`), 이모지는 Apple Color Emoji로 fallback한다.

### 완료 조건
1. ~~실제 Pretendard 파일 또는 필요한 글리프만 포함한 경량 서브셋을 준비한다.~~ 완료.
2. Android 콜드스타트와 ANR 지표가 기존 대비 악화되지 않는지 확인한다. — **남음**:
   1.2.0 내부 테스트 트랙에서 저사양 Android 기기 콜드스타트를 측정하고, 출시 후 Play Console ANR 비율을 확인한다.
3. iOS·Android 한글/영문 렌더링과 스토어 이미지 생성 테스트를 통과한다. — 스토어 이미지
   생성 테스트 통과(한글·이모지 정상 렌더 확인). 실기기 iOS·Android 육안 확인은 **남음**.
4. ~~검증 전에는 과거 1.6MB 폰트 3개를 그대로 복원하지 않는다.~~ 원본은 복원하지 않았다.
