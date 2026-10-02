<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (16 files)`
> - 문서 갱신: `2026-10-03 07:18:57 +0900`
<!-- COMMIT_STATUS END -->

# 출시 런북 — 둘운완 1.1.0 (81)

> 작성 2026-10-02 · 김삿갓 / 마케팅실장 · 검토 황희 / 리스크 감시역 · 실행 장영실 / 기술실장 · **승인권자: 대표**(단계마다 서명)
> 스펙 §8 배포 순서를 그대로 따른다. 콘솔 클릭 항목은 `STORE_CONSOLE_CHECKLIST.md`, 과거 배포 함정은 `RELEASE_READINESS.md`와 동일하다.

## 0. 원칙과 사전 준비

### 원칙
1. **서버 먼저, 앱 나중.** 서버 변경은 구버전(80 이하)과 호환되어야 한다. 함수 배포는 앱 버전과 상관없이 전원에게 즉시 적용된다.
2. **앱이 공개되기 전(7단계 전)까지만 롤백한다.** 공개 뒤에는 81 클라이언트가 새 규칙·함수에 의존하므로, 되돌리지 말고 해당 함수나 규칙만 고쳐 다시 배포한다.
3. 모든 Firebase 명령에 `--project nod-try`를 붙인다. `.firebaserc`에는 default 별칭이 없고 `y`만 있다.
4. 셸 전체에 `export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8`을 먼저 실행한다(§3 함정 1).
5. `scripts/build_aab_deploy.sh`는 **쓰지 않는다.** 버전을 자동으로 올리고 커밋·태그까지 한다. 이번 버전은 `1.1.0+81`로 고정이다.
6. 각 단계는 **사전 확인 → 명령 → 검증 → 대표 승인 기록** 순서로 진행한다. 하나라도 실패하면 다음 단계로 가지 않는다.

### D-3 사전 준비
```bash
cd /Users/basil/Projects/flutter/nodtry
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# 품질 게이트 (스펙 §8)
flutter analyze
flutter test
npm --prefix functions ci && npm --prefix functions test        # tsc 빌드 + functions/test
npm --prefix rules-tests ci
npm --prefix rules-tests run emulators:rules                    # firestore.rules·storage.rules 에뮬레이터 테스트
npm --prefix rules-tests run emulators:functions                # 관계·탈퇴 트리거 에뮬레이터 테스트
grep -n "^version:" pubspec.yaml            # → version: 1.1.0+81

# 롤백 기준점 기록
git rev-parse HEAD                          # DEPLOY_COMMIT
firebase functions:list --project nod-try   # 현재 배포된 함수 목록 저장
```
- PREV_COMMIT: 현재 운영 중인 규칙과 함수의 소스 커밋을 기록한다. 콘솔의 규칙 탭 "기록"에서 현재 게시본을 내려받아 레포 밖에 보관한다.
- **Firestore 백업**(마이그레이션 대비, 대표 승인 필요)
  - Cloud 콘솔: Firestore → 가져오기/내보내기 → 내보내기 → `gs://<백업 버킷>/pre-pivot-YYYYMMDD`
  - gcloud CLI(현재 이 맥에는 미설치): `gcloud firestore export gs://<백업 버킷>/pre-pivot-YYYYMMDD --project=nod-try`
- 위 에뮬레이터 테스트 결과(통과 수)를 §4 승인 기록에 남긴다. 테스트는 데모 프로젝트(`demo-duounwan`)에서 돌아 운영 데이터를 건드리지 않는다.

## 1. 배포 순서 (1~8단계)

### 1단계. Storage 규칙
```bash
firebase deploy --only storage --project nod-try
```
- 처음 배포할 때 교차 서비스(`firestore.get`) 규칙용 IAM 역할을 부여하라는 프롬프트가 나온다. **Y로 승인한다.** 거부하면 인증샷 규칙이 전부 거부로 평가된다.
- 검증: 콘솔 Storage → 규칙 → 플레이그라운드에서 3건을 확인한다.
  - `proofs/{owner}/{plan}/{action}.jpg` owner read 허용
  - managerId read 허용
  - 제3자 read 거부
- 롤백: 콘솔 → Storage → 규칙 → 기록에서 이전 버전 게시. 또는 아래 명령.
  ```bash
  git worktree add ../nodtry-rollback <PREV_COMMIT>
  (cd ../nodtry-rollback && firebase deploy --only storage --project nod-try)
  ```
