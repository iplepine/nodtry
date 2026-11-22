<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `eb7bab8ef3d51720dfbb57d867c537410e654b67` (`release/1.2.0`)
> - 최근 커밋: `eb7bab8ef3d5` chore(release): record the 1.3.0+91 production release and add ios submit_uploaded
> - 커밋 일시: `2026-11-22T10:57:15+09:00`
> - 워킹트리: `dirty (9 files)`
> - 문서 갱신: `2026-11-22 10:57:15 +0900`
<!-- COMMIT_STATUS END -->

# Task

ID: `BT-010-growth-features-recap-challenge-kakao`

유형: `Dev`

상태: `Active` (코드 완료 · 미커밋 · 미배포)

연결 Roadmap: `R-002-duounwan-release`

연결 Goal: `G-002-duounwan-launch`

담당: 정약용 / 프로덕트 총괄(범위), 장영실 / 기술실장(구현), 황희 / 리스크 감시역(검토), 승인 대표

마지막 갱신일: 2026-11-21

## 목표

사용자 증대를 위해 대표가 2026-11-21에 승인한 기능 3개를 다음 릴리스에 넣는다. 근거와 우선순위는 공용 운영 기록의 `GROWTH-1121-LIST`, `GROWTH-1121-FEATURES`.

1. **월간 리캡** — 한 달 운동을 9:16 카드 한 장으로 모아 공유한다.
2. **기간 챌린지 약속** — 새해 둘운완 21일 챌린지(2027-01-01~01-21). App Store In-App Event `newyear2027_duo21`의 앱 내 실체(`LAUNCH_PLAN_DUOUNWAN.md` §4.3의 배너·고정 기간 약속·공유 카드 프레임).
3. **카카오톡 초대 카드** — 초대를 카카오톡 피드 카드로 보낸다. 설정과 남은 일은 `docs/operations/KAKAO_SHARE_SETUP.md`.

효과(공유율·초대→연결·이벤트 유입)는 모두 `Assumption`이다. 출시 후 아래 이벤트로 측정한다.

## 범위와 동작

### 1. 월간 리캡
- 진입: 우리 탭의 `{월} 리캡` 행(약속이 하나라도 있으면, 짝꿍이 없어도 보인다). 매달 1~7일에는 지난달 리캡을 한 번 자동으로 제안한다(지난달 기준일 3일 이상일 때, 공유 카드 제안이 뜬 날은 건너뜀).
- 카드: 커플은 `우리의 11월 · 둘운완 N일`, 혼자는 `나의 11월 · 운동한 날 N일`. 달력(둘 다 한 날 = 채운 원, 한 명만 = 테두리), 사람별 운동한 날과 가장 많이 한 운동, 달 안의 최장 연속.
- 최근 12개월까지 이전 달로 넘겨 볼 수 있다. 기록이 없는 달은 공유할 수 없다.
- 사진과 짝꿍 실명은 넣지 않는다(애칭 또는 `짝꿍`). 서버·규칙 변경 없음, 저장하는 데이터 없음.
- 계산 규칙은 둘운완 통계와 같다(`lib/features/duo/domain/duo_recap.dart` 머리 주석).

### 2. 기간 챌린지 약속
- 정의는 앱 코드에 있다(`lib/features/challenge/domain/duo_challenge.dart`의 `kDuoChallenges`). 새 챌린지는 릴리스에 실어야 한다.
- 지금 탭 배너: 예고(12/18~12/31, D-n) → 진행·미참여(`참여하기`) → 진행·참여(며칠째, 진행 막대, 둘운완 N일) → 종료 후 7일(참여자에게 결과). 참여 중 배너만 닫을 수 없다.
- 참여 방법 2가지
  - 진행 중인 약속이 없으면: 챌린지용 새 약속. 기간이 오늘~1/21(28일 아님).
  - 진행 중인 약속이 있으면: 그 약속 그대로 참여(기간 변경 없음) 또는 새 약속 만들기 중 선택.
- 데이터: `plans.challengeId`(선택 필드) 하나. 현재 Firestore 규칙이 허용하고(키 제한 없음), 서버 함수는 이 필드를 읽지 않으며 약속 기간은 원래 `startDate`/`endDate`로만 판정한다. 구버전 앱은 무시한다. **규칙·함수 배포 불필요.**
- 진행 수치는 챌린지 시작일부터의 둘운완 날(혼자면 운동한 날)이며 어느 약속에 기록했든 센다.
- 공유 카드: 참여 중이면 `#새해둘운완 N일째`, 종료 후 7일은 `#새해둘운완 완주` 칩이 붙는다.

### 3. 카카오톡 초대 카드
- `.env`에 `KAKAO_NATIVE_APP_KEY`가 없으면 지금과 완전히 같다. 키가 있고 카카오톡이 설치돼 있으면 노란 `카카오톡으로 초대 보내기` 버튼 + `다른 앱으로 보내기`가 보인다.
- 카드 전송이 실패하면 기존 공유 시트로 넘어간다.

