<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (18 files)`
> - 문서 갱신: `2026-10-03 07:18:57 +0900`
<!-- COMMIT_STATUS END -->

# Firestore / Storage Security Rules

마지막 갱신: 2026-10-03 (둘운완 피벗 + 읽기 축소 스테이징, **둘 다 미배포**) · 배포 순서·승인은 `LAUNCH_RUNBOOK.md`

소스 오브 트루스: [`firestore.rules`](../../firestore.rules), [`storage.rules`](../../storage.rules),
[`firestore.indexes.json`](../../firestore.indexes.json). `firebase.json`의 `firestore`·`storage` 타깃이 이 파일들을 가리킨다.
읽기를 참가자로 좁힌 다음 버전은 [`firestore.rules.next`](../../firestore.rules.next)에 스테이징돼 있다(아래 "읽기 축소").
`firebase.next.json`은 그 파일을 쓰는 **에뮬레이터 전용** 설정이다 — 이 설정으로 배포하지 않는다.
서버(Cloud Functions, admin SDK)는 규칙을 우회한다. 서버 쪽 불변식은 아래 "서버 강제"에 정리한다.

## 모델 요약 (`firestore.rules`)
| 대상 | read | create | update | delete |
|---|---|---|---|---|
| `users/{uid}` | 로그인 사용자 전체¹ | 본인 | 본인(한 번 발급된 `inviteCode` 변경·삭제 ✗) | 본인 |
| `users/{uid}/private/{doc}` | 본인 | 본인 | 본인 | 본인 |
| `relations/{id}` | 참가자 | 코드 입력자(`inviterId`=상대, `inviteCode`=상대의 현재 코드, `createdAt`=서버 시각) 또는 레거시 창(`config/app.legacyLinkUntil`) | ✗ | 참가자 |
| `plans/{id}` | 로그인 사용자 전체² | `userId==me`, `managerSince*` ✗ | 참가자 + `userId` 불변 + `managerSince*` ✗ | `userId==me` |
| `actions/{id}` | get: 소유자·plan 매니저 / list: 로그인 전체² | `userId==me`, 내 plan에만, `managerId`는 없거나 `plans/{planId}.managerId`와 같게 | 소유자(`userId`·`planId` 불변) · plan 매니저(인정 키 `verifiedBy`·`verifiedAt`·`comment`·`partnerMessage`·`reaction`만) | 소유자 |
| `cheers/{id}` | 보낸·받은 사람 | `fromUserId==me` | ✗ | ✗ |
| **`config/{doc}`** (신규) | **누구나**(로그인 전 포함) | ✗ | ✗ | ✗ |
| `serverLocks/{key}` (신규, 서버 전용) | ✗ (match 없음) | ✗ | ✗ | ✗ |
| Storage `users/{uid}/*` | 로그인 전체 | 본인·이미지 <5MB | 본인 | 본인 |
| **Storage `proofs/{ownerUid}/{planId}/{file}`** (신규) | 본인 또는 `plans/{planId}.managerId == me` | 본인·`resource == null`·`image/jpeg`·<3MB·`plans/{planId}.userId == ownerUid` | ✗ | 본인 |

¹ ² **읽기가 넓은 이유**: 빌드 ≤80이 짝꿍의 `plans`/`actions`를 partner uid로만 필터링해 조회하고(기록 탭, 둘운완 통계), 초대 코드를 `users` 쿼리로 찾는다. 규칙은 필터가 아니라서 참가자 read를 걸면 이 쿼리들이 통째로 거부된다. 좁힌 규칙은 `firestore.rules.next`에 준비돼 있고, 빌드 81이 대다수가 되면 앱 릴리스 없이 교체한다(아래 "읽기 축소").

## 피벗에서 바뀐 것
### `proofs` Storage 블록
- read는 **현재** `managerId` 기준이다. 연결 해제 시 `onRelationDeleted`가 `managerId`를 지우는 순간 전 짝꿍은 읽을 수 없다(인증샷 1건마다 Firestore 문서 1회 read 비용).
- create는 action 문서 존재를 요구하지 않는다(앱이 업로드 후 배치로 action을 쓴다). `resource == null`로 덮어쓰기 금지(Storage 에뮬레이터는 덮어쓰기를 create로 평가하기 때문).
- 클라이언트는 업로드 전에 EXIF·GPS를 지우고 JPEG로 재인코딩한다. 규칙은 contentType·크기·경로 소유만 검사한다.
- **IAM 권한 부여**: `firestore.get`을 쓰는 교차 서비스 규칙이라 첫 `firebase deploy --only storage` 때 CLI가 Storage 서비스 에이전트에 Firestore 읽기 권한을 줄지 묻는다. **수락해야 한다.** 거절하면 모든 인증샷 업로드·조회가 거부된다.

### `config/{doc}`
- `config/app {minBuild, latestBuild}` 최소 버전 게이트용. 공개 read, 클라이언트 쓰기 금지. 콘솔에서 직접 만든다(규칙 배포 직후 `{minBuild: 0, latestBuild: 80}`, 숫자 타입).

### `serverLocks`
- 서버 전용. 똑똑 하루 1회 제한, 쌍별 연결·해제 이벤트 잠금(2분). `{at, expireAt}`, `firestore.indexes.json`의 TTL 정책(`fieldOverrides`: `serverLocks.expireAt`)으로 자동 삭제.
- `emulatorPushes`는 에뮬레이터(`FUNCTIONS_EMULATOR=true`)에서만 쓰는 서버 전용 컬렉션.

### 클라이언트가 새로 쓰는 필드 (규칙 변경 없이 허용됨)
- `users`: `partnerNickname`(≤10자 또는 삭제), `pivotNoticeSeen`, `clientBuild`, `timezone`, `locale`
- `relations`: `inviterId`, `inviteCode`
- `plans`: `workoutType`, `lastActionId`, `lastProofPhotoPath`, `lastProofAt`(삭제 포함), `lastUpdatedBy: 'system_link'`(연결 직후 앱 best-effort)
- `actions`: 소유자 `proofPhotoPath`(항상 `proofs/{userId}/{planId}/{actionId}.jpg`)·`proofSource`·`proofTakenAt`(삭제 포함), 매니저 `reaction`, (선택) create 때 `managerId` — 쓰면 plan의 `managerId`와 같아야 함(규칙 검증, 아래 "읽기 축소")
- `cheers`: `reactionType: 'reply'`(똑똑 답장), 응원 `'💪'`
- 앞으로 plan·action 키 화이트리스트를 도입하면 위 키를 모두 허용해야 한다. 아니면 했어 배치 전체가 실패한다.

## 서버 강제 (Cloud Functions, 규칙 밖)
- **1:1 연결** `onRelationCreated`: 자기 연결 삭제, 더 오래된 연결이 있으면 새 관계 삭제(`partner_connect_failed`), `inviteCode` 불일치 시 취소, 성공 시 두 사람 초대 코드 회전.
- **managerId 가드** `onPlanCreated`·`onPlanUpdated`: 연결되지 않은 `managerId`는 해제(위조·오래된 짝꿍의 인증샷 접근 차단).
- **해제 정리** `onRelationDeleted`: 양쪽 `managerId` 해제, pending→active, 진행 중 내기 rejected, 짝꿍 없어진 사람 코드 회전·`partnerNickname` 삭제.
- **탈퇴 정리** `onAuthUserDeleted`: 내가 매니저인 타인 plans 해제, 내 relations·plans·actions, 보내고 받은 cheers, Storage `proofs/{uid}/`·`users/{uid}/`, 사용자 문서 삭제(단계별 격리).
- **푸시 가드**: 연결되지 않은 사용자 사이의 푸시는 버린다. `system_*` 업데이트는 푸시하지 않는다.
- **`actions.managerId` 동기화**: 모든 action이 자기 plan의 현재 매니저를 들고 있게 한다(아래 "읽기 축소 › actions.managerId"). 구 규칙에선 쓰이지 않고, `firestore.rules.next`의 list 권한이 이 필드에 기댄다.

## 읽기 축소 — `firestore.rules.next` (스테이징, 미배포)
목표: 로그인만 하면(커스텀 클라이언트의 익명 게스트 포함) 남의 `users`(이메일·초대 코드…)·`plans`·`actions`를 나열할 수 있는 상태를 끝낸다.
배포된 규칙은 빌드 ≤80 호환 때문에 아직 좁힐 수 없다. 그래서
1. 좁힌 규칙을 `firestore.rules.next`에 미리 두고,
2. 빌드 81은 **두 규칙 모두에서** 허용되는 쿼리 모양만 쓰고(아래 계약, `rules-tests/test-next/query-shapes.test.js`와 앱의 읽기를 그대로 재현한 `client_queries.test.js`가 두 규칙에 대해 모두 검증),
3. 빌드 81이 대다수가 되면 **앱 릴리스 없이** 규칙 파일만 교체한다(아래 "전환 절차").

### 바뀌는 것
쓰기 규칙은 actions 소유자의 `managerId` 변경 제한 하나를 빼면 같다(`test/firestore.test.js`를 next에도 그대로 돌린다).

| 대상 | 지금 `firestore.rules` | next |
|---|---|---|
| `users/{uid}` | read: 로그인 전체 | **get**: 로그인 전체(짝꿍 프로필은 uid로 읽음) · **list ✗**(초대 코드는 `resolveInviteCode`/`redeemInviteCode` callable로) |
| `plans/{id}` | read: 로그인 전체 | get·list: `userId==me` 또는 `managerId==me` |
| `actions/{id}` | get: 소유자·plan 매니저 · list: 로그인 전체 | get: 소유자 · `managerId==me` · plan의 현재 매니저(스탬프 없는 레거시 action, 푸시에서 단건으로 열 때) · **list: `userId==me` 또는 `managerId==me`** |
| `actions` update (소유자) | 키 제한 없음 | `managerId`는 그대로 두거나, 지우거나, plan의 `managerId`로만 |
| `relations` · `cheers` · `config` | 참가자 · 보낸/받은 사람 · 공개 | 같음 |

규칙은 필터가 아니다. 쿼리 **조건**으로 결과 전부가 읽을 수 있는 문서임을 증명해야 통과하고, 아니면 쿼리 전체가 거부된다. `userId == 짝꿍`만 거는 쿼리, `userId in [나, 짝꿍]`, `planId == X`만 거는 쿼리는 next에서 거부된다. OR 쿼리는 모든 갈래가 허용될 때만 통과한다(`plans where userId==me OR managerId==me`는 통과).

### 앱 쿼리 계약 (빌드 ≥81 — 두 규칙 모두에서 허용됨을 에뮬레이터로 확인)
| 화면·용도 | 쿼리 |
|---|---|
| 내 약속 | `plans where userId == me` |
| 내가 봐주는 약속 | `plans where managerId == me` |
| 짝꿍 약속 | `plans where userId == partner && managerId == me` |
| 홈 스트림 | `plans where (userId == me OR managerId == me)` (현재 코드 그대로 OK) |
| 약속 단건 | `plans/{id}` get — 내가 소유자이거나 매니저일 때만 |
| 내 기록 | `actions where userId == me orderBy date desc` |
| 짝꿍 기록 | `actions where userId == partner && managerId == me orderBy date desc` |
| 짝꿍 약속 타임라인 | `actions where planId == X && managerId == me orderBy date desc` |
| 내 약속 타임라인·오늘 기록 확인 | `actions where planId == X && userId == me (orderBy date desc 또는 date 범위)` |
| 짝꿍이 공유한 기록 전체 | `actions where managerId == me` |
| 기록 탭 양쪽 합치기 | `actions where (userId == me OR managerId == me)` 또는 위 두 쿼리를 따로 |
| action 단건(푸시에서 열기·인정 트랜잭션) | `actions/{id}` get — 소유자, 스탬프된 매니저, plan의 현재 매니저 |
| 연결 | `relations where executorId == me` / `managerId == me` / 둘의 OR |
| 응원·똑똑 | `cheers where toUserId == me` / `fromUserId == me` |
| 짝꿍 프로필 | `users/{partnerUid}` get (이메일 읽지 않기 — 아래 strip) |
| 초대 코드 | `resolveInviteCode({code})` → `{uid, displayName, profileImageUrl}`, 연결은 `redeemInviteCode({code})` → `{partnerId, alreadyLinked}` |
| 내 초대 코드 발급 | 생성해서 내 문서에 바로 쓰기 — 빌드 81은 `users where inviteCode == X` 중복 확인 쿼리를 하지 않는다(next에서 거부되므로. 중복은 서버가 정리) |
| 버전 게이트 | `config/app` get (로그인 전) |

금지(빌드 ≤80의 모양, next에서 거부): `actions where userId in [me, partner]`, `actions where planId == X`(단독), `actions where userId == partner`(단독), `plans where userId == partner`(단독), `users where inviteCode == X`, 필터 없는 컬렉션 조회.

짝꿍 기록에는 **스탬프된 action만** 나온다. 빌드 ≤80이 쓴 action은 백필 전까지 빠지고, 삭제된 plan의 action은 짝꿍에게서 사라진다(소유자에겐 남음). 즉 짝꿍 화면 = "내가 지금 봐주는 약속들의 기록".
이건 규칙과 무관하게 **빌드 81 자체의 동작**이다(지금 규칙에서도 `managerId == me`로만 짝꿍 기록·타임라인을 읽는다). 그래서 `backfill_action_manager_ids.js --apply`는 전환 때가 아니라 **빌드 81 공개 전**(`LAUNCH_RUNBOOK.md` 3단계 functions 배포 뒤, 5단계 마이그레이션)에 한 번 돌린다. 지금 규칙에서 `managerId`는 읽기 권한에 쓰이지 않으므로 먼저 돌려도 안전하다. 전환 1·3단계의 백필은 그 뒤 차이를 맞추는 재실행이다.

### 필요한 복합 인덱스
에뮬레이터는 인덱스를 검사하지 않는다. 아래 세 개는 `firestore.indexes.json`에 들어 있다(미배포) — 빌드 81 출시 **전**에 `firebase deploy --only firestore:indexes --project nod-try`로 배포하고 콘솔에서 "사용 설정됨"까지 기다린다(없으면 운영에서 `failed-precondition`. 짝꿍 기록은 빈 목록 + 비치명 오류, 약속 상세 타임라인과 인정의 오늘 기록 찾기는 실패). 지금 규칙에서도 필요하다.
- `actions`: `userId ASC, managerId ASC, date DESC` (짝꿍 기록)
- `actions`: `planId ASC, managerId ASC, date DESC` (짝꿍 약속 타임라인, 인정할 오늘 기록 찾기의 `date` 범위 쿼리)
- `actions`: `planId ASC, userId ASC, date DESC` (내 약속 타임라인)
- `actions`: `planId ASC, date ASC` — **빌드 ≤80의 인정 경로**(`cheerPartner`·`verifyPlan`의 `planId + date 범위 limit 1`)가 쓴다. 원래 콘솔에서 만들어져 파일에 없던 인덱스라 2026-10-03 배포 때 "파일에 없는 인덱스 삭제?" 프롬프트에서 삭제됐고, 같은 날 파일에 추가해 복구했다. **이 프롬프트에는 항상 N으로 답한다.**
- (빌드 81은 쓰지 않음) `actions`: `managerId ASC, date DESC` — 공유받은 기록 전체·OR 쿼리를 `orderBy date`로 쓰게 되면 추가
- 등호만 쓰는 쿼리(`plans where userId==A && managerId==B`, 서버의 `actions where userId==A && managerId==B`)는 단일 필드 인덱스로 충분하다.

### actions.managerId (비정규화, 선택 필드)
- 값: 그 action의 plan의 **현재** 매니저(`functions/src/planLinks.ts`의 `actionManagerFor`). plan이 없거나, 매니저가 없거나, 매니저가 소유자 자신이거나, action이 plan 소유자의 기록이 아니면 필드 없음.
- 규칙(두 파일 모두): create 때 없거나 `plans/{planId}.managerId`(이 쓰기 직전 값)와 같아야 한다. 빌드 81은 방금 읽은 plan의 매니저를 찍어서 짝꿍 목록에 바로 나오게 하고, 그 사이 매니저가 바뀌어 거부되면(`permission-denied`) 같은 내용을 스탬프 없이 다시 쓴다(했어 배치는 같은 action id로) — 서버가 몇 초 안에 맞게 찍는다. 빌드 ≤80은 찍지 않는다.
- 서버가 유지한다. 모두 멱등이고 실패 시 재시도된다. 450건 단위 트랜잭션이 action과 plan을 다시 읽어서 쓰므로 연결·해제가 겹쳐도 마지막 실행이 최신 plan을 반영한다.
  - `onActionCompleted`(actions onCreate, 모든 type): 없으면 찍고 틀리면 고친다. 이번에 `failurePolicy`를 켰다(1시간 지난 이벤트는 버림, 푸시는 이벤트당 1회 그대로).
  - `onRelationCreated`: 코드 주인의 active plans를 넘길 때 그 plans의 actions에도 찍는다.
  - `onRelationDeleted`·`onRelationUpdated`: plans를 해제한 뒤 `actions where userId==a && managerId==b`(양방향)에서 지운다 — 삭제된 plan의 action도 포함.
  - `onPlanUpdated`: `managerId`가 바뀐 모든 쓰기 뒤(앱이 자기 plans를 짝꿍에게 지정, 가드 해제, 예약 함수의 해제, 탈퇴 해제) 그 plan의 actions를 다시 맞춘다.
  - `onPlanDeleted`: 그 plan의 actions에서 지운다.
  - `onAuthUserDeleted`: 탈퇴자에게 공유된 actions(`managerId==uid`)에서 지운다.
- 비용: 연결·해제·매니저 변경 1회마다 해당 plans의 actions를 읽는다(관계 트리거와 `onPlanUpdated`가 각각 한 번, 두 번째는 쓰기 없음). action 생성 1회마다 트랜잭션 1회(읽기 2).

### 마이그레이션 (`scripts/migrations/`, 기본 dry run · `--apply` · JSON-lines 백업 · 멱등)
- `backfill_action_manager_ids.js` — 모든 action의 `managerId`를 plan의 현재 매니저로 맞춘다(없는 건 찍고, 틀린 건 고치고, plan이 없거나 매니저가 없으면 지움). 연결되지 않은 매니저(stale)에겐 절대 공유하지 않고 그 plans를 보고한다 → `clear_stale_manager_ids.js`로 정리. 백업: `backups/backfill_action_manager_ids-<시각>.jsonl` (`{id, planId, previous: {present, managerId}, next}`).
- `strip_user_emails.js` — `users.email` 삭제. **전환 마지막 단계에서만.** 빌드 ≤80은 실행할 때마다 auth 이메일을 문서에 다시 쓰고 짝꿍 이름 fallback으로 읽으므로, `config/app.minBuild < 81`이면 `--apply`를 거부한다(`--force`로만 우회). 백업 `backups/strip_user_emails-<시각>.jsonl`에는 **이메일이 들어 있다** — 운영자 PC에만 두고 30일 뒤 삭제.
- 둘 다 `functions/`의 firebase-admin과 컴파일된 헬퍼를 쓴다(`cd functions && npm ci && npm run build` 먼저). 에뮬레이터: `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/migrations/<script> --project demo-duounwan`. `rules-tests/functions/migrations.test.js`가 트리거가 켜진 에뮬레이터에서 둘 다 검증한다.

### 전환 절차 (대표 승인 후, 사람이 직접 · 모든 명령 `--project nod-try`)
**전제**
1. 이 묶음의 functions가 배포돼 있다(위 트리거). 이후 새 action은 서버가 찍는다.
2. 위 복합 인덱스가 배포돼 있고, 빌드 81에서 `permission-denied`·`failed-precondition` 비치명 오류가 없다(Crashlytics).
3. 빌드 ≥81 비중: 최근 7일 활성 사용자의 95% 이상(Analytics 앱 버전 분포, 보조로 `users.clientBuild`). 크리스마스 같은 신규 유입 피크 직전은 피한다.
4. `cd rules-tests && npm run emulators:rules-next`와 `npm run emulators:rules` 통과.

**단계**
1. 백필: `node scripts/migrations/backfill_action_manager_ids.js --project nod-try`(dry run)로 숫자 확인 → stale plan이 보고되면 `clear_stale_manager_ids.js --apply` 먼저 → `backfill_action_manager_ids.js --apply`. 다시 dry run해서 변경 0 확인.
2. 규칙 교체: `cp firestore.rules.next firestore.rules`, 헤더 주석의 "NEXT (staged)" 문구 정리, 커밋. 배포 전 `firebase.json`이 가리키는 파일로 `npm run emulators:rules`를 한 번 더(이제 next 내용). `firebase deploy --only firestore:rules --project nod-try`. (`--config firebase.next.json`으로 배포하지 않는다.)
3. 백필 한 번 더 `--apply`(전환 사이에 생긴 차이, 멱등).
4. 콘솔에서 `config/app.minBuild = 81`(숫자). 2와 4 사이엔 구버전이 아래 기능을 잃은 채 돌므로 바로 이어서 한다.
5. 스모크(빌드 81): 홈 → 기록 탭(내 것·짝꿍 것) → 짝꿍 약속 상세 → 인정 → 코드로 연결 → 해제 후 전 짝꿍 화면에서 기록·약속이 사라지는지.
6. 며칠 관찰 뒤(롤백할 일이 없다고 판단되면): `strip_user_emails.js` dry run → `--apply`.
7. 정리: `firestore.rules.next`는 지우거나 다음 축소의 출발점으로 둔다. `firestore.rules`와 다른 채로 방치하지 않는다.

**롤백**
- 규칙: 전환 직전 커밋의 파일로 되돌려 배포 — `git show <전환 직전 커밋>:firestore.rules > firestore.rules && firebase deploy --only firestore:rules --project nod-try`. 데이터는 바뀌지 않았으므로 즉시 원상태. `actions.managerId`는 남겨둬도 무해하다(구 규칙은 읽기를 넓게 허용하고 create 검증은 같다).
- minBuild: 콘솔에서 이전 값(80)으로.
- 백필은 되돌릴 필요 없다. 필요하면 백업의 `previous` 값으로 복원.
- `strip_user_emails`는 백업 JSONL로만 복원된다 — 그래서 롤백할 일이 없어진 뒤 마지막에 한다. 빌드 81은 `email`을 쓰지 않으므로 복원할 이유는 사실상 없다.

**구버전(≤80)이 전환 뒤 잃는 것** (minBuild=81이면 업데이트 화면에서 막히므로 2~4 사이 몇 분)
- 코드로 연결: `users where inviteCode == X` 거부 → "코드를 찾을 수 없음".
- 기록 탭: `actions where userId in [나, 짝꿍] orderBy date` 거부 → 내 기록까지 통째로 안 뜸.
- 짝꿍 약속 목록: `plans where userId == 짝꿍` 거부.
- 약속 상세 타임라인·오늘 기록 확인: `actions where planId == X`(+date 범위) 거부 — 소유자 본인도.
- 남는 것: 홈(`plans`·`relations` OR 쿼리는 참가자 범위라 허용), 단건 get(약속·기록·짝꿍 프로필), 모든 쓰기(했어·인정·똑똑·해제), 버전 게이트.

## 테스트
```bash
# 배포 규칙 firestore.rules 96건 (firestore + storage 에뮬레이터, Java 17+)
#   test/*.test.js + test-next/query-shapes.test.js + test-next/client_queries.test.js
#   (빌드 81의 쿼리 모양·실제 읽기가 지금 규칙에서도 허용되는지)
cd rules-tests && npm ci && npm run emulators:rules

# 스테이징 규칙 firestore.rules.next 113건 (firebase.next.json = next를 가리키는 에뮬레이터 전용 설정)
#   같은 96건(쓰기·storage 동작이 그대로인지, client_queries는 여기서 남·익명 게스트·비로그인 거부까지)
#   + test-next/firestore-next.test.js(남·비로그인·구버전 쿼리 거부)
cd rules-tests && npm run emulators:rules-next

# 트리거·마이그레이션 E2E 32건 (auth+firestore+functions+storage). firebase-tools 15 + JDK 21 필요
cd rules-tests && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" npm run emulators:functions

# functions 단위 테스트 32건 + 린트
cd functions && npm test && npm run lint
```
- 규칙 테스트 범위: 소유자 업로드·조회, 짝꿍 조회, 제3자·비로그인 거부, 남의 폴더·남의 약속·없는 약속 업로드 거부, 3MB 이상·png·heic·타입 없음 거부, 덮어쓰기·메타데이터 수정 거부, 소유자만 삭제, managerId가 바뀐 뒤 전 짝꿍 거부, `config/app` 공개 read·쓰기 거부, `serverLocks` 차단, 매니저 `reaction` 허용·제3자 거부, 답장 cheers, 신규 users 필드, action create의 `managerId` 검증.
- next 범위: 위 계약의 모든 쿼리 모양이 참가자에게 허용(두 규칙 모두), 남·비로그인의 get·list 거부, 빌드 ≤80 쿼리(`userId in`, `planId` 단독, `userId == partner` 단독, `users where inviteCode`) 거부, OR 쿼리는 모든 갈래가 허용될 때만, 해제 뒤 전 짝꿍 거부, 소유자의 `managerId` 변경 제한.
- 트리거 범위(추가분): action 생성 시 스탬프(모든 type, 틀린 값 교정, 남의 기록은 공유 안 함), 연결 시 공유, 해제·가드 해제·plan 삭제·탈퇴 시 해제, 앱이 지정한 plan의 공유. 마이그레이션 2종의 dry run·apply·백업·재실행 무변경, `strip_user_emails`의 minBuild 가드.
- `client_queries.test.js`: 앱(`lib/repositories/real_*_repository.dart`, `developer_screen`, 버전 게이트·메타데이터 동기화)이 보내는 읽기를 컬렉션·where·orderBy·limit·get/리스너까지 그대로 재현한다. 참가자는 두 규칙 모두에서 기대 결과로 성공, 같은 쿼리를 남(다른 커플)·익명 게스트·비로그인이 보내면 next에서 거부. 인정(Now 탭 배치·기록 탭 트랜잭션)·approve 트랜잭션·했어 직후 짝꿍 목록 노출·스탬프 거부 후 재시도 흐름 포함. "좁혀졌는지"는 파일 이름이 아니라 로드된 규칙을 찔러 보고 정하므로 전환 2단계(next를 `firestore.rules`로 복사한 뒤 `npm run emulators:rules`)에서도 그대로 통과한다. 앱의 읽기를 추가·변경하면 이 파일과 위 "앱 쿼리 계약"을 같이 고친다.
- 2026-10-03 rules.next 묶음 결과: 규칙 57/57, next 74/74, 트리거·마이그레이션 32/32, functions 32/32, lint 0.
- 2026-10-03 검증 단계(client_queries 추가 후): 규칙 96/96, next 113/113, 트리거·마이그레이션 32/32, functions 32/32, lint 0, `flutter analyze` 0, `flutter test` 652/652. 규칙을 일부러 넓히거나 좁힌 변이 6종(actions list·get 확대, users list 개방, relations 개방, actions list 소유자 전용, plan 매니저 get 제거)을 client_queries가 모두 잡았다. 예약 함수(`notifyMissedActions`, `notifyUnverifiedActions`)는 Pub/Sub 에뮬레이터 없이 단위 테스트만.
- 주의: firebase-tools 14의 functions 에뮬레이터는 firebase-functions v7을 못 읽는다(`functions/`의 `npm run serve`도 마찬가지). 배포·에뮬레이터 모두 firebase-tools 15 이상 권장.

## 배포 (프로덕션 영향 — 대표 승인 후, 사람이 직접)
> 규칙과 함수는 구버전(빌드 80 이하) 사용자에게도 즉시 적용된다. 잘못된 규칙은 앱을 잠근다. CI 자동 배포로 묶지 않는다.

순서는 `LAUNCH_RUNBOOK.md` 1~3단계를 따른다(모든 명령에 `--project nod-try`. `.firebaserc`에 default 별칭 없음):
- 런북 1단계: `firebase deploy --only storage --project nod-try` — **IAM 권한 부여 수락**
- 런북 2단계: `firebase deploy --only firestore:rules --project nod-try` → 콘솔에서 `config/app` 생성. 이어서 `firebase deploy --only firestore:indexes --project nod-try`(TTL 추가). 파일에 없는 콘솔 인덱스를 지우겠냐고 물으면 **No**. 사전에 `firebase firestore:indexes --project nod-try > /tmp/firestore.indexes.live.json`로 백업·비교
- 런북 3단계: `firebase deploy --only functions --project nod-try` — 갱신 6개(`onCheerCreated`, `onPlanCreated`, `onActionCompleted`(이제 `failurePolicy` + `managerId` 스탬프), `notifyMissedActions`, `notifyUnverifiedActions`, `onPlanUpdated`) + 신규(`onPlanDeleted`, `onRelationCreated`, `onRelationDeleted`, `onRelationUpdated`, `onAuthUserDeleted`, callable `resolveInviteCode`·`redeemInviteCode`). 읽기 축소 전환의 전제이기도 하다(`actions.managerId` 유지).
- 이후 hosting, 마이그레이션은 런북 4·5단계

- 스토리지는 `storage:rules`가 아니라 `storage`로 배포한다(`storage:<이름>`은 멀티버킷 named target으로 해석됨).
- 배포 직후 스모크: 로그인 → 연결 → 약속 → 인증샷 업로드 → 짝꿍 화면에서 사진 보기 → 인정 → 연결 해제 후 전 짝꿍 사진 거부 → 프로필 이미지 업로드.

## 알려진 잔여 리스크 (후속)
- `users` 전체 read(지금 규칙): `fcmToken`, `partnerNickname`, `email`, `inviteCode`가 로그인 사용자에게 나열된다. → `firestore.rules.next`로 list 차단(전환 절차), 이후 `strip_user_emails`.
- next 이후에도 uid만 알면 `users/{uid}` get으로 `fcmToken`·`inviteCode`·`partnerNickname`·`timezone`을 읽을 수 있다(짝꿍 프로필을 uid로 읽어야 해서). → `fcmToken`은 `users/{uid}/private/messaging`만 쓰도록 앱 이전 후 공개 필드 삭제(서버 `tokenOf`는 이미 private를 읽음). 초대 코드는 1:1·초대자 푸시·코드 회전으로 완화.
- `plans`/`actions` list가 넓다(지금 규칙). → next에서 참가자 범위로. 짝꿍 화면은 스탬프된 action만 보이므로 전환 전 백필 필수.
- `actions.managerId`는 해제 직후 트리거가 지울 때까지(수 초) 전 짝꿍에게 남는다. `plans.managerId`·인증샷 접근과 같은 창이다.
- 초대 코드 없는 relation 생성(구버전 호환)이 허용된다. 짝꿍 없는 사용자와 위조 관계를 만들면 성립하고 서버가 그 사람의 약속을 지정할 수 있다. 완화: 1:1 강제, 초대자 푸시, 코드 불일치 거부, `legacyLinkUntil` 창 밖에선 거부. → 전환 뒤 relations create를 callable(`redeemInviteCode`) 전용으로 좁히는 것이 다음 후보.
- `android/fastlane/json_key.json`(Play 서비스 계정 키)이 커밋 히스토리에 있다. 레포 공개 전 키 회전·히스토리 정리 필수.