- 구버전 영향: 없음. `proofs/` 경로만 추가된다.

### 2단계. Firestore 규칙 (`config/app` 공개 읽기)
```bash
firebase deploy --only firestore:rules --project nod-try
# 인덱스가 바뀐 경우에만 — 1.1.0(81)은 바뀌었다: actions 복합 인덱스 3개(SECURITY_RULES.md "필요한 복합 인덱스")
firebase deploy --only firestore:indexes --project nod-try
```
- 6단계(스토어 제출) 전에 콘솔에서 세 인덱스가 "사용 설정됨"인지 확인한다. 없으면 81의 짝꿍 기록·약속 타임라인·인정이 `failed-precondition`으로 실패한다.
- 배포 직후 콘솔에서 `config/app` 문서를 만든다: `minBuild: 0`, `latestBuild: 80`(숫자형).
  - 앱(`lib/core/services/app_version_gate.dart`)은 문서가 없거나 읽기에 실패하면 게이트를 건너뛴다(fail-open). 그래도 미리 만들어 두면 이후 운영에서 숫자만 바꾸면 된다.
  - 타입이 문자열이면 무시될 수 있으니 반드시 숫자형으로 넣는다.
- 검증(플레이그라운드)
  - 비로그인 상태에서 `config/app` get 허용
  - 클라이언트 write 거부
  - 기존 plans·relations 쓰기 패턴 회귀 없음
- 롤백: 콘솔 → Firestore → 규칙 → 기록에서 이전 버전 게시

### 3단계. Functions
```bash
npm --prefix functions ci
firebase deploy --only functions --project nod-try     # predeploy가 tsc 빌드를 다시 실행
firebase functions:list --project nod-try
firebase functions:log --project nod-try
```
- 아티팩트 정리 정책을 묻는 프롬프트가 나오면 기본값(1일 이상)으로 승인한다.
- 검증은 **현재 스토어 빌드(80)** 테스트 계정 2개로 한다. 구버전 호환을 확인하는 단계이기 때문이다.
  - 코드로 연결하면 초대자 푸시가 정확히 1건 온다.
  - 이미 짝꿍이 있는 사용자의 코드로 연결하면 30초 안에 관계 0건이 되고, 사용한 코드는 재사용할 수 없다.
  - 연결을 해제하면 양쪽 plans.managerId가 해제된다.
  - 레거시(비운동) 약속의 미이행 푸시에 "운동"이라는 단어가 0회 나온다.
  - 인정 1회에 상대 푸시가 1건 온다.
  - 테스트 계정 탈퇴 시 해당 uid의 actions·cheers·Storage prefix가 0이 되고, **다른 사용자 데이터는 변하지 않는다**(황희 필수 확인).
- 롤백(공개 전까지만)
  ```bash
  (cd ../nodtry-rollback && npm --prefix functions ci && firebase deploy --only functions --project nod-try)
  ```
  - PREV에 없는 새 함수는 CLI가 삭제 여부를 묻는다. Y로 답한다. 함수 삭제는 데이터 삭제가 아니다.
  - 공개 뒤에는 고친 함수만 `firebase deploy --only functions:<함수명> --project nod-try`로 다시 배포한다.

### 4단계. Hosting (초대 랜딩 `/i/{code}`)
- 전제
  - `firebase.json` hosting 블록은 있다: public `hosting/public`, rewrite `/i/**`→`/invite.html`, `/get`→`/get.html`.
  - 2026-10-02 기준 `hosting/public` 디렉터리는 아직 없다. 기술 레인이 만든다.
  - 같은 날 `nod-try.web.app`은 "Site Not Found" 상태다. 즉 이번이 **첫 배포**다.
```bash
# 먼저 미리보기 채널에서 카톡 미리보기 카드 확인
firebase hosting:channel:deploy invite-preview --expires 7d --project nod-try
# 본 배포
firebase deploy --only hosting --project nod-try
curl -sI https://nod-try.web.app/i/TESTCODE | head -1     # 200
curl -sI https://nod-try.web.app/get | head -1            # 200
```
- 검증
  - 카카오톡 나와의 채팅에 링크를 보내 미리보기 카드(OG 제목·이미지)를 확인한다.
  - iOS 브라우저는 App Store로, Android 브라우저는 Play로 가는지 확인한다. Play URL에 `&referrer=invite_code%3D{CODE}`가 붙는지도 본다.
  - 코드가 크게 보이고 복사 버튼이 동작하는지 확인한다.
