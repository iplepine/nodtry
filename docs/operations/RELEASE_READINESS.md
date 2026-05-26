# 출시 준비 체크리스트

## 제품
- 첫 실행에서 가입, 프로필, 파트너 연결, 플랜 생성이 막힘 없이 이어진다.
- 지금 탭의 빈 상태, 오늘 할 일, 완료, 지연, 파트너 카드가 모두 확인되었다.
- 플랜 승인, 조율, 수정, 중단, 자동 완료가 정상 동작한다.
- 히스토리 기록과 파트너 확인이 양측에 반영된다.
- 보상/벌칙 약속 제안과 정산 카드가 노출된다.

## 알림
- 로컬 알림 권한 요청과 스케줄링을 확인했다.
- 원격 알림 토큰 등록과 주요 이벤트 알림을 확인했다.
- 알림 비활성화와 플랜 종료 시 알림 취소를 확인했다.

## 데이터
- 양방향 relation 생성이 중복 없이 동작한다.
- 1인 파트너 제한이 적용된다.
- 플랜, 히스토리, 약속 데이터가 계정 삭제 또는 연결 해제 상황에서 예상대로 남거나 정리된다.

## 품질
- 주요 화면에서 로딩, 오류, 빈 상태가 있다.
- Android와 iOS에서 핵심 루프를 각각 1회 이상 수동 검증했다.
- 개인정보 처리방침, 이용약관, 문의 채널을 준비했다.