### 챌린지 대표 이미지 (2026-11-22)
- 대표 지시("필요한 이미지는 코덱스로 만들어 사용")로 Codex CLI 내장 이미지 생성으로 만들었다.
- 1차(붉은 배경 4종)는 대표 반려("너무 뻘개서 뭔지 모르겠다"). 2차는 밝은 배경·빨강은 포인트만으로 4종(A 운동화 · B 덤벨 · C 21일 메달 · D 달력 체크)을 냈고, **대표가 C안(21일 메달)으로 확정**했다(11/22). 나머지 시안 파일은 지웠다.
- 파일
  - 원본: `assets/brand/challenge_newyear2027_1024.png`(앱 번들에 들어가지 않는 원본 폴더)
  - 앱 번들본: `assets/images/challenge_newyear2027.png`(256px, 약 50KB). Now 탭 배너(40pt)와 참여 시트(72pt)에 표시. 옅은 테두리, 파일을 못 읽으면 트로피 아이콘으로 대체(`ChallengeArt`).
  - App Store 인앱 이벤트 ②용: `assets/brand/events/newyear2027/event_card_16x9_1920x1080.png`, `event_detail_9x16_1080x1920.png`. 메달 + 운동화 두 켤레, 글자는 숫자 21뿐, 제목이 얹히는 아래쪽은 비움. 코덱스 생성본을 규격에 맞게 합성했다.
- 참여 시트는 이미지가 들어가 높이가 늘어, 낮은 화면·큰 글씨에서 넘치던 것을 내용 높이에 맞추고 스크롤되게 고쳤다(테스트 추가).
- 미확인: 실기기 표시, App Store Connect 업로드 시 규격 통과 여부(파일 크기·비율·알파 없음은 확인). 이벤트 이미지 2종은 대표 확인 전이다.

## 계측 (`docs/operations/ANALYTICS_EVENTS.md`)

`recap_opened`, `recap_shared`, `challenge_joined`, `challenge_banner_dismissed`, `plan_created.challenge`, `invite_shared{channel: kakao_card}`.

## 완료 기준

- [x] `flutter analyze` 0건
- [x] `flutter test` 전체 통과(1,014건, 2026-11-22 이미지 적용 후 재실행)
- [x] 실제 폰트 렌더로 리캡 카드·챌린지 배너 4상태·공유 카드 칩 육안 확인(테스트 렌더, 기기 아님)
- [x] Android 디버그 APK 빌드 · iOS 시뮬레이터 빌드 성공(새 카카오 플러그인 포함, 2026-11-21)
- [x] 릴리스 빌드 성공(2026-11-22, 버전 변경 없이 확인용): Android `flutter build appbundle --release`(난독화 포함) AAB 79.6MB, iOS `flutter build ios --release --no-codesign` Runner.app 59.3MB. 이전 버전 대비 용량 변화는 비교하지 않았다
- [ ] 실기기 확인: 리캡 공유(인스타·카카오), 챌린지 배너(기기 날짜를 12/27·1/5·1/23으로 바꿔 4상태), 챌린지 약속 생성 후 종료일·알림
- [ ] 대표: Kakao Developers 앱 등록 → 키 전달(`KAKAO_SHARE_SETUP.md` §1). 그 뒤 카카오 카드 실기기 검증
- [ ] 대표: 리캡·챌린지·카카오 카드 문구 확인
- [x] 대표: 챌린지 대표 이미지 2차 C안(21일 메달) 확정(2026-11-22)
- [ ] 대표: 인앱 이벤트 이미지 2종(카드 16:9, 상세 9:16) 확인
- [x] 커밋·푸시(대표 요청, 2026-11-22, `release/1.2.0`)
- [x] 프로덕션 출시(대표 승인 2026-11-22): `1.3.0+91`. Google Play 프로덕션 반영, App Store 심사 제출(승인 시 자동 공개). 상세 `docs/operations/RELEASE_READINESS.md`
- [ ] 스토어 심사·공개 확인 후 `config/app.latestBuild = 91`(대표 승인)

## 열린 이슈 · 위험

- **일정**: In-App Event ②는 12/15 제출·12/18 게시 계획이다. 배너 예고가 12/18부터라, 이 빌드가 그 전에 스토어에 나가 있어야 한다.
- **카카오 카드에서 설치된 앱으로 바로 열리는지 미확인**(인앱 브라우저). 전송 완료 여부를 SDK가 알려 주지 않아 `invite_shared`가 과대 집계될 수 있다. 상세 `KAKAO_SHARE_SETUP.md` §5.
- `kakao_flutter_sdk_share` 2.1.0은 Dart 3.9 이상이 필요하다. `pubspec.yaml`의 `sdk: ^3.8.1`은 그대로 두었다(현재 툴체인 Dart 3.13에서 해석됨).
- 챌린지 날짜 판정은 기기 로컬 날짜 기준이다. 한국 외 시간대 사용자는 자기 날짜로 1/1~1/21을 지낸다.
- 리캡의 과거 달 수치는 약속 문서의 기록 배열에 의존한다(`REMAINING_IMPROVEMENTS.md` §3의 5~6단계에서 배열 쓰기를 멈추면 리캡 읽기 경로도 함께 옮겨야 한다).
- 감시 프레임: 리캡·챌린지 카드는 사진과 실명을 싣지 않는다. 공유는 항상 사용자가 누를 때만 일어난다.

## 주요 파일

- 리캡: `lib/features/duo/domain/duo_recap.dart`, `application/duo_recap_provider.dart`, `presentation/duo_recap_card.dart`, `application/duo_moments.dart`(월초 제안), `domain/duo_stats.dart`(`computeDuoDays`)
- 챌린지: `lib/features/challenge/**`, `lib/models/plan_model.dart`(`challengeId`), `lib/repositories/*record_repository.dart`(`setPlanChallenge`), `lib/features/plan/presentation/**`(챌린지 약속 기간), `lib/features/duo/presentation/duo_share_card.dart`(칩)
- 카카오: `lib/features/connect/application/kakao_invite_sharer.dart`, `invite_services.dart`, `presentation/widgets/kakao_invite_button.dart`
- 테스트: `test/features/duo/duo_recap*_test.dart`, `test/features/challenge/**`, `test/viewmodels/plan_create_challenge_test.dart`, `test/features/connect/kakao_invite_test.dart`