- 롤백
  - 첫 배포라면 `firebase hosting:disable --project nod-try`로 사이트를 끈다. 초대 메시지 본문에 코드가 있으므로 연결은 계속된다.
  - 이후 배포라면 콘솔 Hosting → 출시 기록 → 이전 버전 "롤백"
  - 개인정보처리방침을 Hosting으로 옮겼다면 disable하지 말고 롤백만 쓴다.

### 5단계. 데이터 마이그레이션 (dry-run → 대표 승인 → 실행)
스크립트는 기술 레인이 구현한다. 아래 `<MIGRATION_CMD>`를 실제 경로로 바꾼다. 스크립트가 지켜야 할 계약:
- 기본값은 dry-run이다. 실제 쓰기는 `--apply`를 줄 때만 한다.
- 대상 문서 수와 샘플 ID를 리포트로 출력한다.
- `--apply` 때 바꾸는 문서의 원본을 JSON으로 백업한다. `--restore <백업파일>`을 지원한다.
- 멱등이어야 한다(두 번째 실행 시 변경 0건).
- 대상 예: 관계가 없는데 managerId가 남은 plans. 최종 대상은 스크립트 리포트로 확정한다.
- 1.1.0(81) 필수: `scripts/migrations/clear_stale_manager_ids.js` 다음에 `scripts/migrations/backfill_action_manager_ids.js`(3단계 functions 배포 **뒤**). 81은 짝꿍 기록·약속 타임라인을 `actions.managerId == me`로만 읽으므로, 백필 전에 쓰인 기록은 81 사용자에게 안 보인다(SECURITY_RULES.md "읽기 축소"). 이 스크립트들은 `--restore`가 없다 — 복원은 JSON-lines 백업의 `previous` 값으로 한다.

```bash
# 인증: 서비스 계정 키는 레포 밖 경로에만 둔다. 커밋 금지
export GOOGLE_APPLICATION_CREDENTIALS=<레포 밖 키 경로>   # 또는 gcloud ADC
<MIGRATION_CMD> --project nod-try --dry-run   > migration_dryrun_YYYYMMDD.txt
# ↑ 리포트를 대표가 확인하고 승인
<MIGRATION_CMD> --project nod-try --apply
<MIGRATION_CMD> --project nod-try --dry-run   # 변경 0건 확인
```
- 롤백
  - 1순위: `<MIGRATION_CMD> --restore <백업 JSON>`
  - 최후 수단: 0단계 내보내기에서 Firestore 가져오기. 같은 ID 문서를 덮어쓰므로 공개 전에만 쓴다.

### 6단계. 스토어 제출 (수동 출시)
공개 목표일보다 **최소 7일 먼저** 제출한다. 이름·아이콘·카테고리·사진 UGC가 한 번에 바뀌어 심사가 길어질 수 있다.

**Android**
```bash
cd /Users/basil/Projects/flutter/nodtry
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
flutter clean && flutter pub get
flutter build appbundle --release
bundletool dump manifest --bundle build/app/outputs/bundle/release/app-release.aab | grep uses-permission
#   → AD_ID, CAMERA, READ_MEDIA_* 없어야 함
wc -m android/fastlane/metadata/android/ko-KR/changelogs/81.txt android/fastlane/metadata/android/en-US/changelogs/81.txt
#   → 각 500자 이하
cd android && fastlane production
```
- **전제: Play Console 관리형 게시가 ON이어야 한다.** OFF면 `production` 레인(`release_status: completed`)이 심사 통과 즉시 공개한다. 확인하기 전에는 실행하지 않는다.
- 검증
  - Play Console에서 프로덕션 81이 "검토 중"인지 본다.
  - 스토어 등록정보 변경이 함께 대기 중인지 본다.
  - 구 스크린샷이 남아 있지 않은지 본다.

**iOS** — `release` 레인은 쓰지 않는다. `automatic_release: true`라서 승인되는 즉시 공개된다.

2026-10-03에 Fastfile을 이렇게 고쳤다.
- `release_manual` 레인을 추가했다. `release`와 같은 빌드·업로드·심사 제출이고, `automatic_release: false`다.
- 모든 업로드 레인(`release`, `release_manual`, `upload_assets`, `metadata_only`)이 `overwrite_screenshots: true`로 구 스크린샷 세트를 교체한다.
- 릴리스 노트 생성기는 `GENERATE_RELEASE_NOTES=1`일 때만 돈다. metadata에 커밋 안 된 변경이 있으면 멈춘다. 기본값은 수동 문안 `release_notes.txt`를 그대로 올리는 것이다.
- `metadata_only`는 더 이상 심사 제출이나 자동 출시를 하지 않는다.
- 루트 `fastlane release_all_manual`은 Android `production`과 iOS `release_manual`을 함께 돌린다.