## 최근 내부 테스트 배포
- 2026-05-26: `1.0.45+67` Android production 배포 완료. 약속 상세 화면을 대거 보강. (1) "진행 현황" 카드를 정보 행 아래·실천 기록 위에 상시 노출 — 큰 글자로 성공률(완료 플랜: 성공/예정, 진행 중: 성공/(성공+실패)) + 진행 바와 연속 달성·실천·남음(완료된 플랜이면 놓침) 3-메트릭, promise가 붙어 있으면 같은 카드 안에 🏆 보상 / ⚡ 벌칙 진행 바와 "보상까지 N일 더 필요" / "벌칙까지 N번 여유" / "벌칙 발동 확정" 상태 문구까지 그린다(`ActivePromiseChip`과 동일한 success/remaining 기준). 종전 `_buildSummaryReport`(완료 플랜 한정)는 제거. (2) 기록 탭 캘린더 시인성 개선 — 색깔만으로 구분하면 헷갈린다는 피드백을 반영해 셀을 (배경색 + 아이콘 + 테두리 패턴) 조합으로 재설계. done은 mint 솔리드 + 흰 ✓, missed는 coral 솔리드 + 흰 ✕로 정반대 강한 시그널을 주고, rested(시안톤 + 달 아이콘) / rescued(흰 배경 + mint 2px 테두리 + ✓) / skipped(옅은 회색 + 빗금 + 취소선 숫자) / scheduled(옅은 mint 얇은 테두리) / notScheduled+outside(투명)로 분기. 범례도 같은 22×22 compact 셀 렌더러로 그려 실제 모양 그대로 보여준다. (3) 우상단 빨간 `stop_circle_outlined`가 톤에 안 맞는다는 피드백 — 재시작 / 중단 두 IconButton을 단일 `PopupMenuButton(Icons.more_vert)`로 모았고, "중단"의 destructive 컬러는 메뉴 항목 안에서 `Icons.flag_outlined` + 빨강 텍스트로만 살짝 보인다(active: "새 스케줄로 다시 시작" + "약속 중단", completed/stopped: "이 약속으로 다시 만들기"). (4) 지금 탭 카드의 메모/응원 풍선에 날짜 라벨(오늘 / 어제 / N일 지남 / M월 D일)을 작은 글씨로 위에 박아 "오늘은 ..." 같은 user-typed 노트가 어제 작성된 것임을 분명히 했다 — lastActionNote 날짜는 `max(plan.completedDates)` 추정(reportCompletion이 둘을 같이 갱신하기 때문), lastComment 날짜는 `plan.lastCheerAt`. 공통 `_buildDatedNoteBubble` 헬퍼로 primary executor / secondary executor / partner-today-complete 세 곳을 통일. 사전 검증으로 `flutter analyze`(no issues), 노트 라벨 변경분은 iOS 시뮬레이터에서 직접 띄워 "2일 지남"/"5일 지남" 노출까지 시각 확인한 뒤 production AAB → Play production 트랙에 업로드. 첫 시도(`1.0.45+66`)는 en-US changelog가 532자로 Play의 500자 한도를 넘어 거절 → en-US 노트를 420자로 줄여 재업로드했지만 +66은 "Upload has already been terminated" 상태가 돼서 versionCode를 +67로 bump하고 재빌드. iOS는 이번 사이클에서 빌드/제출하지 않았다.
- 2026-05-26: `1.0.44+65` Android production 배포 완료. 지금 탭의 약속 정산 카드(`promiseSettled`)에 "결과 확인하기" 액션을 새로 붙였다. Promise 모델에 `settlementAcknowledgedBy: List<String>` 필드를 추가하고, `acknowledgePromiseSettlement(planId, comment?)` repository 메서드가 본인 UID를 `FieldValue.arrayUnion`으로 더하면서 옵션 코멘트가 있으면 `lastComment`/`lastCheerAt`도 같이 갱신해 상대에게 한마디로 전달되도록 했다. Repository의 home-card 빌더는 해당 사용자가 이미 ack한 경우 카드를 숨겨, Mine/Yours 양쪽 사용자가 각자 확인해야 자기 화면에서만 사라진다. 같은 빌드에 약속 상세 화면의 실천 기록 섹션에 목록/캘린더/그래프 SegmentedButton 토글을 추가했다 — `PlanHistoryCalendarView`는 plan 기간을 월별 7×N 그리드로 그리며 실천/휴식/인정/건너뜀/놓침/예정 6단계 색으로 일별 상태를 표시하고 범례를 함께 보여주고, `PlanHistoryGraphView`는 시작일 기준 7일 단위 주차 막대 그래프로 실천율(%)을 표시한다. 외부 차트 패키지 의존성 없이 순수 Flutter 위젯으로 구현. 사전 검증으로 `flutter analyze`(no issues), `now_tab_viewmodel_test`/`record_tab_viewmodel_test` 15개 모두 통과, 무선 연결된 SM S931N(갤럭시 S24)에 debug APK 설치로 신규 UX 두 가지가 화면에 노출되는지 확인한 뒤 `scripts/build_aab_deploy.sh`로 production AAB → Google Play production 트랙에 바로 업로드했다. iOS는 이번 사이클에서 빌드/제출하지 않았다.
- 2026-05-21: `1.0.43+64` Android production 배포 완료. 1.0.41까지의 Google Play "손상된 기능(로드 문제)" 심사 반려에 대응 — main.dart에서 `runApp` 전 await 체인에 있던 `FirebaseMessaging.requestPermission()`/`getToken()` + local notification `init()`이 splash 위에 알림 권한 다이얼로그를 띄우고 응답을 기다리며 첫 화면 진입을 ~54초 막던 문제(Pre-launch crawler가 "앱이 열리지 않음"으로 판정)를 고쳤다. 두 init 호출을 `runApp` 이후 `WidgetsBinding.addPostFrameCallback` + `unawaited`로 옮기고, `NotificationService.initialize()`를 권한 다이얼로그 없는 `setupListenersAndMaybeRegister()`(첫 진입용)과 `requestPermissionAndRegister()`(약속 알림 설정 시점에 명시 호출)로 분리. `dotenv.load`도 try/catch로 감쌌다. 같은 빌드에 `plan_create_viewmodel.dart`도 한 줄 수정 — 파트너가 연결되지 않은 상태(`managerId == null`)에서 새로 만드는 약속은 승인 대기 없이 `PlanState.active`로 바로 시작하도록 변경. 사전 검증으로 production AAB → bundletool universal APK → Android arm64 에뮬레이터에서 cold start 4초 이내·권한 다이얼로그 미발생을 확인하고 production 트랙에 바로 업로드했다(internal에는 1.0.42+63까지 올라가 있음). iOS는 이번 사이클에서 빌드/제출하지 않았다.
- 2026-05-19: `1.0.40+60` Android production + iOS App Store Connect 배포 완료. 1.0.39 Apple 심사 반려(Guideline 2.3.8 — 마켓플레이스 이름 `Nodtry - Promise Partner` vs 디바이스 라벨 `그래,해봐` 불일치, Guideline 2.1 — 후원 메뉴 한글 전용)에 대응. iOS는 `InfoPlist.strings` 로케일 분기로 영어 디바이스 `Nodtry` / 한국어 디바이스 `그래,해봐` 표시하도록 분리하고, 한국 App Store 노출 이름을 `Nodtry (그래,해봐) - 약속 파트너`로 변경해 마켓플레이스/디바이스 이름이 같은 토큰을 공유하게 했다. IAP "개발자에게 커피 사주기" 메뉴 4개 문자열(`settingsBuyDeveloperCoffee`, `settingsCoffeeSubtitle`, `settingsCoffeePurchasing`, `settingsStoreUnavailable`)을 EN/KO ARB로 분리하고, App Store 스크린샷을 1320×2868 (iPhone 17 Pro Max / 6.9") 7장으로 교체·확장(로그인/지금/기록/우리/설정/모든 약속/약속 상세). ASO 키워드는 커플 페르소나 중심으로 재정렬(`커플,연인,친구,가족,동기부여,자기계발,함께,...` / `couple,boyfriend,girlfriend,friends,family,habit,...`)하고 타이틀/서브타이틀에 이미 있는 약속/파트너 단어를 제거. iOS는 Apple 심사 재제출 대기, App Store Connect에서 Build 1.0.40 (60) 처리 완료 후 수동 Submit for Review + 2.1 메시지에 IAP donation_coffee 설명 회신 필요.
- 2026-05-17: `1.0.39+59` Android production + iOS App Store Connect 배포 완료. 집중 타이머 UX 보강 ("했어! 지금 끝낼게" CTA, 실제 경과 시간 prefill, 하단 시스템 바 가림 수정), 진행 중 약속(active promise) 카드 chip 신규 도입 (보상/벌칙 임박을 액션 버튼 위에 한 줄로 노출, 탭 시 풀 조건 + 진행 바)을 포함한다. iOS는 Apple 심사 진행 중. 초기 업로드 시 precheck가 EN release notes의 "Android" 단어를 잡아 경고했고, 즉시 `generate_ios_release_notes.sh`의 focus_timer 패턴을 platform 중립 표현으로 수정 → `metadata_only` lane으로 metadata만 재업로드 → precheck 전부 통과로 마무리.
- 2026-05-15: `1.0.38+58` Android production + iOS App Store Connect 배포 완료. 지금 탭 약속 카드의 집중 타이머 ("지금 할게!" 버튼, 5/10/25분 또는 직접 입력, 종료 시 자동 "했어" 노트 `"{N}분 집중 완료"` prefill) 추가, 똑똑 수신 카드 UI 단순화 (별도 버튼 제거, 상단 배지 + 자동 lastPokeAcknowledgedAt 기록), iOS fastlane locale/encoding 견고화 (`LANG`이 비어있어도 빌드되도록)를 포함한다. iOS는 Apple 심사 대기.
- 2026-05-12: `1.0.34+53` Android production 배포 완료 및 iOS App Store Connect 업로드 완료. 새 앱 아이콘/스토어 스크린샷, Pretendard 폰트 자산 수정, 응원/반응 이모지 중앙 정렬 개선을 포함한다.
- 2026-05-12: 스토어 스크린샷 갱신 준비 완료. 새 민트/주황 디자인과 앱 아이콘 기준으로 iOS/Android 스크린샷과 Play Store 아이콘을 다시 생성했고, production/App Store metadata 업로드에서 스크린샷 업로드를 활성화했다.
- 2026-05-12: `1.0.33+52` Android production 배포 완료. 상/벌 제안 화면에서 약속 기간, 현재 성공/실패, 남은 예정일을 표시하고 현재 상태 기준으로 도달 가능한 상/벌 일수만 조절하도록 수정했다.
- 2026-05-12: 문서/로드맵 갱신. 현재 파일럿용 최신 배포는 Android production `1.0.33+52`, iOS TestFlight `1.0.30+49`.
- 2026-05-11: `1.0.32+51` Android production 배포 완료. 기록 탭 상대 프로필 표시, 민트/주황 테마와 새 아이콘/스플래시, 커스텀 밑줄 텍스트, 우리 탭 약속 카드 overflow 수정을 포함한다.
- 2026-05-10: `1.0.31+50` Android production 배포 완료. 약속걸기 바텀시트/응원 입력 UI 수정, Google Play 설명/출시노트 갱신을 포함한다.
- 2026-05-10: 문서/로드맵 갱신. 현재 파일럿용 최신 배포는 Android production `1.0.32+51`, iOS TestFlight `1.0.30+49`.
- 2026-05-09: `1.0.30+49` Android production track 배포 완료. 출시노트 `ko-KR`, `en-US` 업로드 완료.
- 2026-05-09: `1.0.30+49` Android internal track 업로드 완료.
- 2026-05-09: `1.0.30+49` iOS TestFlight 업로드 완료. App Store Connect 처리 완료까지는 몇 분 지연될 수 있다.
- 2026-05-09: `1.0.29+48` Android internal track 업로드 완료.
- 2026-05-09: `1.0.29+48` iOS TestFlight 업로드 완료. App Store Connect 처리 완료까지는 몇 분 지연될 수 있다.
- 배포 전 사용자 수동 smoke 확인: 가입/연결/플랜/실천/파트너 반응 흐름 정상.

## 출시 보류 조건
- 가입 후 첫 플랜 생성 실패
- 파트너 연결 또는 양방향 관계 생성 실패
- 알림 권한 거부 시 앱이 진행 불가 상태가 됨
- 히스토리나 정산 결과가 양측에서 다르게 보임