권장 경로는 A다. 수동 문안을 커밋한 뒤 아래처럼 실행한다.
```bash
cd /Users/basil/Projects/flutter/nodtry/ios && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 fastlane release_manual
```
Fastfile을 바꾸지 않고 지금 바로 해야 하면 B 경로를 쓴다.
```bash
cd /Users/basil/Projects/flutter/nodtry
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
(cd ios && pod install)          # 실패 시 §3 함정 3
flutter build ipa --release
# ios/fastlane/metadata/{ko,en-US}/release_notes.txt 는 수동 문안이어야 함(체크리스트 B3)
cd ios && fastlane deliver \
  --api_key_path fastlane/api_key.json \
  --ipa "$(ls -t ../build/ios/ipa/*.ipa | head -1)" \
  --app_version 1.1.0 \
  --skip_metadata false --skip_screenshots false --overwrite_screenshots true \
  --submit_for_review true --automatic_release false --reject_if_possible true \
  --force true --precheck_include_in_app_purchases false \
  --copyright "2026 Devho"
```
- 검증(ASC)
  - 1.1.0 "심사 대기 중"
  - 빌드 81, 버전 출시 = **수동**
  - 스크린샷 6장만 있음, 이름·부제·키워드 일치
- 제출 뒤 체크리스트 B3의 데모 계정과 심사 메모를 확인한다.
- 롤백(공개 전)
  - iOS: ASC → 1.1.0 → "심사에서 제거" 또는 개발자 거부
  - Play: 게시하지 않으면 공개되지 않는다. 필요하면 새 릴리스로 대체한다.
- **심사 중에는 `release`·`release_manual` 레인을 실행하지 않는다.** 두 레인 모두 `reject_if_possible: true`라서 심사 중인 제출을 취소하고 다시 제출한다. `release`는 자동 출시까지 켠다. 메타데이터만 고칠 때는 `metadata_only`나 `upload_assets`를 쓴다. 둘 다 심사 제출을 하지 않는다.

### 7단계. 동시 공개
- 조건
  - 양 스토어 승인 완료
  - 1~5단계 완료
  - 대표 공개 승인
  - CS 담당(임시 운영 리드) 대기
- 시각: 평일 오전(계획 기준 **11/3(화) 10:00 KST**)
  - ASC → 1.1.0 → **"이 버전 출시"**
  - Play Console → 게시 개요 → **"변경사항 게시"**
- 검증(T+4h까지)
  - KR App Store와 Play 페이지에 새 이름·아이콘·스크린샷이 보인다. Apple 반영은 최대 24시간 걸릴 수 있다. `Signal`
  - 새로 설치해 iOS A ↔ Android B 교차 초대 → 연결 → 인증샷 → 인정을 스모크한다.
  - 두 스토어 페이지가 모두 새 브랜드로 보이기 **전에는** 유료 광고를 시작하지 않는다.
- 롤백
  - iOS 바이너리는 되돌릴 수 없다. 1.1.1을 만들어 신속 심사를 요청한다.
  - Play는 프로덕션 출시 "중지(halt)"가 가능한지 콘솔에서 확인하고, 수정 빌드를 올린다.
  - 81을 서버에서 막는 스위치는 없다. `minBuild`는 하위 버전만 막는다. 필요하면 다음 릴리스에 `blockedBuilds` 같은 장치를 검토한다.

### 8단계. `config/app.latestBuild`
- 공개 1시간 뒤 콘솔에서 `config/app.latestBuild = 81`로 바꾼다. `minBuild`는 0으로 둔다. 다음 릴리스의 보안 묶음 때 올린다.
- 검증: 81 클라이언트에 업데이트 안내가 뜨지 않는다.
- 배포 기록을 `RELEASE_READINESS.md` "최근 내부 테스트 배포"에 한 줄 추가한다(배포 담당).

## 2. 공개 후 72시간 모니터링

| 항목 | 기준 | 확인 |
|---|---|---|
| 비정상 종료 없는 사용자 | ≥99.5% (99% 미만이면 중단 조건) | Crashlytics |
| 함수 오류 | 급증 없음 | `firebase functions:log --project nod-try` |
| Storage 거부율 | 인증샷 로드 실패 급증 없음 | 콘솔 사용량 |
| 사용자당 푸시 | 하루 4건 이하 목표 | 로그 샘플 |
| 리뷰 | 1~3점은 24시간 안에 답변 | ASC, Play |
| 초대→연결 | 일 단위 추적 | GA4 |

**즉시 중단 조건**: 아래 중 하나라도 생기면 대표에게 바로 보고한다. 이후 유료 광고와 In-App Event 제출을 보류하고 원인을 고친다.
- 짝꿍이 아닌 사람이 인증샷을 볼 수 있음
- 1:1 제한이 깨짐
- 탈퇴 정리가 다른 사용자 데이터를 건드림
- 비정상 종료 없는 사용자 99% 미만

## 3. 함정 (`RELEASE_READINESS.md`·배포 메모 기준)

| # | 증상 | 대응 |
|---|---|---|
| 1 | deliver·gym이 `invalid byte sequence in US-ASCII`로 실패 | 명령 앞에 `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8`. Fastfile은 LANG이 비었을 때만 보정하고 `C`일 때는 보정하지 않는다 |
| 2 | `pod install`이 `Encoding::CompatibilityError(ASCII-8BIT)`로 실패 | 1과 같음 |
| 3 | `The sandbox is not in sync with the Podfile.lock`, 또는 Firebase pod 버전 충돌 | `cd ios && pod install`. 충돌하면 `pod update <Pod명>`. 새 플러그인(share_plus 등)이 들어간 이번 릴리스는 가능성이 높다 |
| 4 | 업로드 직후 `NSURLErrorDomain -1005`, 또는 빌드 대기 중 프로세스 종료 | IPA는 이미 도달한 상태다. deliver를 `--skip_binary_upload true`로 다시 실행하되 `--automatic_release false`를 유지한다. `metadata_only` 레인은 심사 제출을 하지 않으므로 이 복구에 쓰지 않는다 |
| 5 | Play 업로드 거절(출시 노트 500자 초과) → versionCode 소진 | 제출 전 `wc -m`. 소진되면 +82로 올리고 iOS 빌드 번호도 맞춘다. 서버 `PIVOT_BUILD=81` 비교는 82에서도 유효하다 |
| 6 | Play가 광고 ID 신고 불일치로 거절 | 매니페스트에서 `AD_ID`를 `tools:node="remove"`로 유지 |
| 7 | "A required agreement is missing or has expired" | 대표가 ASC 계약에 서명 |
| 8 | Flutter 업그레이드 후 `GeneratedPluginRegistrant`가 남아 아카이브 실패 | `flutter clean`. iOS는 DerivedData 정리 + `pod install --repo-update` |
| 9 | 구 스크린샷(로그인 컷)이 계속 남음 | `overwrite_screenshots true`. Play는 콘솔에서 확인 후 삭제 |
| 10 | 릴리스 노트가 커밋 제목으로 덮어써짐 | 2026-10-03부터 생성기는 `GENERATE_RELEASE_NOTES=1`일 때만 돌고, metadata에 커밋 안 된 변경이 있으면 멈춘다. 이 환경 변수를 켜지 않는다 |
| 11 | Firebase 명령이 엉뚱한 프로젝트를 잡거나 프로젝트 없음 오류 | `--project nod-try` |

**보안 후속(황희)**: Play 서비스 계정 키 `android/fastlane/json_key.json`이 과거 커밋 히스토리에 남아 있다(RELEASE_READINESS 2026-06-13). 레포가 공개 상태이거나 공개될 예정이면, 버스트 전에 키를 회전하고 히스토리를 정리한다.

## 4. 승인 기록

| 단계 | 실행 일시 | 커밋 | 실행자 | 검증 결과 | 대표 승인 |
|---|---|---|---|---|---|
| 0 백업·게이트 | | | | | |
| 1 Storage 규칙 | | | | | |
| 2 Firestore 규칙 + config/app | | | | | |
| 3 Functions | | | | | |
| 4 Hosting | | | | | |
| 5 마이그레이션 dry-run | | | | | |
| 5 마이그레이션 실행 | | | | | |
| 6 스토어 제출 | | | | | |
| 7 동시 공개 | | | | | |
| 8 latestBuild=81 | | | | | |
